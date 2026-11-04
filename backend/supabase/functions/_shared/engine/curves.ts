/**
 * Level and rank curves (progression rules §6). Twin of `curves.dart`.
 *
 * The SQL functions `public.xp_to_advance_level` / `public.level_for_xp`
 * implement the same curve for the character cache; the validation script
 * checks both against `curves.json`.
 */
import { roundHalfAwayFromZero } from './model.ts';
import * as rules from './rules.ts';

/**
 * Position on a progression curve: the current step and the exact XP into
 * and required for the next step. Progress bars use these numbers directly,
 * never an inflated proportion.
 */
export interface CurveProgress {
  step: number;
  xpIntoStep: number;
  xpForNextStep: number;
}

export function xpRemaining(progress: CurveProgress): number {
  return progress.xpForNextStep - progress.xpIntoStep;
}

export function fraction(progress: CurveProgress): number {
  return progress.xpForNextStep === 0 ? 0 : progress.xpIntoStep / progress.xpForNextStep;
}

/** XP needed to go from character level `n` to `n + 1`: round(100 × n^1.5). */
export function xpToAdvanceLevel(n: number): number {
  return roundHalfAwayFromZero(rules.LEVEL_CURVE_BASE * Math.pow(n, rules.LEVEL_CURVE_EXPONENT));
}

/** XP needed to go from attribute rank `n` to `n + 1`: round(40 × n^1.4). */
export function xpToAdvanceRank(n: number): number {
  return roundHalfAwayFromZero(rules.RANK_CURVE_BASE * Math.pow(n, rules.RANK_CURVE_EXPONENT));
}

export function level(totalXp: number): CurveProgress {
  return walk(totalXp, xpToAdvanceLevel);
}

export function rank(attributeXp: number): CurveProgress {
  return walk(attributeXp, xpToAdvanceRank);
}

/** Total XP required to reach `targetLevel` from zero. */
export function totalXpForLevel(targetLevel: number): number {
  let total = 0;
  for (let n = 1; n < targetLevel; n++) total += xpToAdvanceLevel(n);
  return total;
}

function walk(xp: number, cost: (n: number) => number): CurveProgress {
  let step = 1;
  let remaining = Math.max(0, xp);
  while (remaining >= cost(step)) {
    remaining -= cost(step);
    step++;
  }
  return { step, xpIntoStep: remaining, xpForNextStep: cost(step) };
}
