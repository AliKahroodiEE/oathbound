import 'package:wyrd_engine/wyrd_engine.dart';

import '../core/format/formatters.dart';
import 'generated/app_localizations.dart';

/// Maps engine identifiers (attributes, categories, achievements, titles,
/// adjustment codes) to localized text. Game rules never contain prose.
extension GameContentL10n on AppLocalizations {
  String attributeName(Attribute a) => switch (a) {
    Attribute.strength => attributeStrength,
    Attribute.intelligence => attributeIntelligence,
    Attribute.discipline => attributeDiscipline,
    Attribute.creativity => attributeCreativity,
    Attribute.vitality => attributeVitality,
    Attribute.social => attributeSocial,
  };

  String attributeDescription(Attribute a) => switch (a) {
    Attribute.strength => attributeStrengthDesc,
    Attribute.intelligence => attributeIntelligenceDesc,
    Attribute.discipline => attributeDisciplineDesc,
    Attribute.creativity => attributeCreativityDesc,
    Attribute.vitality => attributeVitalityDesc,
    Attribute.social => attributeSocialDesc,
  };

  String categoryName(QuestCategory c) => switch (c) {
    QuestCategory.study => category_study,
    QuestCategory.work => category_work,
    QuestCategory.fitness => category_fitness,
    QuestCategory.health => category_health,
    QuestCategory.creative => category_creative,
    QuestCategory.social => category_social,
    QuestCategory.chores => category_chores,
    QuestCategory.admin => category_admin,
    QuestCategory.mindfulness => category_mindfulness,
    QuestCategory.reading => category_reading,
    QuestCategory.other => category_other,
  };

  String tierName(QuestTier t) => switch (t) {
    QuestTier.daily => tierDaily,
    QuestTier.contract => tierContract,
    QuestTier.objective => tierObjective,
  };

  String tierHelp(QuestTier t) => switch (t) {
    QuestTier.daily => tierDailyHelp,
    QuestTier.contract => tierContractHelp,
    QuestTier.objective => tierObjectiveHelp,
  };

  String className(CharacterClass c) => switch (c) {
    CharacterClass.scholar => className_scholar,
    CharacterClass.warden => className_warden,
    CharacterClass.artisan => className_artisan,
    CharacterClass.vanguard => className_vanguard,
    CharacterClass.envoy => className_envoy,
    CharacterClass.druid => className_druid,
    CharacterClass.explorer => className_explorer,
    CharacterClass.strategist => className_strategist,
    CharacterClass.arcanist => className_arcanist,
  };

  String classDescription(CharacterClass c) => switch (c) {
    CharacterClass.scholar => classDesc_scholar,
    CharacterClass.warden => classDesc_warden,
    CharacterClass.artisan => classDesc_artisan,
    CharacterClass.vanguard => classDesc_vanguard,
    CharacterClass.envoy => classDesc_envoy,
    CharacterClass.druid => classDesc_druid,
    CharacterClass.explorer => classDesc_explorer,
    CharacterClass.strategist => classDesc_strategist,
    CharacterClass.arcanist => classDesc_arcanist,
  };

  String achievementName(String id) => switch (id) {
    'first_oath' => achievement_first_oath_name,
    'deeds_10' => achievement_deeds_10_name,
    'deeds_100' => achievement_deeds_100_name,
    'deeds_1000' => achievement_deeds_1000_name,
    'first_contract' => achievement_first_contract_name,
    'first_objective' => achievement_first_objective_name,
    'level_5' => achievement_level_5_name,
    'level_10' => achievement_level_10_name,
    'level_25' => achievement_level_25_name,
    'rank_10_strength' => achievement_rank_10_strength_name,
    'rank_10_intelligence' => achievement_rank_10_intelligence_name,
    'rank_10_discipline' => achievement_rank_10_discipline_name,
    'rank_10_creativity' => achievement_rank_10_creativity_name,
    'rank_10_vitality' => achievement_rank_10_vitality_name,
    'rank_10_social' => achievement_rank_10_social_name,
    'kept_weeks_4' => achievement_kept_weeks_4_name,
    'kept_weeks_12' => achievement_kept_weeks_12_name,
    'kept_weeks_52' => achievement_kept_weeks_52_name,
    'the_return' => achievement_the_return_name,
    'balanced' => achievement_balanced_name,
    'hours_100' => achievement_hours_100_name,
    _ => id,
  };

  String achievementDescription(String id) => switch (id) {
    'first_oath' => achievement_first_oath_desc,
    'deeds_10' => achievement_deeds_10_desc,
    'deeds_100' => achievement_deeds_100_desc,
    'deeds_1000' => achievement_deeds_1000_desc,
    'first_contract' => achievement_first_contract_desc,
    'first_objective' => achievement_first_objective_desc,
    'level_5' => achievement_level_5_desc,
    'level_10' => achievement_level_10_desc,
    'level_25' => achievement_level_25_desc,
    'rank_10_strength' => achievement_rank_10_strength_desc,
    'rank_10_intelligence' => achievement_rank_10_intelligence_desc,
    'rank_10_discipline' => achievement_rank_10_discipline_desc,
    'rank_10_creativity' => achievement_rank_10_creativity_desc,
    'rank_10_vitality' => achievement_rank_10_vitality_desc,
    'rank_10_social' => achievement_rank_10_social_desc,
    'kept_weeks_4' => achievement_kept_weeks_4_desc,
    'kept_weeks_12' => achievement_kept_weeks_12_desc,
    'kept_weeks_52' => achievement_kept_weeks_52_desc,
    'the_return' => achievement_the_return_desc,
    'balanced' => achievement_balanced_desc,
    'hours_100' => achievement_hours_100_desc,
    _ => '',
  };

  String titleName(String id) => switch (id) {
    'sworn' => title_sworn,
    'centurion' => title_centurion,
    'pathfinder' => title_pathfinder,
    'seasoned' => title_seasoned,
    'ironbound' => title_ironbound,
    'adept_of_lore' => title_adept_of_lore,
    'unbending' => title_unbending,
    'dreamwright' => title_dreamwright,
    'evergreen' => title_evergreen,
    'kindred' => title_kindred,
    'steadfast' => title_steadfast,
    'oathkeeper' => title_oathkeeper,
    'returned' => title_returned,
    'whole' => title_whole,
    _ => id,
  };

  /// Plain-language explanation for an engine adjustment.
  String adjustmentText(Adjustment a, AppFormatters f) {
    String param(String k) => '${a.params[k] ?? ''}';
    Attribute? attr() => Attribute.tryParse(a.params['attribute']);
    return switch (a.code) {
      AdjustmentCode.durationPlausibility => adj_duration_plausibility(
        f.number(num.tryParse(param('credited')) ?? 0),
        f.number(num.tryParse(param('declared')) ?? 0),
      ),
      AdjustmentCode.tierMinutesCap => adj_tier_minutes_cap(f.number(num.tryParse(param('cap')) ?? 0)),
      AdjustmentCode.dailyBudget => adj_daily_budget,
      AdjustmentCode.tierBonus => adj_tier_bonus(tierName(QuestTier.parse(a.params['tier']))),
      AdjustmentCode.trivialFloor => adj_trivial_floor,
      AdjustmentCode.trivialLimit => adj_trivial_limit,
      AdjustmentCode.repetition => adj_repetition(f.number(num.tryParse(param('count')) ?? 0)),
      AdjustmentCode.lowConfidence => adj_low_confidence,
      AdjustmentCode.followThrough => a.params['intention'] == true ? adj_follow_through_intention : adj_follow_through,
      AdjustmentCode.softCap => adj_soft_cap(attr() == null ? '' : attributeName(attr()!)),
      AdjustmentCode.hardCap => adj_hard_cap(attr() == null ? '' : attributeName(attr()!)),
      AdjustmentCode.weightsDefaulted => adj_weights_defaulted,
      _ => a.code,
    };
  }
}
