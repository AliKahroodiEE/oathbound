/**
 * Every tunable number of the progression rulebook (TypeScript twin of
 * `packages/wyrd_engine/lib/src/rules.dart`).
 *
 * Changing any value here requires bumping RULES_VERSION in BOTH engines,
 * updating `docs/product/progression-rules.md`, and regenerating the shared
 * conformance vectors (ADR-004).
 */
import type { QuestTier } from './model.ts';

export const RULES_VERSION = '2026.11.1';

/** Base XP constant in `base = k × (m / 30)^e × D × T`. */
export const BASE_XP_CONSTANT = 20;
export const DURATION_EXPONENT = 0.65;
export const DURATION_REFERENCE_MINUTES = 30;

export const DIFFICULTY_MULTIPLIER: Readonly<Record<number, number>> = {
  1: 0.5,
  2: 0.75,
  3: 1.0,
  4: 1.3,
  5: 1.6,
};

export const TIER_MULTIPLIER: Readonly<Record<QuestTier, number>> = {
  daily: 1.0,
  contract: 1.25,
  objective: 1.5,
};

export const TIER_MINUTES_CAP: Readonly<Record<QuestTier, number>> = {
  daily: 240,
  contract: 480,
  objective: 480,
};

/** Declared minutes may not exceed `max(estimate × k, floor)`. */
export const PLAUSIBILITY_FACTOR = 2;
export const PLAUSIBILITY_FLOOR_MINUTES = 15;

/** Credited minutes per local day. */
export const DAILY_MINUTES_BUDGET = 960;

/** Trivial tasks. */
export const TRIVIAL_MINUTES_THRESHOLD = 5;
export const TRIVIAL_MAX_XP = 3;
export const TRIVIAL_DAILY_LIMIT = 10;

/** Per-day repetition multipliers by prior same-key completions. */
export const REPETITION_MULTIPLIERS: readonly number[] = [1.0, 0.8, 0.6, 0.4, 0.25];
export const REPETITION_FLOOR = 0.1;

/** Confidence below which AI proposals are discounted. */
export const LOW_CONFIDENCE_THRESHOLD = 0.4;
export const LOW_CONFIDENCE_MULTIPLIER = 0.75;

/** Follow-through bonus (Discipline). */
export const PLANNED_AHEAD_THRESHOLD_MS = 60 * 60 * 1000;
export const FOLLOW_THROUGH_RATE = 0.1;
export const INTENTION_RATE = 0.05;
export const FOLLOW_THROUGH_MINIMUM = 1;

/** Per-attribute daily caps on raw XP. */
export const SOFT_CAP_XP = 200;
export const HARD_CAP_XP = 400;

/** Attribute weight normalisation. */
export const MAX_WEIGHTED_ATTRIBUTES = 3;
export const MIN_ATTRIBUTE_WEIGHT = 0.1;

/** Level and rank curves: XP to advance from n to n + 1. */
export const LEVEL_CURVE_BASE = 100;
export const LEVEL_CURVE_EXPONENT = 1.5;
export const RANK_CURVE_BASE = 40;
export const RANK_CURVE_EXPONENT = 1.4;

/** Condition (HP). */
export const CONDITION_MAX = 100;
export const CONDITION_MIN = 25;
export const STRAIN_THRESHOLD_MINUTES = 600;
export const STRAIN_PER_10_MINUTES = 1;
export const STRAIN_MAX_PER_DAY = 30;
export const RECOVERY_PER_CALM_DAY = 15;
export const VITALITY_RECOVERY_XP = 20;
export const VITALITY_RECOVERY_BONUS = 10;
export const REST_DAY_RECOVERY = 25;

/** Consistency. */
export const DEFAULT_WEEKLY_TARGET = 4;
export const FORGIVEN_MISSES_PER_WEEK = 1;
export const RETURN_GAP_DAYS = 3;
export const RETURN_ACHIEVEMENT_GAP_DAYS = 7;

/** Classes. */
export const CLASS_REVEAL_LEVEL = 5;
export const EXPLORER_MAX_TOP_SHARE = 0.25;
export const EXPLORER_MIN_SHARE = 0.1;
export const EXPLORER_MIN_ATTRIBUTES = 5;
export const HYBRID_MIN_SHARE = 0.25;
