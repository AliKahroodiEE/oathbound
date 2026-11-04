import 'package:flutter_test/flutter_test.dart';
import 'package:wyrd/data/models.dart';
import 'package:wyrd/features/reminders/reminder_planner.dart';
import 'package:wyrd_engine/wyrd_engine.dart';

Quest quest({
  String id = 'q',
  Recurrence recurrence = Recurrence.none,
  int? remindAt = 18 * 60,
  DateTime? dueAt,
  QuestStatus status = QuestStatus.active,
}) => Quest(
  id: id,
  tier: QuestTier.daily,
  title: 'Study',
  createdAt: DateTime(2026, 11, 1),
  updatedAt: DateTime(2026, 11, 1),
  recurrence: recurrence,
  remindAt: remindAt,
  dueAt: dueAt,
  status: status,
);

void main() {
  final morning = DateTime(2026, 11, 4, 9); // Wednesday

  test('one-off reminder fires today at the chosen time', () {
    final plans = planReminders([quest()], morning, firstWeekday: DateTime.monday);
    expect(plans.single.first, DateTime(2026, 11, 4, 18));
    expect(plans.single.repeat, ReminderRepeat.once);
  });

  test('past one-off reminders and quests without a time are skipped', () {
    final evening = DateTime(2026, 11, 4, 20);
    expect(planReminders([quest()], evening, firstWeekday: DateTime.monday), isEmpty);
    expect(planReminders([quest(remindAt: null)], morning, firstWeekday: DateTime.monday), isEmpty);
  });

  test('completed one-off quests do not remind', () {
    expect(planReminders([quest(status: QuestStatus.completed)], morning, firstWeekday: DateTime.monday), isEmpty);
  });

  test('daily reminders skip today once done', () {
    final plans = planReminders(
      [quest(recurrence: Recurrence.daily)],
      morning,
      firstWeekday: DateTime.monday,
      completedToday: {'q'},
    );
    expect(plans.single.first, DateTime(2026, 11, 5, 18));
    expect(plans.single.repeat, ReminderRepeat.daily);
  });

  test('weekday reminders follow the locale week (Saturday start → Sat–Wed)', () {
    final plans = planReminders([quest(recurrence: Recurrence.weekdays)], morning, firstWeekday: DateTime.saturday);
    expect(plans.map((p) => p.first.weekday).toSet(), {
      DateTime.saturday,
      DateTime.sunday,
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
    });
    expect(plans.every((p) => p.repeat == ReminderRepeat.weekly), isTrue);
  });
}
