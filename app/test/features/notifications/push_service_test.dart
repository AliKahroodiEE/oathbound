import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wyrd/features/notifications/push_provider.dart';
import 'package:wyrd/features/notifications/push_service.dart';
import 'package:wyrd/features/notifications/push_tile.dart';
import 'package:wyrd/l10n/generated/app_localizations.dart';

/// Firebase stand-in: [answer] is what the user picks at the system prompt.
class FakeMessaging implements PushMessaging {
  bool supported = true;
  PushPermission current = PushPermission.askable;
  PushPermission answer = PushPermission.granted;
  String currentToken = 'token-1';

  /// Thrown by [token], as where no push service answers (Brave with it
  /// switched off, a phone without Google Play services).
  Object? tokenError;

  /// Makes [token] never answer, like a stuck platform call.
  bool tokenHangs = false;

  /// Makes [token] answer only after this long, like a slow platform call.
  Duration? tokenDelay;

  /// Makes [deleteToken] finish only after this long.
  Duration? deleteDelay;
  int prompts = 0;
  int deletions = 0;

  /// Calls of any kind; the real transport starts Firebase on the first one.
  int calls = 0;
  final refreshes = StreamController<String>.broadcast();
  final foreground = StreamController<PushMessage>.broadcast();
  final opened = StreamController<PushMessage>.broadcast();

  bool get listened => refreshes.hasListener || foreground.hasListener || opened.hasListener;

  @override
  Future<bool> isSupported() async {
    calls++;
    return supported;
  }

  @override
  Future<PushPermission> permission() async {
    calls++;
    return current;
  }

  @override
  Future<PushPermission> requestPermission() async {
    calls++;
    prompts++;
    if (current == PushPermission.askable) current = answer;
    return current;
  }

  @override
  Future<String?> token() async {
    calls++;
    if (tokenHangs) return Completer<String?>().future;
    if (tokenDelay case final delay?) await Future<void>.delayed(delay);
    final error = tokenError;
    if (error != null) throw error;
    return current == PushPermission.granted ? currentToken : null;
  }

  @override
  Future<void> deleteToken() async {
    calls++;
    if (deleteDelay case final delay?) await Future<void>.delayed(delay);
    deletions++;
    currentToken = 'token-${deletions + 1}'; // FCM issues a fresh one next time.
  }

  @override
  Stream<String> get tokenRefreshes => refreshes.stream;

  @override
  Stream<PushMessage> get foregroundMessages => foreground.stream;

  @override
  Stream<PushMessage> get openedMessages => opened.stream;
}

class FakeRegistry implements PushRegistry {
  final registered = <(String, String)>[];
  final unregistered = <String>[];

  @override
  Future<void> register(String token, String platform) async => registered.add((token, platform));

  @override
  Future<void> unregister(String token) async => unregistered.add(token);
}

class FakePromptLog implements PushPromptLog {
  final asked = <String>{};

  @override
  Future<bool> wasAsked(String userId) async => asked.contains(userId);

  @override
  Future<void> markAsked(String userId) async => asked.add(userId);
}

const _both = PushPreferences(guild: true, weekly: true);
const _none = PushPreferences(guild: false, weekly: false);

void main() {
  late FakeMessaging messaging;
  late FakeRegistry registry;
  late FakePromptLog prompts;
  late PushService push;
  final live = <PushService>[];

  PushService keep(PushService service) {
    live.add(service);
    return push = service;
  }

  PushService create({bool promptOnSettingsOpen = false, String platform = 'android'}) => keep(
    PushService(
      messaging: messaging,
      registry: registry,
      prompts: prompts,
      platform: platform,
      promptOnSettingsOpen: promptOnSettingsOpen,
    ),
  );

  /// Lets stream events reach the service, then waits for its updates.
  Future<void> settle() async {
    await Future<void>.delayed(Duration.zero);
    await push.settled;
  }

  setUp(() {
    messaging = FakeMessaging();
    registry = FakeRegistry();
    prompts = FakePromptLog();
  });

  tearDown(() {
    for (final service in live) {
      service.dispose();
    }
    live.clear();
  });

  group('registration', () {
    test('only when signed in, allowed by the switches and granted', () async {
      messaging.current = PushPermission.granted;
      create().setPreferences(_both);
      await settle();
      expect(registry.registered, isEmpty, reason: 'guests never register');
      expect(push.status.value, PushStatus.hidden);

      push.setUser('u1');
      await settle();
      expect(registry.registered, [('token-1', 'android')]);
      expect(push.status.value, PushStatus.on);
    });

    test('not while both switches are off', () async {
      messaging.current = PushPermission.granted;
      create()
        ..setUser('u1')
        ..setPreferences(_none);
      await settle();
      expect(registry.registered, isEmpty);
      expect(push.status.value, PushStatus.hidden);
    });

    test('one switch on is enough', () async {
      messaging.current = PushPermission.granted;
      create()
        ..setUser('u1')
        ..setPreferences(const PushPreferences(guild: false, weekly: true));
      await settle();
      expect(registry.registered, hasLength(1));
    });

    test('waits for the profile before deciding', () async {
      messaging.current = PushPermission.granted;
      create().setUser('u1');
      await settle();
      expect(registry.registered, isEmpty);

      push.setPreferences(_both);
      await settle();
      expect(registry.registered, hasLength(1));
    });

    test('never prompts at launch', () async {
      create(promptOnSettingsOpen: true)
        ..setUser('u1')
        ..setPreferences(_both);
      await settle();
      expect(messaging.prompts, 0);
      expect(registry.registered, isEmpty);
      expect(push.status.value, PushStatus.off);
    });

    test('a blocked permission shows as blocked', () async {
      messaging.current = PushPermission.blocked;
      create()
        ..setUser('u1')
        ..setPreferences(_both);
      await settle();
      expect(push.status.value, PushStatus.blocked);
      expect(registry.registered, isEmpty);
    });

    test('a browser without push shows as unsupported', () async {
      messaging
        ..supported = false
        ..current = PushPermission.granted;
      create(platform: 'web')
        ..setUser('u1')
        ..setPreferences(_both);
      await settle();
      expect(push.status.value, PushStatus.unsupported);
      expect(registry.registered, isEmpty);
    });

    test('a device that gets no token shows as unsupported', () async {
      messaging
        ..current = PushPermission.granted
        ..tokenError = Exception('AbortError: Registration failed - push service error');
      create(platform: 'web')
        ..setUser('u1')
        ..setPreferences(_both);
      await settle();
      expect(push.status.value, PushStatus.unsupported);
      expect(registry.registered, isEmpty);

      messaging.tokenError = null; // A later visit tries again.
      await push.settingsOpened();
      expect(push.status.value, PushStatus.on);
      expect(registry.registered, [('token-1', 'web')]);
    });

    test('builds without Firebase stay inert', () async {
      keep(PushService(messaging: null, registry: registry, prompts: prompts, platform: 'android'))
        ..setUser('u1')
        ..setPreferences(_both);
      await push.enable();
      await settle();
      expect(push.isAvailable, isFalse);
      expect(push.status.value, PushStatus.hidden);
      expect(registry.registered, isEmpty);
    });

    test('guests never start Firebase', () async {
      messaging.current = PushPermission.granted;
      create().setPreferences(_both);
      await push.enable();
      await push.settingsOpened();
      await settle();
      expect(messaging.calls, 0);
      expect(messaging.listened, isFalse);
    });

    test('Firebase starts with the first sign-in', () async {
      create().setPreferences(_both);
      await settle();
      expect(messaging.listened, isFalse);

      push.setUser('u1');
      expect(messaging.listened, isTrue);
    });

    test('the same token is registered once per session', () async {
      messaging.current = PushPermission.granted;
      create()
        ..setUser('u1')
        ..setPreferences(_both);
      await settle();
      await push.settingsOpened();
      await push.settingsOpened();
      expect(registry.registered, hasLength(1));
    });
  });

  group('refresh', () {
    test('a new token is registered again', () async {
      messaging.current = PushPermission.granted;
      create()
        ..setUser('u1')
        ..setPreferences(_both);
      await settle();

      messaging.currentToken = 'token-9';
      messaging.refreshes.add('token-9');
      await settle();
      expect(registry.registered, [('token-1', 'android'), ('token-9', 'android')]);
    });

    test('a refresh while signed out registers nothing', () async {
      messaging.current = PushPermission.granted;
      create().setPreferences(_both);
      messaging.refreshes.add('token-9');
      await settle();
      expect(registry.registered, isEmpty);
    });
  });

  group('unregister', () {
    Future<void> registered() async {
      messaging.current = PushPermission.granted;
      create()
        ..setUser('u1')
        ..setPreferences(_both);
      await settle();
      expect(registry.registered, [('token-1', 'android')]);
    }

    test('both switches off removes the token and invalidates it', () async {
      await registered();
      push.setPreferences(_none);
      await settle();
      expect(registry.unregistered, ['token-1']);
      expect(messaging.deletions, 1);
      expect(push.status.value, PushStatus.hidden);
    });

    test('signing out invalidates the token; the session is gone, so no server call', () async {
      await registered();
      push.setUser(null);
      await settle();
      expect(messaging.deletions, 1);
      expect(registry.unregistered, isEmpty);
      expect(push.status.value, PushStatus.hidden);
    });

    test('beforeSignOut removes the server row while the session works', () async {
      await registered();
      await push.beforeSignOut();
      expect(registry.unregistered, ['token-1']);
      expect(messaging.deletions, 1);

      push.setUser(null);
      await settle();
      expect(messaging.deletions, 1, reason: 'already retired');
    });

    test('the next account on the device gets a fresh token', () async {
      await registered();
      push.setUser(null);
      await settle();
      push.setUser('u2');
      await settle();
      expect(registry.registered.last, ('token-2', 'android'));
    });

    test('signing out retires a token left from an earlier session', () async {
      messaging.current = PushPermission.granted;
      create().setUser('u1'); // The profile never loaded, so nothing registered yet.
      await settle();
      push.setUser(null);
      await settle();
      expect(messaging.deletions, 1);
    });

    test('signing out on a device that never allowed push touches nothing', () async {
      create()
        ..setUser('u1')
        ..setPreferences(_both);
      await settle();
      push.setUser(null);
      await settle();
      expect(messaging.deletions, 0);
      expect(registry.unregistered, isEmpty);
    });
  });

  // Widget tests for their fake clock.
  group('a platform call that answers late or never', () {
    testWidgets('holds up the steps behind it for 45 s, not for good', (tester) async {
      create()
        ..setUser('u1')
        ..setPreferences(_both);
      await tester.pump();
      expect(push.status.value, PushStatus.off);

      // Allowed in the browser's settings, but the token never comes.
      messaging
        ..current = PushPermission.granted
        ..tokenHangs = true;
      unawaited(push.settingsOpened());
      var retired = false;
      unawaited(push.beforeSignOut().then((_) => retired = true));

      await tester.pump(const Duration(seconds: 44));
      expect(retired, isFalse, reason: 'still waiting on the token');
      expect(messaging.deletions, 0);

      await tester.pump(const Duration(seconds: 2));
      expect(retired, isTrue, reason: 'signing out still retires the token');
      expect(messaging.deletions, 1);
    });

    testWidgets('a step given up on changes nothing when its token comes at last', (tester) async {
      create()
        ..setUser('u1')
        ..setPreferences(_both);
      await tester.pump();
      expect(push.status.value, PushStatus.off);

      // Allow tapped, but the token takes 46 s; both switches go off meanwhile.
      messaging.tokenDelay = const Duration(seconds: 46);
      unawaited(push.enable());
      await tester.pump();
      push.setPreferences(_none);

      await tester.pump(const Duration(seconds: 45));
      expect(push.status.value, PushStatus.hidden, reason: 'the switches-off step ran once the first was given up');

      await tester.pump(const Duration(seconds: 1)); // The token arrives.
      await tester.pump();
      expect(push.status.value, PushStatus.hidden, reason: 'as the newer step left it');
      expect(registry.registered, isEmpty);
    });

    testWidgets('a token invalidated late does not count for the next account', (tester) async {
      messaging.current = PushPermission.granted;
      create()
        ..setUser('u1')
        ..setPreferences(_both);
      await tester.pump();
      expect(registry.registered, [('token-1', 'android')]);

      // Signing out invalidates the token, which takes 46 s; u2 signs in meanwhile.
      messaging.deleteDelay = const Duration(seconds: 46);
      push.setUser(null);
      await tester.pump();
      push.setUser('u2');
      await tester.pump(const Duration(seconds: 45));
      expect(push.status.value, PushStatus.on);
      expect(registry.registered, hasLength(2), reason: 'u1, then u2');

      await tester.pump(const Duration(seconds: 1)); // The deletion finishes.
      expect(registry.registered, hasLength(2), reason: 'the step given up on registers nothing for u2');

      messaging.deleteDelay = null;
      push.setUser(null);
      await tester.pump();
      expect(messaging.deletions, 2, reason: "u2's sign-out invalidates its token too");
    });
  });

  group('asking', () {
    test('the first Settings visit asks once per account where no tap is needed', () async {
      create(promptOnSettingsOpen: true)
        ..setUser('u1')
        ..setPreferences(_both);
      await settle();

      await push.settingsOpened();
      expect(messaging.prompts, 1);
      expect(registry.registered, [('token-1', 'android')]);
      expect(push.status.value, PushStatus.on);

      await push.settingsOpened();
      expect(messaging.prompts, 1);
    });

    test('a declined first prompt is not repeated on later visits', () async {
      messaging.answer = PushPermission.askable;
      create(promptOnSettingsOpen: true)
        ..setUser('u1')
        ..setPreferences(_both);
      await settle();
      await push.settingsOpened();
      await push.settingsOpened();
      expect(messaging.prompts, 1);
      expect(push.status.value, PushStatus.off);
    });

    test('another account on the same device is asked on its own first visit', () async {
      prompts.asked.add('u1');
      create(promptOnSettingsOpen: true)
        ..setUser('u2')
        ..setPreferences(_both);
      await settle();
      await push.settingsOpened();
      expect(messaging.prompts, 1);
    });

    test('on the web the first visit offers Allow instead of prompting', () async {
      create(promptOnSettingsOpen: false, platform: 'web')
        ..setUser('u1')
        ..setPreferences(_both);
      await settle();
      await push.settingsOpened();
      expect(messaging.prompts, 0);
      expect(push.status.value, PushStatus.off);

      await push.enable(); // Allow tapped.
      expect(messaging.prompts, 1);
      expect(registry.registered, [('token-1', 'web')]);
    });

    test('turning a switch on asks at once and registers when allowed', () async {
      create()
        ..setUser('u1')
        ..setPreferences(_none);
      await settle();

      final asked = push.enable(); // The switch handler calls this first...
      push.setPreferences(_both); // ...then saves the switch.
      await asked;
      await settle();
      expect(messaging.prompts, 1);
      expect(registry.registered, [('token-1', 'android')]);
    });

    test('guests are never asked', () async {
      create(promptOnSettingsOpen: true).setPreferences(_both);
      await push.enable();
      await push.settingsOpened();
      expect(messaging.prompts, 0);
    });

    test('switches never prompt where push cannot work', () async {
      messaging.supported = false;
      create(platform: 'web')
        ..setUser('u1')
        ..setPreferences(_none);
      await settle();

      final asked = push.enable(); // An iPhone browser tab: a switch turned on.
      push.setPreferences(_both);
      await asked;
      await settle();
      expect(messaging.prompts, 0);
      expect(push.status.value, PushStatus.unsupported);
    });
  });

  group('taps', () {
    test('a tapped notification reaches the signed-in app', () async {
      create()
        ..setUser('u1')
        ..setPreferences(_none); // Taps count even with the switches off now.
      final opened = <PushMessage>[];
      push.opened.listen(opened.add);

      messaging.opened.add(const PushMessage(title: 'Comment', data: {'category': 'guild_comments'}));
      await settle();
      expect(opened.map((m) => m.title), ['Comment']);
    });

    test('nothing opens after signing out', () async {
      create()
        ..setUser('u1')
        ..setPreferences(_both);
      await settle();
      push.setUser(null);
      await settle();
      final opened = <PushMessage>[];
      push.opened.listen(opened.add);

      messaging.opened.add(const PushMessage(title: 'Comment'));
      await settle();
      expect(opened, isEmpty);
    });
  });

  group('foreground messages', () {
    test('only what the switches allow reaches the app', () async {
      messaging.current = PushPermission.granted;
      create()
        ..setUser('u1')
        ..setPreferences(const PushPreferences(guild: true, weekly: false));
      await settle();
      final shown = <PushMessage>[];
      push.messages.listen(shown.add);

      messaging.foreground
        ..add(const PushMessage(title: 'Comment', data: {'category': 'guild_comments'}))
        ..add(const PushMessage(title: 'Your week', data: {'category': 'weekly_summary'}));
      await settle();
      expect(shown.map((m) => m.title), ['Comment']);
    });

    test('nothing reaches a signed-out app', () async {
      create().setPreferences(_both);
      final shown = <PushMessage>[];
      push.messages.listen(shown.add);
      messaging.foreground.add(const PushMessage(title: 'Comment', data: {'category': 'guild_comments'}));
      await settle();
      expect(shown, isEmpty);
    });
  });

  test('push routes lead to the guild hall or the chronicle', () {
    const guild = '6f1c2b9e-8a4d-4c1e-9b7a-2d5e8f0a1b3c';
    expect(pushRoute({'category': 'guild_comments', 'guild_id': guild}), '/guilds/$guild');
    expect(pushRoute({'category': 'weekly_summary'}), '/chronicle');
    expect(pushRoute({'category': 'guild_comments', 'guild_id': '../settings'}), isNull);
    expect(pushRoute({'category': 'briefing'}), isNull);
  });

  group('settings row', () {
    final l10n = lookupAppLocalizations(const Locale('en'));

    Future<void> pumpRow(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [pushServiceProvider.overrideWithValue(push)],
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: PushDeviceTile()),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('offers Allow and turns on when allowed', (tester) async {
      create(platform: 'web')
        ..setUser('u1')
        ..setPreferences(_both);
      await pumpRow(tester);
      expect(find.text(l10n.pushDeviceOff), findsOneWidget);

      await tester.tap(find.text(l10n.pushAllow));
      await tester.pump();
      expect(messaging.prompts, 1);
      expect(find.text(l10n.pushDeviceOn), findsOneWidget);
    });

    testWidgets('stops offering Allow once allowed but no token comes', (tester) async {
      messaging.tokenError = Exception('AbortError: Registration failed - push service error');
      create(platform: 'web')
        ..setUser('u1')
        ..setPreferences(_both);
      await pumpRow(tester);
      expect(find.text(l10n.pushDeviceOff), findsOneWidget);

      await tester.tap(find.text(l10n.pushAllow));
      await tester.pump();
      expect(messaging.prompts, 1);
      expect(find.text(l10n.pushAllow), findsNothing);
      expect(find.text(l10n.pushUnsupported), findsOneWidget);
    });

    testWidgets('points to the settings once blocked, without an Allow button', (tester) async {
      messaging.current = PushPermission.blocked;
      create()
        ..setUser('u1')
        ..setPreferences(_both);
      await pumpRow(tester);
      expect(find.text(l10n.pushDeviceBlocked), findsOneWidget);
      expect(find.text(l10n.pushAllow), findsNothing);
    });

    testWidgets('says so where push cannot work', (tester) async {
      messaging.supported = false;
      create(platform: 'web')
        ..setUser('u1')
        ..setPreferences(_both);
      await pumpRow(tester);
      expect(find.text(l10n.pushUnsupported), findsOneWidget);
      expect(find.text(l10n.pushAllow), findsNothing);
    });

    testWidgets('in the Android app, speaks of the device rather than a browser', (tester) async {
      messaging
        ..current = PushPermission.granted
        ..tokenError = Exception('java.io.IOException: SERVICE_NOT_AVAILABLE');
      create()
        ..setUser('u1')
        ..setPreferences(_both);
      await pumpRow(tester);
      expect(find.text(l10n.pushUnsupportedDevice), findsOneWidget);
      expect(find.text(l10n.pushAllow), findsNothing);
    });

    testWidgets('in an iPhone browser, points to the Home Screen', (tester) async {
      messaging.supported = false;
      create(platform: 'web')
        ..setUser('u1')
        ..setPreferences(_both);
      await pumpRow(tester);
      expect(find.text(l10n.pushInstallHint), findsOneWidget);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('stays hidden when push is not offered', (tester) async {
      create(); // Signed out.
      await pumpRow(tester);
      expect(find.byType(ListTile), findsNothing);
    });
  });

  group('in-app snack bar', () {
    final l10n = lookupAppLocalizations(const Locale('en'));

    Future<void> show(WidgetTester tester, SnackBar snackBar) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(snackBar),
                child: const Text('show'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('show'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500)); // Slide in.
    }

    testWidgets('shows the push with an Open action for its screen', (tester) async {
      var opened = 0;
      const message = PushMessage(title: 'Mira commented', body: 'Well fought.');
      await show(tester, pushSnackBar(l10n, message, onOpen: () => opened++));
      expect(find.text('Mira commented'), findsOneWidget);
      expect(find.text('Well fought.'), findsOneWidget);

      await tester.tap(find.text(l10n.pushOpen));
      expect(opened, 1);
    });

    testWidgets('falls back to a localized line and no action', (tester) async {
      await show(tester, pushSnackBar(l10n, const PushMessage(title: ' ')));
      expect(find.text(l10n.pushInAppFallback), findsOneWidget);
      expect(find.byType(SnackBarAction), findsNothing);
    });
  });

  testWidgets('PushHost renders the app untouched in builds without push', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: PushHost(
          child: Directionality(textDirection: TextDirection.ltr, child: Text('app')),
        ),
      ),
    );
    expect(find.text('app'), findsOneWidget);
  });
}
