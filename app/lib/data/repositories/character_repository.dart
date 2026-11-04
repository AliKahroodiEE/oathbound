import 'package:drift/drift.dart';
import 'package:wyrd_engine/wyrd_engine.dart';

import '../db/database.dart';
import '../models.dart';
import 'progression_repository.dart';
import 'settings_repository.dart';

/// Everything the character sheet shows, derived from the ledger.
class CharacterState {
  const CharacterState({
    required this.profile,
    required this.attributeXp,
    required this.todayXp,
    required this.condition,
    required this.weekly,
    required this.chain,
    required this.characterClass,
    required this.achievements,
    required this.recent,
    required this.daysAway,
    required this.restToday,
    required this.totalCompletions,
  });

  final UserProfile profile;
  final Map<Attribute, int> attributeXp;
  final Map<Attribute, int> todayXp;
  final int condition;
  final WeeklyConsistency weekly;
  final ChainStatus chain;
  final CharacterClass? characterClass;
  final List<AchievementRow> achievements;
  final List<RewardRecord> recent;
  final int? daysAway;
  final bool restToday;
  final int totalCompletions;

  int get totalXp => attributeXp.values.fold(0, (a, b) => a + b);
  CurveProgress get level => Curves.level(totalXp);
  CurveProgress rank(Attribute a) => Curves.rank(attributeXp[a] ?? 0);
  ConditionLabel get conditionLabel => Consistency.labelFor(condition);

  /// Titles the user may equip.
  List<String> get unlockedTitles => [for (final a in achievements) ?Achievements.titleFor(a.id)];

  /// Show the welcome-back card after ≥ 3 days away, once per return.
  bool showReturn(String todayKey) => (daysAway ?? 0) >= 3 && profile.returnAcknowledgedDay != todayKey;
}

/// Analytics for one period (week, month, year).
class PeriodStats {
  const PeriodStats({
    required this.start,
    required this.endExclusive,
    required this.xpByAttribute,
    required this.xpByDay,
    required this.completions,
    required this.minutes,
    required this.activeDays,
    required this.restDays,
    required this.minutesByCategory,
  });

  final DateTime start;
  final DateTime endExclusive;
  final Map<Attribute, int> xpByAttribute;

  /// Day key → attribute → XP.
  final Map<String, Map<Attribute, int>> xpByDay;
  final int completions;
  final int minutes;
  final Set<String> activeDays;
  final Set<String> restDays;
  final Map<QuestCategory, int> minutesByCategory;

  int get totalXp => xpByAttribute.values.fold(0, (a, b) => a + b);

  Attribute? get strongest => _extreme((a, b) => a > b);
  Attribute? get quietest => _extreme((a, b) => a < b);

  Attribute? _extreme(bool Function(int, int) better) {
    if (totalXp == 0) return null;
    Attribute? best;
    for (final a in Attribute.values) {
      final v = xpByAttribute[a] ?? 0;
      if (best == null || better(v, xpByAttribute[best] ?? 0)) best = a;
    }
    return best;
  }
}

class CharacterRepository {
  CharacterRepository(this._db, this._progression, this._settings, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final AppDatabase _db;
  final ProgressionRepository _progression;
  final SettingsRepository _settings;
  final DateTime Function() _now;

  Stream<void> get _changes => _db.tableUpdates(
    TableUpdateQuery.onAllTables([
      _db.ledgerEntries,
      _db.evaluations,
      _db.completions,
      _db.keyValues,
      _db.unlockedAchievements,
      _db.dayMarks,
    ]),
  );

  Stream<T> _watch<T>(Future<T> Function() load) async* {
    yield await load();
    await for (final _ in _changes) {
      yield await load();
    }
  }

  Stream<CharacterState> watch(int firstWeekday) => _watch(() => load(firstWeekday));

  Future<CharacterState> load(int firstWeekday) async {
    final now = _now();
    final today = dayKey(now);
    final profile = await _settings.profile();
    final totals = await _progression.attributeTotals();
    final todayXp = await _progression.attributeTotals(
      fromDay: today,
      toDayExclusive: dayKey(now.add(const Duration(days: 1))),
    );
    final active = await _progression.activeDays();
    final marks = await _db.select(_db.dayMarks).get();
    final rest = {for (final m in marks.where((m) => m.rest)) parseDayKey(m.localDay)};
    final paused = {
      for (final m in marks.where((m) => m.paused)) parseDayKey(m.localDay),
      ..._pausedSince(profile.pauseStartedDay, now),
    };

    final ninetyDaysAgo = dayKey(now.subtract(const Duration(days: 90)));
    final xp90 = await _progression.attributeTotals(fromDay: ninetyDaysAgo);
    final total = totals.values.fold(0, (a, b) => a + b);

    final achievements = await (_db.select(
      _db.unlockedAchievements,
    )..orderBy([(a) => OrderingTerm.desc(a.unlockedAt)])).get();
    final completions = await _db
        .customSelect("SELECT COUNT(*) AS n FROM completions WHERE state = 'active'", readsFrom: {_db.completions})
        .getSingle();

    return CharacterState(
      profile: profile,
      attributeXp: totals,
      todayXp: todayXp,
      condition: Consistency.condition(await _dayRecords(rest), now),
      weekly: Consistency.weekly(
        activeDays: active,
        today: now,
        target: profile.weeklyTarget,
        firstWeekday: firstWeekday,
        pausedDays: paused,
      ),
      chain: Consistency.chain(
        activeDays: active,
        today: now,
        firstWeekday: firstWeekday,
        restDays: rest,
        pausedDays: paused,
      ),
      characterClass: Classes.compute(xp90, Curves.level(total).step),
      achievements: achievements,
      recent: await rewards(limit: 5),
      daysAway: Consistency.daysAway(active, now),
      restToday: rest.contains(parseDayKey(today)),
      totalCompletions: completions.read<int>('n'),
    );
  }

  /// Reward records, newest first (the reward ledger).
  Future<List<RewardRecord>> rewards({int limit = 50, int offset = 0}) async {
    final query =
        _db.select(_db.evaluations).join([
            innerJoin(_db.completions, _db.completions.id.equalsExp(_db.evaluations.completionId)),
            innerJoin(_db.quests, _db.quests.id.equalsExp(_db.completions.questId)),
          ])
          ..orderBy([OrderingTerm.desc(_db.evaluations.createdAt)])
          ..limit(limit, offset: offset);
    final rows = await query.get();
    return [
      for (final r in rows)
        RewardRecord.fromRows(
          evaluation: r.readTable(_db.evaluations),
          questTitle: r.readTable(_db.quests).title,
          questTier: QuestTier.parse(r.readTable(_db.quests).tier),
          undone: r.readTable(_db.completions).state == 'undone',
        ),
    ];
  }

  Stream<List<RewardRecord>> watchRewards({int limit = 100}) => _watch(() => rewards(limit: limit));

  Future<PeriodStats> period(DateTime start, DateTime endExclusive) async {
    final from = dayKey(start);
    final to = dayKey(endExclusive);
    final byAttr = await _progression.attributeTotals(fromDay: from, toDayExclusive: to);

    final dayRows = await _db
        .customSelect(
          'SELECT local_day, attribute, SUM(amount) AS xp FROM ledger_entries '
          'WHERE superseded = 0 AND local_day >= ? AND local_day < ? GROUP BY local_day, attribute',
          variables: [Variable(from), Variable(to)],
          readsFrom: {_db.ledgerEntries},
        )
        .get();
    final byDay = <String, Map<Attribute, int>>{};
    for (final r in dayRows) {
      final a = Attribute.tryParse(r.read<String>('attribute'));
      if (a == null) continue;
      (byDay[r.read<String>('local_day')] ??= {})[a] = r.read<int>('xp');
    }

    final evalRows = await _db
        .customSelect(
          'SELECT e.local_day, e.category, e.effective_minutes, e.trivial FROM evaluations e '
          "JOIN completions c ON c.id = e.completion_id WHERE c.state = 'active' "
          'AND e.local_day >= ? AND e.local_day < ?',
          variables: [Variable(from), Variable(to)],
          readsFrom: {_db.evaluations, _db.completions},
        )
        .get();
    var minutes = 0;
    final active = <String>{};
    final byCategory = <QuestCategory, int>{};
    for (final r in evalRows) {
      final m = r.read<int>('effective_minutes');
      minutes += m;
      if (!r.read<bool>('trivial')) active.add(r.read<String>('local_day'));
      final c = QuestCategory.parse(r.read<String>('category'));
      byCategory[c] = (byCategory[c] ?? 0) + m;
    }
    final marks = await (_db.select(
      _db.dayMarks,
    )..where((m) => m.localDay.isBiggerOrEqualValue(from) & m.localDay.isSmallerThanValue(to) & m.rest)).get();

    return PeriodStats(
      start: start,
      endExclusive: endExclusive,
      xpByAttribute: byAttr,
      xpByDay: byDay,
      completions: evalRows.length,
      minutes: minutes,
      activeDays: active,
      restDays: {for (final m in marks) m.localDay},
      minutesByCategory: byCategory,
    );
  }

  Stream<PeriodStats> watchPeriod(DateTime start, DateTime endExclusive) => _watch(() => period(start, endExclusive));

  Future<List<DayRecord>> _dayRecords(Set<DateTime> rest) async {
    final rows = await _db
        .customSelect(
          'SELECT e.local_day, SUM(e.effective_minutes) AS m FROM evaluations e '
          "JOIN completions c ON c.id = e.completion_id WHERE c.state = 'active' GROUP BY e.local_day",
          readsFrom: {_db.evaluations, _db.completions},
        )
        .get();
    final vitality = await _db
        .customSelect(
          "SELECT local_day, SUM(amount) AS xp FROM ledger_entries WHERE superseded = 0 AND attribute = 'vitality' "
          'GROUP BY local_day',
          readsFrom: {_db.ledgerEntries},
        )
        .get();
    final vit = {for (final r in vitality) r.read<String>('local_day'): r.read<int>('xp')};
    final records = <DateTime, DayRecord>{};
    for (final r in rows) {
      final key = r.read<String>('local_day');
      final day = parseDayKey(key);
      records[day] = DayRecord(
        day: day,
        creditedMinutes: r.read<int>('m'),
        vitalityXp: vit[key] ?? 0,
        restDay: rest.contains(day),
      );
    }
    for (final d in rest) {
      records.putIfAbsent(d, () => DayRecord(day: d, restDay: true));
    }
    return records.values.toList();
  }

  static Iterable<DateTime> _pausedSince(String? startKey, DateTime now) sync* {
    if (startKey == null) return;
    final end = parseDayKey(dayKey(now));
    for (var d = parseDayKey(startKey); !d.isAfter(end); d = DateTime.utc(d.year, d.month, d.day + 1)) {
      yield d;
    }
  }
}
