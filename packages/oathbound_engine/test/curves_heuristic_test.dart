import 'package:oathbound_engine/oathbound_engine.dart';
import 'package:test/test.dart';

void main() {
  group('curves', () {
    test('level costs follow 100 × n^1.5', () {
      expect([for (var n = 1; n <= 5; n++) Curves.xpToAdvanceLevel(n)], [100, 283, 520, 800, 1118]);
    });

    test('rank costs follow 40 × n^1.4', () {
      expect([for (var n = 1; n <= 5; n++) Curves.xpToAdvanceRank(n)], [40, 106, 186, 279, 381]);
    });

    test('level walks exact boundaries', () {
      expect(Curves.level(0), const CurveProgress(step: 1, xpIntoStep: 0, xpForNextStep: 100));
      expect(Curves.level(99).step, 1);
      expect(Curves.level(100), const CurveProgress(step: 2, xpIntoStep: 0, xpForNextStep: 283));
      expect(Curves.level(383).step, 3);
      expect(Curves.level(-50).step, 1);
    });

    test('totalXpForLevel is the inverse of level()', () {
      for (var l = 1; l <= 30; l++) {
        final xp = Curves.totalXpForLevel(l);
        expect(Curves.level(xp).step, l);
        if (xp > 0) expect(Curves.level(xp - 1).step, l - 1);
      }
    });

    test('progress fraction is the true proportion', () {
      final p = Curves.level(150);
      expect(p.fraction, closeTo(50 / 283, 1e-9));
      expect(p.xpRemaining, 233);
    });
  });

  group('heuristic evaluator', () {
    EvaluationProposal eval(String title, {QuestTier tier = QuestTier.daily}) =>
        HeuristicEvaluator.evaluate(HeuristicInput(title: title, tier: tier));

    test('classifies English activities', () {
      expect(eval('Study electronics for 90 minutes').category, QuestCategory.study);
      expect(eval('Go to the gym').category, QuestCategory.fitness);
      expect(eval('Read 10 pages').category, QuestCategory.reading);
      expect(eval('Call mom').category, QuestCategory.social);
      expect(eval('Pay the electricity bill').category, QuestCategory.admin);
      expect(eval('Practice guitar').category, QuestCategory.creative);
      expect(eval('Clean the kitchen').category, QuestCategory.chores);
      expect(eval('Meditation before bed').category, QuestCategory.mindfulness);
    });

    test('classifies Persian activities, including ZWNJ and Arabic letters', () {
      expect(eval('مطالعه الکترونیک ۹۰ دقیقه').category, QuestCategory.study);
      expect(eval('پیاده‌روی در پارک').category, QuestCategory.fitness);
      expect(eval('خواندن ده صفحه کتاب').category, QuestCategory.reading);
      expect(eval('تماس با مادر').category, QuestCategory.social);
      expect(eval('تمرين گيتار').category, QuestCategory.creative);
    });

    test('unknown text falls back to other with low confidence', () {
      final p = eval('zzqx');
      expect(p.category, QuestCategory.other);
      expect(p.confidence, lessThan(0.5));
      expect(p.source, ProposalSource.heuristic);
    });

    test('an explicit category always wins', () {
      final p = HeuristicEvaluator.evaluate(
        const HeuristicInput(title: 'Read 10 pages', categoryHint: QuestCategory.study),
      );
      expect(p.category, QuestCategory.study);
    });

    test('extracts durations in both languages', () {
      int? m(String s) => HeuristicEvaluator.extractMinutes(HeuristicEvaluator.normaliseText(s));
      expect(m('Study 90m'), 90);
      expect(m('run 1.5 hours'), 90);
      expect(m('1h 30m deep work'), 90);
      expect(m('۲ ساعت مطالعه'), 120);
      expect(m('۴۵ دقیقه ورزش'), 45);
      expect(m('half an hour of reading'), 30);
      expect(m('نیم ساعت کتاب'), 30);
      expect(m('make tea'), isNull);
    });

    test('uses extracted minutes for estimate and difficulty', () {
      final p = eval('Study electronics for 90 minutes');
      expect(p.estimatedMinutes, 90);
      expect(p.difficulty, 3);
      expect(p.similarityKey, 'study.electronics');
    });

    test('contracts and high-stakes words raise difficulty', () {
      expect(eval('Study 30m').difficulty, 2);
      expect(eval('Study 30m', tier: QuestTier.contract).difficulty, 3);
      expect(eval('Study for the final exam 30m').difficulty, 3);
    });

    test('very short tasks are trivial', () {
      expect(eval('drink water 2 min').trivial, isTrue);
    });
  });
}
