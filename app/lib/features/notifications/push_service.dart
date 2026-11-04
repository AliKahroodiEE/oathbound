import 'dart:async';

import 'package:flutter/foundation.dart';

/// Whether this device may show notifications.
enum PushPermission {
  granted,

  /// Not asked yet, or declined in a way that lets the app ask again.
  askable,

  /// Declined for good: only the browser or system settings can change it.
  blocked,
}

/// What the Notifications panel shows for this device.
enum PushStatus {
  /// Push is not offered: not configured, signed out, or both switches off.
  hidden,

  /// This browser cannot receive push (on iPhone: until Wyrd is on the Home
  /// Screen), or this browser or phone gets no push token.
  unsupported,

  /// The switches want push, but the system permission is not granted yet.
  off,

  /// The system permission was declined for good.
  blocked,

  /// This device is registered for push.
  on,
}

/// A push notification, as the notify function sends it.
@immutable
class PushMessage {
  const PushMessage({this.title, this.body, this.data = const {}});

  final String? title;
  final String? body;

  /// String key/values from the notify function: `category`, `template_key`, ids.
  final Map<String, String> data;

  String? get category => data['category'];
}

/// Which pushes the Settings switches allow. Reminders are scheduled on the
/// device itself, so only the guild and weekly switches decide about push.
@immutable
class PushPreferences {
  const PushPreferences({required this.guild, required this.weekly});

  final bool guild;
  final bool weekly;

  bool get any => guild || weekly;

  /// Whether a push of [category] (the notify function's categories) may show.
  bool allows(String? category) => switch (category) {
    'guild_reactions' || 'guild_comments' || 'challenge_milestones' => guild,
    'weekly_summary' || 're_engagement' => weekly,
    _ => any,
  };

  @override
  bool operator ==(Object other) => other is PushPreferences && other.guild == guild && other.weekly == weekly;

  @override
  int get hashCode => Object.hash(guild, weekly);
}

/// The push transport: Firebase Cloud Messaging in the app, a fake in tests.
///
/// Nothing here starts Firebase until it is first used, so [PushService]
/// touches it only once someone is signed in.
abstract interface class PushMessaging {
  /// Whether this device or browser can receive push at all.
  Future<bool> isSupported();

  /// The current permission. Never prompts.
  Future<PushPermission> permission();

  /// Shows the system prompt where it can still be shown. Browsers allow it
  /// only inside a tap, so callers must not wait on anything slow before it.
  Future<PushPermission> requestPermission();

  /// This device's token, or null when there is none to be had right now.
  Future<String?> token();

  /// Invalidates the token, so nothing sent to it arrives any more.
  Future<void> deleteToken();

  /// Tokens issued after the first one.
  Stream<String> get tokenRefreshes;

  /// Pushes that arrive while the app is in the foreground.
  Stream<PushMessage> get foregroundMessages;

  /// Notifications the user tapped, including the one that launched the app.
  Stream<PushMessage> get openedMessages;
}

/// Server-side token storage that the notify function sends to.
abstract interface class PushRegistry {
  Future<void> register(String token, String platform);
  Future<void> unregister(String token);
}

/// Remembers which accounts were already asked on this device, so the first
/// Settings visit prompts once and never again.
abstract interface class PushPromptLog {
  Future<bool> wasAsked(String userId);
  Future<void> markAsked(String userId);
}

/// Keeps this device's push registration in step with the signed-in account,
/// the Settings switches and the system permission.
///
/// It never prompts by itself at launch. [settingsOpened] asks once per
/// account where the platform allows a prompt outside a tap, and [enable]
/// asks when the user turns a switch on or taps Allow.
class PushService {
  PushService({
    required this._messaging,
    required this._registry,
    required this._prompts,
    required this._platform,
    this.promptOnSettingsOpen = false,
  });

  final PushMessaging? _messaging;
  final PushRegistry? _registry;
  final PushPromptLog _prompts;
  final String? _platform;

  /// Whether the first Settings visit after signing in may show the system
  /// prompt by itself. Browsers allow the prompt only inside a tap, so on the
  /// web the Notifications panel offers an Allow button instead.
  final bool promptOnSettingsOpen;

  final status = ValueNotifier(PushStatus.hidden);
  final _messages = StreamController<PushMessage>.broadcast();
  final _opened = StreamController<PushMessage>.broadcast();
  final _subscriptions = <StreamSubscription<Object?>>[];

  String? _userId;
  PushPreferences? _preferences;
  bool? _supported;
  ({String userId, String token})? _registered;
  bool _retired = false;
  Future<void> _queue = Future.value();
  bool _disposed = false;

  bool get isAvailable => _messaging != null && _registry != null && _platform != null;

  /// This device's `push_tokens.platform`: `web`, `android`, or null where
  /// push is not offered.
  String? get platform => _platform;

  /// Foreground pushes for the signed-in account that its switches allow.
  Stream<PushMessage> get messages => _messages.stream;

  /// Notifications the signed-in account tapped to open the app.
  Stream<PushMessage> get opened => _opened.stream;

  /// Completes when every change so far has been applied.
  @visibleForTesting
  Future<void> get settled => _queue;

  /// The signed-in account, or null for guests and after signing out.
  void setUser(String? userId) {
    if (userId == _userId) return;
    final signedOut = _userId != null && userId == null;
    _userId = userId;
    if (userId != null) _listen();
    unawaited(_sync(signedOut: signedOut));
  }

  /// The Settings switches; null while the profile is still loading.
  void setPreferences(PushPreferences? preferences) {
    if (preferences == _preferences) return;
    _preferences = preferences;
    unawaited(_sync());
  }

  /// Settings opened. Refreshes the status (the permission may have changed
  /// in the system settings meanwhile) and, the first time an account opens
  /// Settings on this device, shows the system prompt where no tap is needed.
  Future<void> settingsOpened() async {
    await _sync();
    final messaging = _messaging;
    final userId = _userId;
    if (!promptOnSettingsOpen || messaging == null || userId == null || status.value != PushStatus.off) return;
    if (await _prompts.wasAsked(userId)) return;
    await _prompts.markAsked(userId);
    await _ask(messaging);
    await _sync();
  }

  /// The user asked for notifications: a switch turned on, or Allow tapped.
  /// Shows the system prompt straight away (browsers allow it only inside
  /// the tap), then registers this device if the answer was yes.
  Future<void> enable() async {
    final messaging = _messaging;
    final userId = _userId;
    if (!isAvailable || messaging == null || userId == null) return;
    // Nothing to ask for where push cannot work (an iPhone browser tab).
    if (_supported != false) {
      await _ask(messaging);
      await _prompts.markAsked(userId);
    }
    await _sync();
  }

  /// Removes this device's token from the server while the session still
  /// works; the sign-out flow can call it just before signing out. Without
  /// it the token is still invalidated when the sign-out arrives, and the
  /// notify function drops the dead row the next time it sends.
  Future<void> beforeSignOut() => _run(() => _retire(server: true));

  void dispose() {
    _disposed = true;
    for (final s in _subscriptions) {
      unawaited(s.cancel());
    }
    unawaited(_messages.close());
    unawaited(_opened.close());
    status.dispose();
  }

  /// Starts listening (and so starts Firebase) the first time someone signs in.
  void _listen() {
    final messaging = _messaging;
    if (messaging == null || _registry == null || _platform == null || _subscriptions.isNotEmpty) return;
    _subscriptions
      ..add(messaging.tokenRefreshes.listen((_) => unawaited(_sync())))
      ..add(messaging.foregroundMessages.listen(_onForeground))
      ..add(messaging.openedMessages.listen(_onOpened));
  }

  Future<void> _ask(PushMessaging messaging) async {
    try {
      await messaging.requestPermission();
    } on Object catch (error) {
      debugPrint('Push permission request failed: $error');
    }
  }

  Future<void> _sync({bool signedOut = false}) => _run(() async {
    if (signedOut) await _retire(server: false);
    await _reconcile();
  });

  /// How long a step may wait on Firebase, the browser or the server before
  /// the steps queued behind it go ahead.
  static const _stepTimeout = Duration(seconds: 45);

  /// Runs [step] after the steps before it, so events never interleave. A
  /// step that is still waiting after [_stepTimeout] (a platform call that
  /// never answers) is given up, so it cannot hold back the rest of the
  /// session, such as retiring the token after signing out.
  Future<void> _run(Future<void> Function() step) {
    return _queue = _queue.then((_) async {
      if (_disposed) return;
      try {
        await step().timeout(_stepTimeout);
      } on Object catch (error) {
        debugPrint('Push update failed: $error');
      }
    });
  }

  Future<void> _reconcile() async {
    final messaging = _messaging;
    final registry = _registry;
    final platform = _platform;
    final userId = _userId;
    final preferences = _preferences;
    if (messaging == null || registry == null || platform == null || userId == null) {
      _show(PushStatus.hidden);
      return;
    }
    if (preferences == null) return; // The profile is still loading.
    final supported = _supported ??= await messaging.isSupported();
    if (!preferences.any) {
      if (_registered != null) await _retire(server: true);
      _show(PushStatus.hidden);
      return;
    }
    if (!supported) {
      _show(PushStatus.unsupported);
      return;
    }
    final permission = await messaging.permission();
    if (permission != PushPermission.granted) {
      _show(permission == PushPermission.blocked ? PushStatus.blocked : PushStatus.off);
      return;
    }
    final String? token;
    try {
      token = await messaging.token();
    } on Object catch (error) {
      // No push service behind this browser (Brave with it switched off) or
      // phone (no Google Play services): Allow could not get any further.
      debugPrint('Push token unavailable: $error');
      _show(PushStatus.unsupported);
      return;
    }
    if (token == null) {
      _show(PushStatus.off);
      return;
    }
    _retired = false;
    final registered = _registered;
    if (registered == null || registered.userId != userId || registered.token != token) {
      await registry.register(token, platform);
      _registered = (userId: userId, token: token);
    }
    _show(PushStatus.on);
  }

  /// Stops pushes to this device for the account last registered on it.
  /// [server] also deletes the server row, which needs a live session.
  Future<void> _retire({required bool server}) async {
    final messaging = _messaging;
    if (messaging == null || _retired) return;
    final registered = _registered;
    _registered = null;
    if (server && registered != null) {
      try {
        await _registry?.unregister(registered.token);
      } on Object catch (error) {
        debugPrint('Push token could not be removed from the server: $error');
      }
    }
    // A token from an earlier session may still be on the server, so retire
    // it whenever this device could have one.
    if (registered == null && await messaging.permission() != PushPermission.granted) return;
    try {
      await messaging.deleteToken();
      _retired = true;
    } on Object catch (error) {
      debugPrint('Push token could not be invalidated: $error');
    }
  }

  void _onForeground(PushMessage message) {
    final preferences = _preferences;
    if (_disposed || _userId == null || preferences == null || !preferences.allows(message.category)) return;
    _messages.add(message);
  }

  void _onOpened(PushMessage message) {
    if (!_disposed && _userId != null) _opened.add(message);
  }

  void _show(PushStatus value) {
    if (!_disposed) status.value = value;
  }
}
