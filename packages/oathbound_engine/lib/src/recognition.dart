import 'model.dart';
import 'rules.dart' as rules;

/// Lifetime facts used to evaluate achievements.
class AchievementStats {
  const AchievementStats({
    this.totalCompletions = 0,
    this.contractsCompleted = 0,
    this.objectivesCompleted = 0,
    this.level = 1,
    this.ranks = const {},
    this.bestWeekStreak = 0,
    this.totalCreditedMinutes = 0,
    this.returnedAfterLongGap = false,
  });

  final int totalCompletions;
  final int contractsCompleted;
  final int objectivesCompleted;
  final int level;
  final Map<Attribute, int> ranks;
  final int bestWeekStreak;
  final int totalCreditedMinutes;

  /// True when a completion happened after ≥ 7 inactive days.
  final bool returnedAfterLongGap;
}

class AchievementDef {
  const AchievementDef(this.id, this.isUnlocked, {this.titleId});

  /// Stable identifier; also the l10n key stem (`achievement_<id>_name`).
  final String id;
  final bool Function(AchievementStats) isUnlocked;

  /// Title unlocked alongside, if any (`title_<titleId>`).
  final String? titleId;
}

/// Achievements are recognition, not currency: they never grant XP.
abstract final class Achievements {
  static final List<AchievementDef> catalog = [
    AchievementDef(
      'first_oath',
      (s) => s.totalCompletions >= 1,
      titleId: 'sworn',
    ),
    AchievementDef('deeds_10', (s) => s.totalCompletions >= 10),
    AchievementDef(
      'deeds_100',
      (s) => s.totalCompletions >= 100,
      titleId: 'centurion',
    ),
    AchievementDef('deeds_1000', (s) => s.totalCompletions >= 1000),
    AchievementDef('first_contract', (s) => s.contractsCompleted >= 1),
    AchievementDef(
      'first_objective',
      (s) => s.objectivesCompleted >= 1,
      titleId: 'pathfinder',
    ),
    AchievementDef('level_5', (s) => s.level >= 5),
    AchievementDef('level_10', (s) => s.level >= 10, titleId: 'seasoned'),
    AchievementDef('level_25', (s) => s.level >= 25),
    for (final a in Attribute.values)
      AchievementDef(
        'rank_10_${a.name}',
        (s) => (s.ranks[a] ?? 1) >= 10,
        titleId: _rankTitles[a],
      ),
    AchievementDef('kept_weeks_4', (s) => s.bestWeekStreak >= 4),
    AchievementDef(
      'kept_weeks_12',
      (s) => s.bestWeekStreak >= 12,
      titleId: 'steadfast',
    ),
    AchievementDef(
      'kept_weeks_52',
      (s) => s.bestWeekStreak >= 52,
      titleId: 'oathkeeper',
    ),
    AchievementDef(
      'the_return',
      (s) => s.returnedAfterLongGap,
      titleId: 'returned',
    ),
    AchievementDef(
      'balanced',
      (s) => Attribute.values.every((a) => (s.ranks[a] ?? 1) >= 3),
      titleId: 'whole',
    ),
    AchievementDef('hours_100', (s) => s.totalCreditedMinutes >= 6000),
  ];

  static const Map<Attribute, String> _rankTitles = {
    Attribute.strength: 'ironbound',
    Attribute.intelligence: 'adept_of_lore',
    Attribute.discipline: 'unbending',
    Attribute.creativity: 'dreamwright',
    Attribute.vitality: 'evergreen',
    Attribute.social: 'kindred',
  };

  /// Every achievement id satisfied by [stats].
  static Set<String> satisfied(AchievementStats stats) => {
    for (final a in catalog)
      if (a.isUnlocked(stats)) a.id,
  };

  /// Achievements newly earned compared with [alreadyUnlocked].
  static List<AchievementDef> newlyUnlocked(
    AchievementStats stats,
    Set<String> alreadyUnlocked,
  ) => [
    for (final a in catalog)
      if (!alreadyUnlocked.contains(a.id) && a.isUnlocked(stats)) a,
  ];

  static String? titleFor(String achievementId) {
    for (final a in catalog) {
      if (a.id == achievementId) return a.titleId;
    }
    return null;
  }
}

enum CharacterClass {
  scholar,
  warden,
  artisan,
  vanguard,
  envoy,
  druid,
  explorer,
  strategist,
  arcanist,
}

/// Emergent class from the last 90 days of attribute XP (rules §9.3).
/// Classes are identity only and never change XP.
abstract final class Classes {
  static CharacterClass? compute(Map<Attribute, int> xp90, int level) {
    if (level < rules.classRevealLevel) return null;
    final total = xp90.values.fold(0, (a, b) => a + b);
    if (total <= 0) return null;
    double share(Attribute a) => (xp90[a] ?? 0) / total;

    final ranked = [...Attribute.values]
      ..sort((a, b) {
        final c = share(b).compareTo(share(a));
        return c != 0 ? c : a.index.compareTo(b.index);
      });
    final top = ranked.first;
    final present = Attribute.values
        .where((a) => share(a) >= rules.explorerMinShare)
        .length;
    if (share(top) < rules.explorerMaxTopShare &&
        present >= rules.explorerMinAttributes) {
      return CharacterClass.explorer;
    }

    bool strong(Attribute a) => share(a) >= rules.hybridMinShare;
    if (strong(Attribute.intelligence) && strong(Attribute.discipline)) {
      return CharacterClass.strategist;
    }
    if (strong(Attribute.intelligence) && strong(Attribute.creativity)) {
      return CharacterClass.arcanist;
    }
    return switch (top) {
      Attribute.intelligence => CharacterClass.scholar,
      Attribute.discipline => CharacterClass.warden,
      Attribute.creativity => CharacterClass.artisan,
      Attribute.strength => CharacterClass.vanguard,
      Attribute.social => CharacterClass.envoy,
      Attribute.vitality => CharacterClass.druid,
    };
  }
}
