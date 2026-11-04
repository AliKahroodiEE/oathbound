/**
 * The deterministic progression engine (progression rules §5).
 *
 * TypeScript twin of `packages/oathbound_engine/lib/src/engine.dart`. A pure
 * function of its inputs: the same proposal, facts and day state always
 * produce the same result on every platform. The server result is
 * authoritative; both engines must reproduce the shared conformance vectors.
 */
import {
  type Adjustment,
  AdjustmentCode,
  type Attribute,
  ATTRIBUTES,
  attributeIndex,
  type AttributeWeight,
  clamp,
  type CompletionFacts,
  type DayState,
  defaultWeightEntries,
  emptyDayState,
  type EvaluationProposal,
  type Grant,
  normaliseSimilarityKey,
  type RewardResult,
  roundHalfAwayFromZero,
} from './model.ts';
import * as rules from './rules.ts';

/** Ordered `[attribute, weight]` pairs; insertion order matters like a Dart map. */
type WeightEntries = Array<[Attribute, number]>;

export function evaluate(
  proposal: EvaluationProposal,
  facts: CompletionFacts,
  day: DayState = emptyDayState(),
): RewardResult {
  const adjustments: Adjustment[] = [];

  // §5.1 Normalise the proposal.
  const difficulty = clamp(proposal.difficulty, 1, 5);
  const confidence = clamp(proposal.confidence, 0, 1);
  const estimate = clamp(proposal.estimatedMinutes, 1, 600);
  let weights = normaliseWeights(proposal.attributes);
  if (weights.length === 0) {
    weights = defaultWeightEntries(proposal.category);
    adjustments.push({ code: AdjustmentCode.weightsDefaulted, params: {} });
  }

  // §5.2 Effective minutes.
  const minutes = effectiveMinutes(facts, estimate, day, adjustments);

  // §5.3 Base XP.
  const tierFactor = rules.TIER_MULTIPLIER[facts.tier];
  let base = minutes <= 0
    ? 0
    : rules.BASE_XP_CONSTANT *
      Math.pow(minutes / rules.DURATION_REFERENCE_MINUTES, rules.DURATION_EXPONENT) *
      (rules.DIFFICULTY_MULTIPLIER[difficulty] as number) *
      tierFactor;
  if (facts.tier !== 'daily') {
    adjustments.push({
      code: AdjustmentCode.tierBonus,
      params: { tier: facts.tier, multiplier: tierFactor },
    });
  }

  // §5.4 Trivial tasks.
  const trivial = proposal.trivial || minutes < rules.TRIVIAL_MINUTES_THRESHOLD;
  if (trivial) {
    if (day.trivialCount >= rules.TRIVIAL_DAILY_LIMIT) {
      base = 0;
      adjustments.push({
        code: AdjustmentCode.trivialLimit,
        params: { limit: rules.TRIVIAL_DAILY_LIMIT },
      });
    } else if (base > rules.TRIVIAL_MAX_XP) {
      base = rules.TRIVIAL_MAX_XP;
      adjustments.push({
        code: AdjustmentCode.trivialFloor,
        params: { max: rules.TRIVIAL_MAX_XP },
      });
    }
  }

  // §5.5 Repetition (per local day only).
  const key = normaliseSimilarityKey(proposal.similarityKey, proposal.category);
  const repeats = day.similarityCounts[key] ?? 0;
  const repetition = repetitionMultiplier(repeats);
  if (repeats > 0) {
    adjustments.push({
      code: AdjustmentCode.repetition,
      params: { count: repeats + 1, multiplier: repetition },
    });
  }

  // §5.6 Confidence (AI proposals only; heuristic evaluations carry no penalty).
  let confidenceFactor = 1;
  if (proposal.source === 'ai' && confidence < rules.LOW_CONFIDENCE_THRESHOLD) {
    confidenceFactor = rules.LOW_CONFIDENCE_MULTIPLIER;
    adjustments.push({
      code: AdjustmentCode.lowConfidence,
      params: { multiplier: rules.LOW_CONFIDENCE_MULTIPLIER },
    });
  }

  // §5.7 Distribute.
  const adjusted = base * repetition * confidenceFactor;
  const raw = new Map<Attribute, number>();
  for (const [attribute, weight] of weights) raw.set(attribute, adjusted * weight);

  // §5.8 Follow-through bonus (deterministic Discipline).
  if (!trivial && adjusted > 0 && followedThrough(facts)) {
    const rate = rules.FOLLOW_THROUGH_RATE +
      (facts.hasImplementationIntention ? rules.INTENTION_RATE : 0);
    const bonus = Math.max(adjusted * rate, rules.FOLLOW_THROUGH_MINIMUM);
    raw.set('discipline', (raw.get('discipline') ?? 0) + bonus);
    adjustments.push({
      code: AdjustmentCode.followThrough,
      params: { rate, intention: facts.hasImplementationIntention },
    });
  }

  // §5.9 Daily caps (per attribute). Raw amounts are rounded before caps.
  const grants: Grant[] = [];
  for (const attribute of ATTRIBUTES) {
    const value = raw.get(attribute);
    if (value === undefined) continue;
    const rawAmount = roundHalfAwayFromZero(value);
    if (rawAmount <= 0) continue;
    const before = day.rawXp[attribute] ?? 0;
    const amount = roundHalfAwayFromZero(cappedXp(before + rawAmount) - cappedXp(before));
    if (amount < rawAmount) {
      const saturated = before + rawAmount >=
        rules.SOFT_CAP_XP + 2 * (rules.HARD_CAP_XP - rules.SOFT_CAP_XP);
      adjustments.push({
        code: saturated ? AdjustmentCode.hardCap : AdjustmentCode.softCap,
        params: { attribute },
      });
    }
    if (amount > 0) grants.push({ attribute, amount, rawAmount });
  }

  return {
    grants,
    effectiveMinutes: minutes,
    trivial,
    similarityKey: key,
    adjustments,
    ruleVersion: rules.RULES_VERSION,
    source: proposal.source,
  };
}

/**
 * Normalises proposal weights (§5.1): drop unknown, duplicates and
 * non-positive weights; scale to sum 1; keep the top three (ties broken by
 * attribute order); drop weights under 0.10 unless nothing would remain;
 * rescale the survivors.
 */
export function normaliseWeights(input: readonly AttributeWeight[]): WeightEntries {
  const best = new Map<Attribute, number>();
  for (const w of input) {
    if (!Number.isFinite(w.weight) || w.weight <= 0) continue;
    const prev = best.get(w.attribute);
    if (prev === undefined || w.weight > prev) best.set(w.attribute, w.weight);
  }
  if (best.size === 0) return [];
  let total = 0;
  for (const value of best.values()) total += value;
  const ranked: WeightEntries = [...best.entries()].sort((a, b) => {
    const byWeight = b[1] - a[1];
    return byWeight !== 0 ? Math.sign(byWeight) : attributeIndex(a[0]) - attributeIndex(b[0]);
  });
  const top = ranked.slice(0, rules.MAX_WEIGHTED_ATTRIBUTES);
  let kept = top.filter((e) => e[1] / total >= rules.MIN_ATTRIBUTE_WEIGHT);
  if (kept.length === 0) kept = [top[0] as [Attribute, number]];
  let keptTotal = 0;
  for (const e of kept) keptTotal += e[1];
  return kept.map(([attribute, weight]): [Attribute, number] => [attribute, weight / keptTotal]);
}

/** Repetition multiplier for a completion with `priorToday` earlier same-key completions. */
export function repetitionMultiplier(priorToday: number): number {
  return priorToday < rules.REPETITION_MULTIPLIERS.length
    ? (rules.REPETITION_MULTIPLIERS[priorToday] as number)
    : rules.REPETITION_FLOOR;
}

/** Effective XP for `rawToday` raw XP in one attribute on one day (§5.9). */
export function cappedXp(rawToday: number): number {
  const soft = rules.SOFT_CAP_XP;
  const over = clamp(rawToday - soft, 0, 2 * (rules.HARD_CAP_XP - soft));
  return Math.min(rawToday, soft) + 0.5 * over;
}

function effectiveMinutes(
  facts: CompletionFacts,
  estimate: number,
  day: DayState,
  adjustments: Adjustment[],
): number {
  let minutes: number;
  const tracked = facts.trackedMinutes;
  const declared = facts.declaredMinutes;
  if (tracked !== null && tracked >= 1) {
    minutes = tracked;
  } else if (declared !== null && declared > 0) {
    const limit = Math.max(
      rules.PLAUSIBILITY_FACTOR * estimate,
      rules.PLAUSIBILITY_FLOOR_MINUTES,
    );
    if (declared > limit) {
      minutes = limit;
      adjustments.push({
        code: AdjustmentCode.durationPlausibility,
        params: { declared, credited: limit },
      });
    } else {
      minutes = declared;
    }
  } else {
    minutes = estimate;
  }

  const cap = rules.TIER_MINUTES_CAP[facts.tier];
  if (minutes > cap) {
    minutes = cap;
    adjustments.push({ code: AdjustmentCode.tierMinutesCap, params: { cap } });
  }

  const remaining = Math.max(0, rules.DAILY_MINUTES_BUDGET - day.creditedMinutes);
  if (minutes > remaining) {
    minutes = remaining;
    adjustments.push({
      code: AdjustmentCode.dailyBudget,
      params: { budget: rules.DAILY_MINUTES_BUDGET },
    });
  }
  return minutes;
}

function followedThrough(facts: CompletionFacts): boolean {
  const planned = facts.isRecurringOccurrence ||
    facts.completedAt.getTime() - facts.createdAt.getTime() >= rules.PLANNED_AHEAD_THRESHOLD_MS;
  const due = facts.dueAt;
  const onTime = due === null || !(facts.completedAt.getTime() > due.getTime());
  return planned && onTime;
}
