/**
 * Server twin of the Oathbound progression engine (ADR-004).
 *
 * The authoritative specification is `docs/product/progression-rules.md`;
 * the Dart client engine lives in `packages/oathbound_engine`. Both must pass
 * the shared conformance vectors in `packages/oathbound_engine/test/vectors/`
 * (run `node --test backend/supabase/functions/_shared/engine/`).
 */
export * from './model.ts';
export { RULES_VERSION } from './rules.ts';
export { cappedXp, evaluate, normaliseWeights, repetitionMultiplier } from './engine.ts';
export {
  type CurveProgress,
  fraction,
  level,
  rank,
  totalXpForLevel,
  xpRemaining,
  xpToAdvanceLevel,
  xpToAdvanceRank,
} from './curves.ts';
export {
  evaluateHeuristic,
  extractMinutes,
  type HeuristicInput,
  normaliseText,
} from './heuristic.ts';
