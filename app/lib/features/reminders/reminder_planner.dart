import '../../data/models.dart';

enum ReminderRepeat { once, daily, weekly }

/// One scheduled reminder occurrence pattern.
class ReminderPlan {
  const ReminderPlan({
    required this.id,
    required this.questId,
    required this.title,
    required this.first,
    required this.repeat,
    this.intention,
  });

  final int id;
  final String questId;
  final String title;
  final String? intention;

  /// First local fire time.
  final DateTime first;
  final ReminderRepeat repeat;

  @override
  String toString() => 'ReminderPlan($title @ $first, ${repeat.name})';
}

/// Turns quests into reminder schedules. Pure and deterministic so it can
/// be tested without platform plugins. Completed, archived and deleted
/// quests never produce reminders; a recurring quest already completed
/// today starts reminding from its next occurrence.
List<ReminderPlan> planReminders(
  List<Quest> quests,
  DateTime now, {
  required int firstWeekday,
  Set<String> completedToday = const {},
}) {
  final plans = <ReminderPlan>[];
  var nextId = 1;
  final today = DateTime(now.year, now.month, now.day);

  DateTime at(DateTime day, int minutes) => DateTime(day.year, day.month, day.day, minutes ~/ 60, minutes % 60);

  for (final q in quests) {
    final minutes = q.remindAt;
    if (minutes == null || q.status != QuestStatus.active && !q.isRecurring) continue;
    if (q.status == QuestStatus.archived) continue;

    void add(DateTime first, ReminderRepeat repeat) => plans.add(
      ReminderPlan(id: nextId++, questId: q.id, title: q.title, intention: q.intention, first: first, repeat: repeat),
    );

    // First occurrence on or after now, skipping today when already done.
    DateTime? nextOccurrence() {
      for (var i = 0; i < 8; i++) {
        final day = today.add(Duration(days: i));
        if (!q.occursOn(day, firstWeekday)) continue;
        if (i == 0 && completedToday.contains(q.id)) continue;
        final fire = at(day, minutes);
        if (fire.isAfter(now)) return fire;
      }
      return null;
    }

    switch (q.recurrence) {
      case Recurrence.none:
        final day = q.dueAt ?? today;
        final fire = at(day, minutes);
        if (fire.isAfter(now)) add(fire, ReminderRepeat.once);
      case Recurrence.daily:
        final first = nextOccurrence();
        if (first != null) add(first, ReminderRepeat.daily);
      case Recurrence.weekly:
        final first = nextOccurrence();
        if (first != null) add(first, ReminderRepeat.weekly);
      case Recurrence.weekdays:
        // One weekly schedule per working day of the user's week.
        for (var i = 0; i < 7; i++) {
          final day = today.add(Duration(days: i));
          if (!q.occursOn(day, firstWeekday)) continue;
          var fire = at(day, minutes);
          if (!fire.isAfter(now) || (i == 0 && completedToday.contains(q.id))) {
            fire = fire.add(const Duration(days: 7));
          }
          add(fire, ReminderRepeat.weekly);
        }
    }
  }
  return plans;
}
