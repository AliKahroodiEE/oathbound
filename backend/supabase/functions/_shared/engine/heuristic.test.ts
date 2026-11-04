/**
 * Heuristic evaluator tests, mirroring
 * `packages/wyrd_engine/test/curves_heuristic_test.dart` so both
 * fallback evaluators classify identically.
 */
import assert from 'node:assert/strict';
import { describe, test } from 'node:test';

import {
  evaluateHeuristic,
  extractMinutes,
  normaliseText,
  type QuestTier,
} from './index.ts';

function evalTitle(title: string, tier: QuestTier = 'daily') {
  return evaluateHeuristic({ title, tier });
}

describe('heuristic evaluator', () => {
  test('classifies English activities', () => {
    assert.equal(evalTitle('Study electronics for 90 minutes').category, 'study');
    assert.equal(evalTitle('Go to the gym').category, 'fitness');
    assert.equal(evalTitle('Read 10 pages').category, 'reading');
    assert.equal(evalTitle('Call mom').category, 'social');
    assert.equal(evalTitle('Pay the electricity bill').category, 'admin');
    assert.equal(evalTitle('Practice guitar').category, 'creative');
    assert.equal(evalTitle('Clean the kitchen').category, 'chores');
    assert.equal(evalTitle('Meditation before bed').category, 'mindfulness');
  });

  test('classifies Persian activities, including ZWNJ and Arabic letters', () => {
    assert.equal(evalTitle('مطالعه الکترونیک ۹۰ دقیقه').category, 'study');
    assert.equal(evalTitle('پیاده‌روی در پارک').category, 'fitness');
    assert.equal(evalTitle('خواندن ده صفحه کتاب').category, 'reading');
    assert.equal(evalTitle('تماس با مادر').category, 'social');
    assert.equal(evalTitle('تمرين گيتار').category, 'creative');
  });

  test('unknown text falls back to other with low confidence', () => {
    const p = evalTitle('zzqx');
    assert.equal(p.category, 'other');
    assert.ok(p.confidence < 0.5);
    assert.equal(p.source, 'heuristic');
  });

  test('an explicit category always wins', () => {
    const p = evaluateHeuristic({ title: 'Read 10 pages', categoryHint: 'study' });
    assert.equal(p.category, 'study');
  });

  test('extracts durations in both languages', () => {
    const m = (s: string) => extractMinutes(normaliseText(s));
    assert.equal(m('Study 90m'), 90);
    assert.equal(m('run 1.5 hours'), 90);
    assert.equal(m('1h 30m deep work'), 90);
    assert.equal(m('۲ ساعت مطالعه'), 120);
    assert.equal(m('۴۵ دقیقه ورزش'), 45);
    assert.equal(m('half an hour of reading'), 30);
    assert.equal(m('نیم ساعت کتاب'), 30);
    assert.equal(m('make tea'), null);
  });

  test('uses extracted minutes for estimate and difficulty', () => {
    const p = evalTitle('Study electronics for 90 minutes');
    assert.equal(p.estimatedMinutes, 90);
    assert.equal(p.difficulty, 3);
    assert.equal(p.similarityKey, 'study.electronics');
  });

  test('contracts and high-stakes words raise difficulty', () => {
    assert.equal(evalTitle('Study 30m').difficulty, 2);
    assert.equal(evalTitle('Study 30m', 'contract').difficulty, 3);
    assert.equal(evalTitle('Study for the final exam 30m').difficulty, 3);
  });

  test('very short tasks are trivial', () => {
    assert.equal(evalTitle('drink water 2 min').trivial, true);
  });

  test('attributes follow the category defaults in declaration order', () => {
    const p = evalTitle('Go to the gym');
    assert.deepStrictEqual(
      p.attributes.map((a) => [a.attribute, a.weight]),
      [['strength', 0.7], ['vitality', 0.3]],
    );
  });
});
