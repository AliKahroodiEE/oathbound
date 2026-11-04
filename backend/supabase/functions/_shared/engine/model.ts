/**
 * Core vocabulary and data shapes of the progression engine.
 *
 * TypeScript twin of `model.dart`, `proposal.dart`, `facts.dart` and
 * `result.dart` in `packages/oathbound_engine/lib/src/`. Only erasable
 * TypeScript syntax is used (no `enum`, namespaces or parameter properties)
 * so the same file runs under Deno and under Node's built-in type stripping.
 */

// ---------------------------------------------------------------------------
// Vocabulary
// ---------------------------------------------------------------------------

/** The six permanent character attributes, in canonical (tie-break) order. */
export const ATTRIBUTES = [
  'strength',
  'intelligence',
  'discipline',
  'creativity',
  'vitality',
  'social',
] as const;
export type Attribute = (typeof ATTRIBUTES)[number];

/** Activity categories understood by both evaluators, in canonical order. */
export const CATEGORIES = [
  'study',
  'work',
  'fitness',
  'health',
  'creative',
  'social',
  'chores',
  'admin',
  'mindfulness',
  'reading',
  'other',
] as const;
export type QuestCategory = (typeof CATEGORIES)[number];

export const TIERS = ['daily', 'contract', 'objective'] as const;
export type QuestTier = (typeof TIERS)[number];

export const PROPOSAL_SOURCES = ['ai', 'heuristic'] as const;
export type ProposalSource = (typeof PROPOSAL_SOURCES)[number];

export function attributeIndex(attribute: Attribute): number {
  return ATTRIBUTES.indexOf(attribute);
}

export function categoryIndex(category: QuestCategory): number {
  return CATEGORIES.indexOf(category);
}

/** Mirrors `Attribute.tryParse`: unknown values yield `null`. */
export function parseAttribute(value: unknown): Attribute | null {
  return typeof value === 'string' && (ATTRIBUTES as readonly string[]).includes(value)
    ? (value as Attribute)
    : null;
}

/** Mirrors `QuestCategory.parse`: unknown values fall back to `other`. */
export function parseCategory(value: unknown): QuestCategory {
  return typeof value === 'string' && (CATEGORIES as readonly string[]).includes(value)
    ? (value as QuestCategory)
    : 'other';
}

/** Mirrors `QuestTier.parse`: unknown values fall back to `daily`. */
export function parseTier(value: unknown): QuestTier {
  return typeof value === 'string' && (TIERS as readonly string[]).includes(value)
    ? (value as QuestTier)
    : 'daily';
}

/** Mirrors `ProposalSource.parse`: anything but `ai` is `heuristic`. */
export function parseSource(value: unknown): ProposalSource {
  return value === 'ai' ? 'ai' : 'heuristic';
}

/**
 * Fallback attribute weights (progression rules §8.1). Object key order is
 * significant: it matches the Dart map literal order, which the heuristic
 * evaluator uses when listing proposal attributes.
 */
export const CATEGORY_DEFAULT_WEIGHTS: Readonly<
  Record<QuestCategory, Readonly<Partial<Record<Attribute, number>>>>
> = {
  study: { intelligence: 0.8, discipline: 0.2 },
  reading: { intelligence: 0.8, creativity: 0.2 },
  work: { discipline: 0.6, intelligence: 0.4 },
  fitness: { strength: 0.7, vitality: 0.3 },
  health: { vitality: 0.8, discipline: 0.2 },
  mindfulness: { vitality: 0.6, discipline: 0.4 },
  creative: { creativity: 0.8, discipline: 0.2 },
  social: { social: 1.0 },
  chores: { discipline: 0.7, vitality: 0.3 },
  admin: { discipline: 0.8, intelligence: 0.2 },
  other: { discipline: 1.0 },
};

/** Ordered `[attribute, weight]` pairs of a category's default weights. */
export function defaultWeightEntries(category: QuestCategory): Array<[Attribute, number]> {
  const entries: Array<[Attribute, number]> = [];
  const weights = CATEGORY_DEFAULT_WEIGHTS[category];
  for (const key of Object.keys(weights)) {
    const attribute = key as Attribute;
    entries.push([attribute, weights[attribute] as number]);
  }
  return entries;
}

// ---------------------------------------------------------------------------
// Numeric helpers (Dart semantics)
// ---------------------------------------------------------------------------

/**
 * Dart's `num.round()`: rounds half away from zero. `Math.round` rounds
 * half towards +∞, which differs for negative ties (−2.5 → −2 vs −3).
 */
export function roundHalfAwayFromZero(value: number): number {
  if (!Number.isFinite(value)) {
    throw new RangeError(`cannot round non-finite value ${value}`);
  }
  const rounded = Math.round(Math.abs(value));
  // Dart returns an int, which has no negative zero.
  return value < 0 && rounded !== 0 ? -rounded : rounded;
}

/** Dart's `num.clamp(lower, upper)`. */
export function clamp(value: number, lower: number, upper: number): number {
  return value < lower ? lower : value > upper ? upper : value;
}

/** Thrown when untrusted JSON lacks required structure (Dart `FormatException`). */
export class FormatError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'FormatError';
  }
}

function isFiniteNumber(value: unknown): value is number {
  return typeof value === 'number' && Number.isFinite(value);
}

function isPlainObject(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

// ---------------------------------------------------------------------------
// Proposal (progression rules §3)
// ---------------------------------------------------------------------------

/** One attribute an evaluator believes the activity developed. */
export interface AttributeWeight {
  attribute: Attribute;
  weight: number;
  /** Rationale in the user's AI language; empty for heuristic proposals. */
  reason: string;
}

/** The evaluator's structured interpretation of a completion. Advice, not a grant. */
export interface EvaluationProposal {
  category: QuestCategory;
  similarityKey: string;
  difficulty: number;
  estimatedMinutes: number;
  attributes: AttributeWeight[];
  trivial: boolean;
  confidence: number;
  summary: string;
  source: ProposalSource;
}

/**
 * Lowercases, collapses whitespace/punctuation to `-`, guarantees a
 * `category.` prefix and caps the length at 48 characters
 * (twin of `normaliseSimilarityKey` in `proposal.dart`).
 */
export function normaliseSimilarityKey(key: string, category: QuestCategory): string {
  let k = key.trim().toLowerCase();
  k = k.replace(/[\s_/\\,;:!?"()[\]{}]+/g, '-');
  k = k.replace(/-+/g, '-');
  k = k.replace(/^-|-$/g, '');
  if (k.length === 0) k = category;
  if (!k.startsWith(`${category}.`) && k !== category) {
    k = `${category}.${k}`;
  }
  if (k.length > 48) k = k.substring(0, 48);
  return k;
}

/**
 * Parses untrusted JSON (e.g. model output) exactly like
 * `EvaluationProposal.fromJson`: throws {@link FormatError} when required
 * structure is missing and tolerates out-of-range numbers (the engine clamps).
 */
export function proposalFromJson(json: Record<string, unknown>): EvaluationProposal {
  const rawAttributes = json['attributes'];
  if (!Array.isArray(rawAttributes)) {
    throw new FormatError('attributes must be a list');
  }
  const attributes: AttributeWeight[] = [];
  for (const item of rawAttributes) {
    if (!isPlainObject(item)) continue;
    const attribute = parseAttribute(item['attribute']);
    const weight = item['weight'];
    if (attribute === null || !isFiniteNumber(weight)) continue;
    const reason = item['reason'];
    attributes.push({
      attribute,
      weight,
      reason: typeof reason === 'string' ? reason : '',
    });
  }
  const difficulty = json['difficulty'];
  const minutes = json['estimatedMinutes'];
  if (!isFiniteNumber(difficulty) || !isFiniteNumber(minutes)) {
    throw new FormatError('difficulty and estimatedMinutes required');
  }
  const key = json['similarityKey'];
  const confidence = json['confidence'];
  const summary = json['summary'];
  const category = parseCategory(json['category']);
  return {
    category,
    similarityKey: normaliseSimilarityKey(typeof key === 'string' ? key : '', category),
    difficulty: roundHalfAwayFromZero(difficulty),
    estimatedMinutes: roundHalfAwayFromZero(minutes),
    attributes,
    trivial: json['trivial'] === true,
    confidence: isFiniteNumber(confidence) ? confidence : 0.5,
    summary: typeof summary === 'string' ? summary : '',
    source: parseSource(json['source']),
  };
}

export function proposalToJson(proposal: EvaluationProposal): Record<string, unknown> {
  return {
    category: proposal.category,
    similarityKey: proposal.similarityKey,
    difficulty: proposal.difficulty,
    estimatedMinutes: proposal.estimatedMinutes,
    attributes: proposal.attributes.map((a) => ({
      attribute: a.attribute,
      weight: a.weight,
      reason: a.reason,
    })),
    trivial: proposal.trivial,
    confidence: proposal.confidence,
    summary: proposal.summary,
    source: proposal.source,
  };
}

// ---------------------------------------------------------------------------
// Completion facts (progression rules §4)
// ---------------------------------------------------------------------------

export interface CompletionFacts {
  tier: QuestTier;
  createdAt: Date;
  completedAt: Date;
  declaredMinutes: number | null;
  trackedMinutes: number | null;
  dueAt: Date | null;
  isRecurringOccurrence: boolean;
  hasImplementationIntention: boolean;
}

function parseDate(value: unknown): Date | null {
  if (typeof value !== 'string') return null;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    throw new FormatError(`invalid date: ${value}`);
  }
  return date;
}

function parseOptionalInt(value: unknown): number | null {
  return isFiniteNumber(value) ? roundHalfAwayFromZero(value) : null;
}

/** Twin of `CompletionFacts.fromJson`. */
export function factsFromJson(json: Record<string, unknown>): CompletionFacts {
  const createdAt = parseDate(json['createdAt']);
  const completedAt = parseDate(json['completedAt']);
  if (createdAt === null || completedAt === null) {
    throw new FormatError('createdAt and completedAt required');
  }
  return {
    tier: parseTier(json['tier']),
    createdAt,
    completedAt,
    declaredMinutes: parseOptionalInt(json['declaredMinutes']),
    trackedMinutes: parseOptionalInt(json['trackedMinutes']),
    dueAt: parseDate(json['dueAt']),
    isRecurringOccurrence: json['isRecurringOccurrence'] === true,
    hasImplementationIntention: json['hasImplementationIntention'] === true,
  };
}

export function factsToJson(facts: CompletionFacts): Record<string, unknown> {
  return {
    tier: facts.tier,
    createdAt: facts.createdAt.toISOString(),
    completedAt: facts.completedAt.toISOString(),
    declaredMinutes: facts.declaredMinutes,
    trackedMinutes: facts.trackedMinutes,
    dueAt: facts.dueAt === null ? null : facts.dueAt.toISOString(),
    isRecurringOccurrence: facts.isRecurringOccurrence,
    hasImplementationIntention: facts.hasImplementationIntention,
  };
}

// ---------------------------------------------------------------------------
// Day state
// ---------------------------------------------------------------------------

/** What has already been credited during the user's current local day. */
export interface DayState {
  /** Pre-cap XP already granted per attribute today. */
  rawXp: Partial<Record<Attribute, number>>;
  creditedMinutes: number;
  similarityCounts: Record<string, number>;
  trivialCount: number;
}

export function emptyDayState(): DayState {
  return { rawXp: {}, creditedMinutes: 0, similarityCounts: {}, trivialCount: 0 };
}

/** Twin of `DayState.fromJson`; tolerant of missing or malformed fields. */
export function dayStateFromJson(json: Record<string, unknown>): DayState {
  const rawXp: Partial<Record<Attribute, number>> = {};
  const rawJson = json['rawXp'];
  if (isPlainObject(rawJson)) {
    for (const [k, v] of Object.entries(rawJson)) {
      const attribute = parseAttribute(k);
      if (attribute !== null && isFiniteNumber(v)) rawXp[attribute] = roundHalfAwayFromZero(v);
    }
  }
  const similarityCounts: Record<string, number> = {};
  const simJson = json['similarityCounts'];
  if (isPlainObject(simJson)) {
    for (const [k, v] of Object.entries(simJson)) {
      if (isFiniteNumber(v)) similarityCounts[k] = roundHalfAwayFromZero(v);
    }
  }
  const minutes = json['creditedMinutes'];
  const trivial = json['trivialCount'];
  return {
    rawXp,
    creditedMinutes: isFiniteNumber(minutes) ? roundHalfAwayFromZero(minutes) : 0,
    similarityCounts,
    trivialCount: isFiniteNumber(trivial) ? roundHalfAwayFromZero(trivial) : 0,
  };
}

export function dayStateToJson(day: DayState): Record<string, unknown> {
  const rawXp: Record<string, number> = {};
  for (const attribute of ATTRIBUTES) {
    const value = day.rawXp[attribute];
    if (value !== undefined) rawXp[attribute] = value;
  }
  return {
    rawXp,
    creditedMinutes: day.creditedMinutes,
    similarityCounts: { ...day.similarityCounts },
    trivialCount: day.trivialCount,
  };
}

// ---------------------------------------------------------------------------
// Result
// ---------------------------------------------------------------------------

/** XP credited to one attribute. */
export interface Grant {
  attribute: Attribute;
  /** XP actually credited after caps. */
  amount: number;
  /** XP before daily caps; feeds per-day cap accounting. */
  rawAmount: number;
}

/** Stable codes for every rule that changed a result (clients localize them). */
export const AdjustmentCode = {
  durationPlausibility: 'duration_plausibility',
  tierMinutesCap: 'tier_minutes_cap',
  dailyBudget: 'daily_budget',
  tierBonus: 'tier_bonus',
  trivialFloor: 'trivial_floor',
  trivialLimit: 'trivial_limit',
  repetition: 'repetition',
  lowConfidence: 'low_confidence',
  followThrough: 'follow_through',
  softCap: 'soft_cap',
  hardCap: 'hard_cap',
  weightsDefaulted: 'weights_defaulted',
} as const;
export type AdjustmentCodeValue = (typeof AdjustmentCode)[keyof typeof AdjustmentCode];

export type AdjustmentParamValue = string | number | boolean;

export interface Adjustment {
  code: AdjustmentCodeValue;
  params: Record<string, AdjustmentParamValue>;
}

/** The engine's validated, capped and explained outcome for a completion. */
export interface RewardResult {
  grants: Grant[];
  effectiveMinutes: number;
  trivial: boolean;
  similarityKey: string;
  adjustments: Adjustment[];
  ruleVersion: string;
  source: ProposalSource;
}

export function totalXp(result: RewardResult): number {
  let sum = 0;
  for (const g of result.grants) sum += g.amount;
  return sum;
}

export function hasAdjustment(result: RewardResult, code: AdjustmentCodeValue): boolean {
  return result.adjustments.some((a) => a.code === code);
}

export function amountFor(result: RewardResult, attribute: Attribute): number {
  for (const g of result.grants) {
    if (g.attribute === attribute) return g.amount;
  }
  return 0;
}

/** Twin of `RewardResult.applyTo`: the day state after this result is credited. */
export function applyResultToDay(result: RewardResult, day: DayState): DayState {
  const rawXp: Partial<Record<Attribute, number>> = { ...day.rawXp };
  for (const g of result.grants) {
    rawXp[g.attribute] = (rawXp[g.attribute] ?? 0) + g.rawAmount;
  }
  const similarityCounts: Record<string, number> = { ...day.similarityCounts };
  similarityCounts[result.similarityKey] = (similarityCounts[result.similarityKey] ?? 0) + 1;
  return {
    rawXp,
    creditedMinutes: day.creditedMinutes + result.effectiveMinutes,
    similarityCounts,
    trivialCount: day.trivialCount + (result.trivial ? 1 : 0),
  };
}

/**
 * Wire format shared with the Dart client and stored in the ledger.
 * Key order mirrors `RewardResult.toJson` in Dart.
 */
export function resultToJson(result: RewardResult): Record<string, unknown> {
  return {
    grants: result.grants.map((g) => ({
      attribute: g.attribute,
      amount: g.amount,
      rawAmount: g.rawAmount,
    })),
    totalXp: totalXp(result),
    effectiveMinutes: result.effectiveMinutes,
    trivial: result.trivial,
    similarityKey: result.similarityKey,
    adjustments: result.adjustments.map((a) => ({ code: a.code, params: { ...a.params } })),
    ruleVersion: result.ruleVersion,
    source: result.source,
  };
}
