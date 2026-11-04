/// Every tunable number of the progression rulebook.
///
/// Changing any value here requires bumping [rulesVersion], updating
/// `docs/product/progression-rules.md`, and adding conformance vectors.
library;

import 'model.dart';

const String rulesVersion = '2026.11.1';

/// Base XP constant in `base = k × (m / 30)^e × D × T`.
const double baseXpConstant = 20;
const double durationExponent = 0.65;
const double durationReferenceMinutes = 30;

const Map<int, double> difficultyMultiplier = {
  1: 0.50,
  2: 0.75,
  3: 1.00,
  4: 1.30,
  5: 1.60,
};

const Map<QuestTier, double> tierMultiplier = {
  QuestTier.daily: 1.00,
  QuestTier.contract: 1.25,
  QuestTier.objective: 1.50,
};

const Map<QuestTier, int> tierMinutesCap = {
  QuestTier.daily: 240,
  QuestTier.contract: 480,
  QuestTier.objective: 480,
};

/// Declared minutes may not exceed `max(estimate × k, floor)`.
const int plausibilityFactor = 2;
const int plausibilityFloorMinutes = 15;

/// Credited minutes per local day.
const int dailyMinutesBudget = 960;

/// Trivial tasks.
const int trivialMinutesThreshold = 5;
const double trivialMaxXp = 3;
const int trivialDailyLimit = 10;

/// Per-day repetition multipliers by prior same-key completions.
const List<double> repetitionMultipliers = [1.00, 0.80, 0.60, 0.40, 0.25];
const double repetitionFloor = 0.10;

/// Confidence below which AI proposals are discounted.
const double lowConfidenceThreshold = 0.40;
const double lowConfidenceMultiplier = 0.75;

/// Follow-through bonus (Discipline).
const Duration plannedAheadThreshold = Duration(minutes: 60);
const double followThroughRate = 0.10;
const double intentionRate = 0.05;
const double followThroughMinimum = 1;

/// Per-attribute daily caps on raw XP.
const double softCapXp = 200;
const double hardCapXp = 400;

/// Attribute weight normalisation.
const int maxWeightedAttributes = 3;
const double minAttributeWeight = 0.10;

/// Level and rank curves: XP to advance from n to n + 1.
const double levelCurveBase = 100;
const double levelCurveExponent = 1.5;
const double rankCurveBase = 40;
const double rankCurveExponent = 1.4;

/// Condition (HP).
const int conditionMax = 100;
const int conditionMin = 25;
const int strainThresholdMinutes = 600;
const int strainPer10Minutes = 1;
const int strainMaxPerDay = 30;
const int recoveryPerCalmDay = 15;
const int vitalityRecoveryXp = 20;
const int vitalityRecoveryBonus = 10;
const int restDayRecovery = 25;

/// Consistency.
const int defaultWeeklyTarget = 4;
const int forgivenMissesPerWeek = 1;
const int returnGapDays = 3;
const int returnAchievementGapDays = 7;

/// Classes.
const int classRevealLevel = 5;
const double explorerMaxTopShare = 0.25;
const double explorerMinShare = 0.10;
const int explorerMinAttributes = 5;
const double hybridMinShare = 0.25;
