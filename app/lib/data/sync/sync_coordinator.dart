import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import '../../app/providers.dart';
import '../remote/backend.dart';
import '../remote/remote_api.dart';
import 'sync_service.dart';

/// Runs sync while a user is signed in: at sign-in, shortly after every
/// local change, and every two minutes (ADR-003). Network failures are
/// silent and retried; the app keeps working locally.
final syncCoordinatorProvider = Provider<void>((ref) {
  final user = ref.watch(currentUserProvider).value;
  final client = ref.watch(supabaseClientProvider);
  if (user == null || client == null) return;

  final db = ref.watch(databaseProvider);
  final service = SyncService(
    db,
    SupabaseRemoteApi(client),
    ref.watch(progressionRepositoryProvider),
    clientModel: () async => (await ref.read(aiSettingsRepositoryProvider).config())?.model,
  );
  var running = false;
  var again = false;
  Timer? debounce;

  Future<void> run() async {
    if (running) {
      again = true;
      return;
    }
    running = true;
    try {
      final report = await service.syncOnce(profile: await _serverProfile(ref));
      if (kDebugMode) debugPrint('sync: $report');
    } on Object catch (e) {
      if (kDebugMode) debugPrint('sync failed, will retry: $e');
    } finally {
      running = false;
      if (again) {
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
    debounce?.cancel();
    periodic.cancel();
    unawaited(sub.cancel());
  });
});

/// Whether completions should be marked provisional until the server
/// confirms them (signed-in users only).
final provisionalCompletionsProvider = Provider<bool>((ref) => ref.watch(currentUserProvider).value != null);

/// Server profile fields derived from local settings, so AI language, the
/// AI opt-in, day boundaries and week start match on every device.
Future<Map<String, Object?>> _serverProfile(Ref ref) async {
  final p = await ref.read(settingsRepositoryProvider).profile();
  final r = ref.read(regionalProvider);
  String? zone;
  try {
    zone = (await FlutterTimezone.getLocalTimezone()).identifier;
  } on Object {
    zone = null;
  }
  final name = p.characterName.trim();
  return {
    'display_name': name.isEmpty ? null : (name.length > 40 ? name.substring(0, 40) : name),
    'locale': r.locale.languageCode,
    'ai_locale': p.aiLocale ?? r.locale.languageCode,
    'calendar': r.calendar.name,
    'time_zone': ?zone,
    'week_start': r.firstWeekday,
    'weekly_target': p.weeklyTarget,
    'motivation': {'tone': p.tone, 'drivers': p.drivers},
    'ai_evaluation_enabled': p.aiEnabled,
  };
}
