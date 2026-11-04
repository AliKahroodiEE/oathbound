import 'dart:math' as math;

import 'rules.dart' as rules;

/// One local day's aggregated activity. Days are date-only values built
/// with [localDay]; time zones are resolved before they reach the engine.
class DayRecord {
  const DayRecord({required this.day, this.creditedMinutes = 0, this.vitalityXp = 0, this.restDay = false});

  final DateTime day;
  final int creditedMinutes;
  final int vitalityXp;
  final bool restDay;
}

/// Normalises any instant to a date-only UTC value for day arithmetic.
DateTime localDay(DateTime d) => DateTime.utc(d.year, d.month, d.day);

class WeeklyConsistency {
  const WeeklyConsistency({
    required this.currentStreak,
    required this.bestStreak,
    required this.activeDaysThisWeek,
    required this.targetThisWeek,
  });

  final int currentStreak;
  final int bestStreak;
  final int activeDaysThisWeek;
  final int targetThisWeek;

  bool get keptThisWeek => targetThisWeek > 0 && activeDaysThisWeek >= targetThisWeek;
}

class ChainStatus {
  const ChainStatus({required this.current, required this.best});
  final int current;
  final int best;
}

enum ConditionLabel { rested, steady, strained }

/// Consistency, chain and condition rules (progression rules §7).
/// No function here ever decreases permanent progress.
abstract final class Consistency {
  /// Start of the week containing [day]; [firstWeekday] uses
  /// [DateTime.monday]..[DateTime.sunday] (Saturday = 6 for fa-IR).
  static DateTime weekStartOf(DateTime day, int firstWeekday) {
    final d = localDay(day);
    final offset = (d.weekday - firstWeekday) % 7;
    return d.subtract(Duration(days: offset));
  }

  /// Kept-weeks streak. A week is kept when its active days reach the
  /// target, scaled down by paused days. The unfinished current week never
  /// breaks a streak; fully paused weeks are skipped.
  static WeeklyConsistency weekly({
    required Set<DateTime> activeDays,
    required DateTime today,
    required int target,
    int firstWeekday = DateTime.monday,
    Set<DateTime> pausedDays = const {},
  }) {
    final active = activeDays.map(localDay).toSet();
    final paused = pausedDays.map(localDay).toSet();
    final t = localDay(today);
    final currentWeek = weekStartOf(t, firstWeekday);
    final safeTarget = target.clamp(1, 7);

    int activeIn(DateTime start) => _daysOf(start).where((d) => active.contains(d) && !d.isAfter(t)).length;
    int targetFor(DateTime start) {
      final pausedCount = _daysOf(start).where(paused.contains).length;
      return (safeTarget * (7 - pausedCount) / 7).ceil();
    }

    if (active.isEmpty) {
      return WeeklyConsistency(
        currentStreak: 0,
        bestStreak: 0,
        activeDaysThisWeek: 0,
        targetThisWeek: targetFor(currentWeek),
      );
    }

    final first = weekStartOf(active.reduce((a, b) => a.isBefore(b) ? a : b), firstWeekday);
    var run = 0;
    var best = 0;
    for (var week = first; !week.isAfter(currentWeek); week = week.add(const Duration(days: 7))) {
      final weekTarget = targetFor(week);
      final kept = weekTarget > 0 && activeIn(week) >= weekTarget;
      if (kept) {
        run++;
        best = math.max(best, run);
      } else if (weekTarget == 0 || week == currentWeek) {
        continue; // paused or still in progress: neutral
      } else {
        run = 0;
      }
    }
    return WeeklyConsistency(
      currentStreak: run,
      bestStreak: best,
      activeDaysThisWeek: activeIn(currentWeek),
      targetThisWeek: targetFor(currentWeek),
    );
  }

  /// Daily chain with one forgiven miss per week; rest and paused days
  /// are neutral; today never breaks the chain.
  static ChainStatus chain({
    required Set<DateTime> activeDays,
    required DateTime today,
    int firstWeekday = DateTime.monday,
    Set<DateTime> restDays = const {},
    Set<DateTime> pausedDays = const {},
  }) {
    final active = activeDays.map(localDay).toSet();
    if (active.isEmpty) return const ChainStatus(current: 0, best: 0);
    final rest = restDays.map(localDay).toSet();
    final paused = pausedDays.map(localDay).toSet();
    final t = localDay(today);
    final forgiven = <DateTime, int>{};

    var run = 0;
    var best = 0;
    for (
      var d = active.reduce((a, b) => a.isBefore(b) ? a : b);
      !d.isAfter(t);
      d = DateTime.utc(d.year, d.month, d.day + 1)
    ) {
      if (active.contains(d)) {
        run++;
        best = math.max(best, run);
      } else if (paused.contains(d) || rest.contains(d) || d == t) {
        continue;
      } else {
        final week = weekStartOf(d, firstWeekday);
        final used = forgiven[week] ?? 0;
        if (used < rules.forgivenMissesPerWeek) {
          forgiven[week] = used + 1;
        } else {
          run = 0;
        }
      }
    }
    return ChainStatus(current: run, best: best);
  }

  /// Condition (HP). Strain comes only from overexertion; missed quests
  /// never reduce it. Days without records count as calm days.
  static int condition(Iterable<DayRecord> records, DateTime today) {
    final t = localDay(today);
    final byDay = <DateTime, DayRecord>{for (final r in records) localDay(r.day): r};
    if (byDay.isEmpty) return rules.conditionMax;

    var value = rules.conditionMax;
    int clamp(int v) => v.clamp(rules.conditionMin, rules.conditionMax);
    final start = byDay.keys.reduce((a, b) => a.isBefore(b) ? a : b);
    for (var d = start; d.isBefore(t); d = DateTime.utc(d.year, d.month, d.day + 1)) {
      final r = byDay[d];
      final minutes = r?.creditedMinutes ?? 0;
      value = clamp(value + _dayDelta(minutes));
      if (r != null && r.vitalityXp >= rules.vitalityRecoveryXp) {
        value = clamp(value + rules.vitalityRecoveryBonus);
      }
      if (r != null && r.restDay) {
        value = clamp(value + rules.restDayRecovery);
      }
    }
    final todayRecord = byDay[t];
    if (todayRecord != null && todayRecord.creditedMinutes > rules.strainThresholdMinutes) {
      value = clamp(value - _strain(todayRecord.creditedMinutes));
    }
    return value;
  }

  static ConditionLabel labelFor(int condition) => condition >= 80
      ? ConditionLabel.rested
      : condition >= 50
      ? ConditionLabel.steady
      : ConditionLabel.strained;

  /// Whole days since the most recent active day before [today], or null
  /// if there has never been one.
  static int? daysAway(Set<DateTime> activeDays, DateTime today) {
    final t = localDay(today);
    final past = activeDays.map(localDay).where((d) => d.isBefore(t));
    if (past.isEmpty) return null;
    final last = past.reduce((a, b) => a.isAfter(b) ? a : b);
    return t.difference(last).inDays;
  }

  static int _dayDelta(int minutes) =>
      minutes > rules.strainThresholdMinutes ? -_strain(minutes) : rules.recoveryPerCalmDay;

  static int _strain(int minutes) =>
      math.min(rules.strainMaxPerDay, ((minutes - rules.strainThresholdMinutes) ~/ 10) * rules.strainPer10Minutes);

  static Iterable<DateTime> _daysOf(DateTime weekStart) => [
    for (var i = 0; i < 7; i++) DateTime.utc(weekStart.year, weekStart.month, weekStart.day + i),
  ];
}
