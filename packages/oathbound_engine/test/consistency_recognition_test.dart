import 'package:oathbound_engine/oathbound_engine.dart';
import 'package:test/test.dart';

DateTime d(int month, int day) => DateTime.utc(2026, month, day);

/// Every day from [from] to [to] inclusive.
Set<DateTime> range(DateTime from, DateTime to) => {
  for (var x = from; !x.isAfter(to); x = DateTime.utc(x.year, x.month, x.day + 1))
    x,
};

void main() {
  group('weekStartOf', () {
    test('Monday weeks and Saturday weeks', () {
      // 2026-11-04 is a Wednesday.
      expect(Consistency.weekStartOf(d(11, 4), DateTime.monday), d(11, 2));
      expect(Consistency.weekStartOf(d(11, 4), DateTime.saturday), d(10, 31));
      expect(Consistency.weekStartOf(d(10, 31), DateTime.saturday), d(10, 31));
    });
  });

  group('weekly consistency', () {
    test('counts consecutive kept weeks', () {
      // Weeks starting Oct 12, 19, 26 each get 4 active days (Mon–Thu).
      final active = {
        ...range(d(10, 12), d(10, 15)),
        ...range(d(10, 19), d(10, 22)),
        ...range(d(10, 26), d(10, 29)),
      };
      final w = Consistency.weekly(activeDays: active, today: d(11, 2), target: 4);
      expect(w.currentStreak, 3);
      expect(w.bestStreak, 3);
    });

    test('an unfinished current week never breaks the streak', () {
      final active = {...range(d(10, 26), d(10, 29))};
      final w = Consistency.weekly(activeDays: active, today: d(11, 3), target: 4);
      expect(w.currentStreak, 1);
      expect(w.activeDaysThisWeek, 0);
      expect(w.keptThisWeek, isFalse);
    });

    test('a missed week resets the current streak but keeps the record', () {
      final active = {
        ...range(d(10, 5), d(10, 8)),
        ...range(d(10, 12), d(10, 15)),
        d(10, 20),
        ...range(d(10, 26), d(10, 29)),
      };
      final w = Consistency.weekly(activeDays: active, today: d(11, 2), target: 4);
      expect(w.currentStreak, 1);
      expect(w.bestStreak, 2);
    });

    test('paused days scale the target and fully paused weeks are neutral', () {
      final active = {
        ...range(d(10, 12), d(10, 15)),
        d(10, 26), d(10, 27), // 2 active days, 4 paused days in that week
      };
      final w = Consistency.weekly(
        activeDays: active,
        today: d(11, 2),
        target: 4,
        pausedDays: {
          ...range(d(10, 19), d(10, 25)), // whole week paused
          ...range(d(10, 29), d(11, 1)),
        },
      );
      expect(w.currentStreak, 2);
    });
  });

  group('daily chain', () {
    test('one miss per week is forgiven', () {
      final active = range(d(11, 2), d(11, 8))..remove(d(11, 4));
      final c = Consistency.chain(activeDays: active, today: d(11, 8));
      expect(c.current, 6);
    });

    test('a second miss in the same week ends the chain', () {
      final active = range(d(11, 2), d(11, 8))
        ..remove(d(11, 4))
        ..remove(d(11, 5));
      final c = Consistency.chain(activeDays: active, today: d(11, 8));
      expect(c.current, 3);
      expect(c.best, 3);
    });

    test('today being inactive does not break the chain', () {
      final c = Consistency.chain(
        activeDays: range(d(11, 2), d(11, 3)),
        today: d(11, 4),
      );
      expect(c.current, 2);
    });

    test('rest and paused days are neutral', () {
      final c = Consistency.chain(
        activeDays: {d(11, 2), d(11, 6)},
        today: d(11, 6),
        restDays: {d(11, 3)},
        pausedDays: {d(11, 4), d(11, 5)},
      );
      expect(c.current, 2);
    });
  });

  group('condition', () {
    test('missed quests never reduce condition', () {
      expect(Consistency.condition(const [], d(11, 4)), 100);
      final idle = [DayRecord(day: d(10, 1))];
      expect(Consistency.condition(idle, d(11, 4)), 100);
    });

    test('overexertion strains, calm days recover', () {
      final records = [
        DayRecord(day: d(11, 1), creditedMinutes: 900), // −30
        DayRecord(day: d(11, 2), creditedMinutes: 800), // −20
      ];
      expect(Consistency.condition(records, d(11, 3)), 50);
      // One calm day (+15) then rest day (+15 +25).
      final recovering = [
        ...records,
        DayRecord(day: d(11, 3), creditedMinutes: 60),
        DayRecord(day: d(11, 4), restDay: true),
      ];
      expect(Consistency.condition(recovering, d(11, 5)), 100);
    });

    test('condition never drops below 25', () {
      final records = [
        for (var i = 1; i <= 10; i++) DayRecord(day: d(11, i), creditedMinutes: 960),
      ];
      expect(Consistency.condition(records, d(11, 11)), 25);
      expect(Consistency.labelFor(25), ConditionLabel.strained);
      expect(Consistency.labelFor(80), ConditionLabel.rested);
      expect(Consistency.labelFor(65), ConditionLabel.steady);
    });

    test('vitality activity aids recovery', () {
      final records = [
        DayRecord(day: d(11, 1), creditedMinutes: 900),
        DayRecord(day: d(11, 2), creditedMinutes: 120, vitalityXp: 25),
      ];
      expect(Consistency.condition(records, d(11, 3)), 95);
    });

    test('days away', () {
      expect(Consistency.daysAway({d(10, 25)}, d(11, 4)), 10);
      expect(Consistency.daysAway({}, d(11, 4)), isNull);
    });
  });

  group('achievements', () {
    test('first completion unlocks first_oath and its title', () {
      final unlocked = Achievements.newlyUnlocked(
        const AchievementStats(totalCompletions: 1),
        {},
      );
      expect(unlocked.map((a) => a.id), ['first_oath']);
      expect(Achievements.titleFor('first_oath'), 'sworn');
    });

    test('already unlocked achievements are not repeated', () {
      final unlocked = Achievements.newlyUnlocked(
        const AchievementStats(totalCompletions: 12),
        {'first_oath'},
      );
      expect(unlocked.map((a) => a.id), ['deeds_10']);
    });

    test('balanced requires every rank ≥ 3', () {
      final ranks = {for (final a in Attribute.values) a: 3};
      expect(
        Achievements.satisfied(AchievementStats(ranks: ranks)),
        contains('balanced'),
      );
      ranks[Attribute.social] = 2;
      expect(
        Achievements.satisfied(AchievementStats(ranks: ranks)),
        isNot(contains('balanced')),
      );
    });

    test('the return celebrates coming back', () {
      expect(
        Achievements.satisfied(const AchievementStats(returnedAfterLongGap: true)),
        contains('the_return'),
      );
    });
  });

  group('classes', () {
    test('hidden before level 5', () {
      expect(Classes.compute({Attribute.intelligence: 500}, 4), isNull);
    });

    test('dominant attribute decides the class', () {
      expect(
        Classes.compute({Attribute.intelligence: 800, Attribute.social: 100}, 5),
        CharacterClass.scholar,
      );
      expect(
        Classes.compute({Attribute.vitality: 600, Attribute.strength: 200}, 5),
        CharacterClass.druid,
      );
    });

    test('hybrids and explorer', () {
      expect(
        Classes.compute({Attribute.intelligence: 500, Attribute.discipline: 400}, 6),
        CharacterClass.strategist,
      );
      expect(
        Classes.compute({Attribute.intelligence: 500, Attribute.creativity: 400}, 6),
        CharacterClass.arcanist,
      );
      expect(
        Classes.compute({for (final a in Attribute.values) a: 100}, 6),
        CharacterClass.explorer,
      );
    });
  });
}
