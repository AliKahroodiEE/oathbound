import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/models.dart';
import '../../l10n/generated/app_localizations.dart';
import 'reminder_planner.dart';
import 'reminder_service.dart';

final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) {
  final s = ReminderScheduler.forPlatform();
  ref.onDispose(s.dispose);
  return s;
});

/// Keeps scheduled reminders in step with quests, completions, the
/// reminder setting and the language. Watched by the app root.
final reminderCoordinatorProvider = Provider<void>((ref) {
  final db = ref.watch(databaseProvider);
  final scheduler = ref.watch(reminderSchedulerProvider);
  final regional = ref.watch(regionalProvider);
  final enabled = ref.watch(profileProvider.select((p) => p.value?.notifReminders ?? true));
  Timer? debounce;

  Future<void> sync() async {
    final now = DateTime.now();
    final rows = await (db.select(db.quests)..where((q) => q.deletedAt.isNull() & q.remindAt.isNotNull())).get();
    final done = await (db.select(
      db.completions,
    )..where((c) => c.occurrenceDay.equals(dayKey(now)) & c.state.equals('active'))).get();
    final plans = enabled
        ? planReminders(
            rows.map(Quest.fromRow).toList(),
            now,
            firstWeekday: regional.firstWeekday,
            completedToday: {for (final c in done) c.questId},
          )
        : const <ReminderPlan>[];
    final body = lookupAppLocalizations(regional.locale).reminderBody;
    try {
      await scheduler.apply(plans, fallbackBody: body);
    } on Object {
      // Platform without notification support (e.g. tests): nothing to do.
    }
  }

  final sub = db.tableUpdates(TableUpdateQuery.onAllTables([db.quests, db.completions])).listen((_) {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 500), () => unawaited(sync()));
  });
  unawaited(sync());
  ref.onDispose(() {
    debounce?.cancel();
    unawaited(sub.cancel());
  });
});
