/**
 * Conformance tests for the TypeScript engine (ADR-004).
 *
 * Loads the SAME vector files the Dart engine tests use and asserts that
 * every result serialises to exactly the expected JSON. Run with:
 *
 *   node --test backend/supabase/functions/_shared/engine/
 *
 * (Node ≥ 23.6 strips the erasable TypeScript syntax natively.)
 */
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { describe, test } from 'node:test';

import {
  applyResultToDay,
  dayStateFromJson,
  evaluate,
  factsFromJson,
  level,
  proposalFromJson,
  resultToJson,
  roundHalfAwayFromZero,
  RULES_VERSION,
  totalXpForLevel,
  xpToAdvanceLevel,
  xpToAdvanceRank,
} from './index.ts';

const VECTORS = new URL('../../../../../packages/oathbound_engine/test/vectors/', import.meta.url);

interface RewardCase {
  name: string;
  proposal: Record<string, unknown>;
  facts: Record<string, unknown>;
  day: Record<string, unknown>;
  expected: Record<string, unknown>;
}

function loadJson<T>(file: string): T {
  return JSON.parse(readFileSync(new URL(file, VECTORS), 'utf8')) as T;
}

const rewards = loadJson<{ ruleVersion: string; cases: RewardCase[] }>('reward_cases.json');
const curves = loadJson<{
  ruleVersion: string;
  levelCosts: number[];
  rankCosts: number[];
  levelAt: Record<string, number>;
}>('curves.json');

test('vectors match the current rule version', () => {
  assert.equal(rewards.ruleVersion, RULES_VERSION);
  assert.equal(curves.ruleVersion, RULES_VERSION);
});

describe('reward vectors', () => {
  test('vector file contains the expected number of cases', () => {
    assert.equal(rewards.cases.length, 37);
  });

  for (const c of rewards.cases) {
    test(c.name, () => {
      const result = evaluate(
        proposalFromJson(c.proposal),
        factsFromJson(c.facts),
        dayStateFromJson(c.day),
      );
      // Round-trip through JSON exactly like the Dart test (jsonDecode(jsonEncode(...))).
      const actual = JSON.parse(JSON.stringify(resultToJson(result)));
      assert.deepStrictEqual(actual, c.expected);
    });
  }
});

describe('curve vectors', () => {
  test('level and rank costs', () => {
    for (let n = 1; n <= curves.levelCosts.length; n++) {
      assert.equal(xpToAdvanceLevel(n), curves.levelCosts[n - 1], `level cost n=${n}`);
      assert.equal(xpToAdvanceRank(n), curves.rankCosts[n - 1], `rank cost n=${n}`);
    }
  });

  test('level at XP', () => {
    for (const [xp, expected] of Object.entries(curves.levelAt)) {
      assert.equal(level(Number(xp)).step, expected, `level at ${xp} XP`);
    }
  });

  test('totalXpForLevel is the inverse of level()', () => {
    for (let l = 1; l <= 30; l++) {
      const xp = totalXpForLevel(l);
      assert.equal(level(xp).step, l);
      if (xp > 0) assert.equal(level(xp - 1).step, l - 1);
    }
  });

  test('negative XP clamps to level 1', () => {
    assert.deepStrictEqual(level(-50), { step: 1, xpIntoStep: 0, xpForNextStep: 100 });
  });
});

describe('engine invariants', () => {
  test('roundHalfAwayFromZero matches Dart num.round()', () => {
    assert.equal(roundHalfAwayFromZero(2.5), 3);
    assert.equal(roundHalfAwayFromZero(-2.5), -3);
    assert.equal(roundHalfAwayFromZero(0.49999999999999994), 0);
    assert.equal(roundHalfAwayFromZero(-0.4), 0);
    assert.throws(() => roundHalfAwayFromZero(Number.NaN));
  });

  test('applyResultToDay accumulates raw XP, minutes, similarity and trivial counts', () => {
    const c = rewards.cases.find((x) => x.name === 'worked_example') as RewardCase;
    const day0 = dayStateFromJson({});
    const result = evaluate(proposalFromJson(c.proposal), factsFromJson(c.facts), day0);
    const day1 = applyResultToDay(result, day0);
    assert.deepStrictEqual(day1.rawXp, { intelligence: 31, discipline: 14 });
    assert.equal(day1.creditedMinutes, 90);
    assert.deepStrictEqual(day1.similarityCounts, { 'study.electronics': 1 });
    assert.equal(day1.trivialCount, 0);

    // The same activity again the same day is diminished (§5.5).
    const second = evaluate(proposalFromJson(c.proposal), factsFromJson(c.facts), day1);
    assert.ok(second.adjustments.some((a) => a.code === 'repetition'));
  });

  test('a prompt-injected proposal cannot exceed the daily caps', () => {
    const result = evaluate(
      proposalFromJson({
        category: 'study',
        similarityKey: 'study.anything',
        difficulty: 1000,
        estimatedMinutes: 100000,
        attributes: [{ attribute: 'intelligence', weight: 1e9, reason: '' }],
        trivial: false,
        confidence: 99,
        source: 'ai',
      }),
      factsFromJson({
        tier: 'objective',
        createdAt: '2026-11-01T00:00:00.000Z',
        completedAt: '2026-11-04T00:00:00.000Z',
        declaredMinutes: 100000,
      }),
      dayStateFromJson({}),
    );
    for (const g of result.grants) assert.ok(g.amount <= 400, `${g.attribute} ${g.amount}`);
    assert.equal(result.effectiveMinutes, 480);
  });
});
