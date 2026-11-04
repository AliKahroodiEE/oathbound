import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import '../../app/providers.dart';
import '../../core/locale/regional_settings.dart';
import '../remote/backend.dart';
import '../remote/remote_api.dart';
import '../repositories/settings_repository.dart';
import 'sync_service.dart';

/// Lets account flows stop sync before they clear the device.
class SyncControl {
  SyncService? _service;
  Future<void> _cycle = Future.value();

  /// Makes [service] the running sync and stops the one before it. Returns
  /// that one's cycle in progress, which must end before [service] writes.
  Future<void> _attach(SyncService service) {
    _service?.stop();
    _service = service;
    return _cycle;
  }

  void _track(Future<void> cycle) => _cycle = cycle.then((_) {}, onError: (Object _) {});

  /// Stops syncing and completes once a cycle in progress has ended, so
  /// nothing is written to this device afterwards. The next sign-in starts
  /// sync again.
  Future<void> stop() async {
    _service?.stop();
    _service = null;
    await _cycle;
  }
}

/// The app's one [SyncControl].
final syncControlProvider = Provider<SyncControl>((ref) => SyncControl());

/// Runs sync while a user is signed in: at sign-in, shortly after every
/// local change, and every two minutes (ADR-003). Network failures are
/// silent and retried; the app keeps working locally.
final syncCoordinatorProvider = Provider<void>((ref) {
  final user = ref.watch(currentUserProvider).value;
  final client = ref.watch(supabaseClientProvider);
  if (user == null || client == null) return;

  final db = ref.watch(databaseProvider);
  final api = SupabaseRemoteApi(client);
  final ai = ref.read(aiSettingsRepositoryProvider);
  final service = SyncService(
    db,
    api,
    ref.watch(progressionRepositoryProvider),
    clientModel: () async => (await ai.config())?.model,
  );
  final control = ref.read(syncControlProvider);
  final previous = control._attach(service);
  final settings = syncedSettings(
    settings: ref.read(settingsRepositoryProvider),
    api: api,
    regional: () => ref.read(regionalProvider),
  );
  var claimed = false;
  var running = false;
  var again = false;
  Timer? debounce;

  Future<SyncReport> cycle() async {
    if (!claimed) {
      await previous; // the account before must have stopped writing
      // Data another account left here is wiped before this one syncs.
      if (await service.claimFor(user.id)) await ai.clear();
      claimed = true;
    }
    return service.syncOnce(settings: settings);
  }

  Future<void> run() async {
    if (running) {
      again = true;
      return;
    }
    running = true;
    final current = cycle();
    control._track(current);
    try {
      final report = await current;
      if (kDebugMode) debugPrint('sync: $report');
    } on SyncStopped {
      // Signed out, or the device is being cleared.
    } on Object catch (e) {
      if (kDebugMode) debugPrint('sync failed, will retry: $e');
    } finally {
      running = false;
      if (again && !service.isStopped) {
        again = false;
        unawaited(run());
      }
    }
  }

  final sub = db.tableUpdates(TableUpdateQuery.onAllTables([db.outboxEntries])).listen((_) {
    debounce?.cancel();
    debounce = Timer(const Duration(seconds: 2), () => unawaited(run()));
  });
  final periodic = Timer.periodic(const Duration(minutes: 2), (_) => unawaited(run()));
  unawaited(run());

  ref.onDispose(() {
    service.stop();
    debounce?.cancel();
    periodic.cancel();
    unawaited(sub.cancel());
  });
});

/// Whether completions should be marked provisional until the server
/// confirms them (signed-in users only).
final provisionalCompletionsProvider = Provider<bool>((ref) => ref.watch(currentUserProvider).value != null);

const _accountFields = ['display_name', 'weekly_target', 'motivation', 'ai_evaluation_enabled'];
const _deviceFields = ['locale', 'ai_locale', 'calendar', 'time_zone', 'week_start'];
const _categories = ['reminders', 'guild_reactions', 'guild_comments', 'challenge_milestones', 'weekly_summary'];

/// The account settings sync carries (see [SyncedSettings]).
List<SyncedSettings> syncedSettings({
  required SettingsRepository settings,
  required RemoteApi api,
  required RegionalSettings Function() regional,
}) => [
  // Where this device is: the server evaluates and schedules with its
  // language, calendar, time zone and week start, so they are sent from here
  // and never taken over from another device.
  SyncedSettings(
    key: 'sync_profile_device',
    current: () async => _pick(_serverProfile(await settings.profile(), regional(), await _timeZone()), _deviceFields),
    send: api.updateProfile,
  ),
  // Who the account is: name, weekly target, motivation and the AI opt-in
  // follow the account to every device.
  SyncedSettings(
    key: 'sync_profile_account',
    table: 'profiles',
    current: () async => _pick(_serverProfile(await settings.profile(), regional(), null), _accountFields),
    send: api.updateProfile,
    fromServer: accountFromServer,
    apply: (value) => settings.updateProfile((p) => applyAccount(p, value)),
  ),
  // The Notifications switches and quiet hours, which the notify function
  // checks before every background push.
  SyncedSettings(
    key: 'sync_notification_prefs',
    table: 'notification_prefs',
    current: () async => notificationSettings(await settings.profile()),
    send: (value) => api.updateNotificationPrefs(notificationPrefsParams(value)),
    fromServer: notificationSettingsFromServer,
    apply: (value) => settings.updateProfile((p) => applyNotificationSettings(p, value)),
  ),
];

/// Every `public.profiles` column the app writes (the backend validator
/// reads this map's keys to check the UPDATE grant).
Map<String, Object?> _serverProfile(UserProfile p, RegionalSettings r, String? zone) {
  final name = p.characterName.trim();
  return {
    // display_name is NOT NULL on the server: a device without a character
    // name yet leaves the stored one alone.
    if (name.isNotEmpty) 'display_name': name.length > 40 ? name.substring(0, 40) : name,
    'weekly_target': p.weeklyTarget,
    'motivation': {'tone': p.tone, 'drivers': p.drivers},
    'ai_evaluation_enabled': p.aiEnabled,
    'locale': r.locale.languageCode,
    'ai_locale': p.aiLocale ?? r.locale.languageCode,
    'calendar': r.calendar.name,
    'time_zone': ?zone,
    'week_start': r.firstWeekday,
  };
}

Map<String, Object?> _pick(Map<String, Object?> from, List<String> keys) => {
  for (final k in keys)
    if (from.containsKey(k)) k: from[k],
};

Future<String?> _timeZone() async {
  try {
    return (await FlutterTimezone.getLocalTimezone()).identifier;
  } on Object {
    return null;
  }
}

/// The account settings in a pulled `profiles` row; null while no client
/// has changed the profile since sign-up, so a new account gets the choices
/// made on this device instead of the server's defaults.
@visibleForTesting
Map<String, Object?>? accountFromServer(Map<String, Object?> row) {
  if (row['updated_at'] == row['created_at']) return null;
  final name = (row['display_name'] as String? ?? '').trim();
  final motivation = row['motivation'] is Map ? row['motivation']! as Map : const <Object?, Object?>{};
  final tone = motivation['tone'];
  return {
    if (name.isNotEmpty) 'display_name': name,
    'weekly_target': row['weekly_target'],
    'motivation': {
      'tone': tone is String ? tone : null,
      'drivers': [
        for (final d in motivation['drivers'] is List ? motivation['drivers']! as List : const <Object?>[])
          if (d is String) d,
      ],
    },
    'ai_evaluation_enabled': row['ai_evaluation_enabled'],
  };
}

/// [p] with the account settings in [value] (the form of [accountFromServer]).
@visibleForTesting
UserProfile applyAccount(UserProfile p, Map<String, Object?> value) {
  final name = value['display_name'];
  final target = value['weekly_target'];
  final motivation = value['motivation'];
  final enabled = value['ai_evaluation_enabled'];
  final tone = motivation is Map ? motivation['tone'] : null;
  final drivers = motivation is Map ? motivation['drivers'] : null;
  return p.copyWith(
    characterName: name is String && name.trim().isNotEmpty
        ? (name.trim().length > 40 ? name.trim().substring(0, 40) : name.trim())
        : null,
    weeklyTarget: target is num ? target.toInt().clamp(1, 7) : null,
    tone: motivation is Map ? (tone is String ? tone : null) : p.tone,
    drivers: drivers is List
        ? [
            for (final d in drivers)
              if (d is String) d,
          ]
        : null,
    aiEnabled: enabled is bool ? enabled : null,
  );
}

/// The Notifications switches and quiet hours, one key per server category
/// ("Guild" covers reactions, comments and challenge milestones; the server
/// lets re-engagement follow the weekly summary).
@visibleForTesting
Map<String, Object?> notificationSettings(UserProfile p) => {
  'reminders': p.notifReminders,
  'guild_reactions': p.notifGuild,
  'guild_comments': p.notifGuild,
  'challenge_milestones': p.notifGuild,
  'weekly_summary': p.notifWeekly,
  'quiet_hours_start': _hhmm(p.quietStartMinutes),
  'quiet_hours_end': _hhmm(p.quietEndMinutes),
};

/// [notificationSettings] as `public.set_notification_prefs` takes them.
@visibleForTesting
Map<String, Object?> notificationPrefsParams(Map<String, Object?> value) => {
  'categories': {for (final k in _categories) k: value[k]},
  'quiet_hours_start': value['quiet_hours_start'],
  'quiet_hours_end': value['quiet_hours_end'],
};

/// A pulled `notification_prefs` row in the form of [notificationSettings];
/// categories the row leaves out are on, as on the server.
@visibleForTesting
Map<String, Object?> notificationSettingsFromServer(Map<String, Object?> row) {
  final categories = row['categories'] is Map ? row['categories']! as Map : const <Object?, Object?>{};
  String time(Object? value, String fallback) =>
      value is String && RegExp(r'^\d\d:\d\d').hasMatch(value) ? value.substring(0, 5) : fallback;
  return {
    for (final k in _categories) k: categories[k] is bool ? categories[k] : true,
    'quiet_hours_start': time(row['quiet_hours_start'], '22:00'),
    'quiet_hours_end': time(row['quiet_hours_end'], '08:00'),
  };
}

/// [p] with the notification settings in [value].
@visibleForTesting
UserProfile applyNotificationSettings(UserProfile p, Map<String, Object?> value) {
  int? minutes(Object? hhmm) {
    if (hhmm is! String) return null;
    final match = RegExp(r'^(\d\d):(\d\d)').firstMatch(hhmm);
    if (match == null) return null;
    final h = int.parse(match[1]!), m = int.parse(match[2]!);
    return h < 24 && m < 60 ? h * 60 + m : null;
  }

  bool? flag(String key) => value[key] is bool ? value[key]! as bool : null;
  return p.copyWith(
    notifReminders: flag('reminders'),
    // The app changes the three guild categories together.
    notifGuild: flag('guild_reactions'),
    notifWeekly: flag('weekly_summary'),
    quietStartMinutes: minutes(value['quiet_hours_start']),
    quietEndMinutes: minutes(value['quiet_hours_end']),
  );
}

String _hhmm(int minutes) =>
    '${(minutes ~/ 60 % 24).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
