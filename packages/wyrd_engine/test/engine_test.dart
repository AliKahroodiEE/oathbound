import 'package:wyrd_engine/wyrd_engine.dart';
import 'package:test/test.dart';

final _morning = DateTime.utc(2026, 11, 4, 8);
final _evening = DateTime.utc(2026, 11, 4, 19);

EvaluationProposal _proposal({
  QuestCategory category = QuestCategory.study,
  String key = 'study.electronics',
  int difficulty = 3,
  int minutes = 90,
  List<AttributeWeight>? attributes,
  bool trivial = false,
  double confidence = 0.9,
  ProposalSource source = ProposalSource.ai,
}) => EvaluationProposal(
  category: category,
  similarityKey: key,
  difficulty: difficulty,
  estimatedMinutes: minutes,
  attributes:
      attributes ?? const [AttributeWeight(Attribute.intelligence, 0.75), AttributeWeight(Attribute.discipline, 0.25)],
  trivial: trivial,
  confidence: confidence,
  source: source,
);

CompletionFacts _facts({
  QuestTier tier = QuestTier.daily,
  int? declared = 90,
  int? tracked,
  DateTime? created,
  DateTime? completed,
  DateTime? due,
  bool recurring = false,
  bool intention = false,
}) => CompletionFacts(
  tier: tier,
  createdAt: created ?? _morning,
  completedAt: completed ?? _evening,
  declaredMinutes: declared,
  trackedMinutes: tracked,
  dueAt: due,
  isRecurringOccurrence: recurring,
  hasImplementationIntention: intention,
);

void main() {
  group('worked example (rules §5)', () {
    test('90 minutes of electronics study yields 31 INT + 14 DIS', () {
      final r = ProgressionEngine.evaluate(proposal: _proposal(), facts: _facts());
      expect(r.amountFor(Attribute.intelligence), 31);
      expect(r.amountFor(Attribute.discipline), 14);
      expect(r.totalXp, 45);
      expect(r.effectiveMinutes, 90);
      expect(r.ruleVersion, rulesVersion);
      expect(r.hasAdjustment(AdjustmentCode.followThrough), isTrue);
    });

    test('is deterministic', () {
      final a = ProgressionEngine.evaluate(proposal: _proposal(), facts: _facts());
      final b = ProgressionEngine.evaluate(proposal: _proposal(), facts: _facts());
      expect(a.toJson(), b.toJson());
    });
  });

  group('effective minutes', () {
    test('timer beats declared minutes', () {
      final r = ProgressionEngine.evaluate(proposal: _proposal(), facts: _facts(declared: 200, tracked: 30));
      expect(r.effectiveMinutes, 30);
      expect(r.hasAdjustment(AdjustmentCode.durationPlausibility), isFalse);
    });

    test('implausible declarations are limited to twice the estimate', () {
      final r = ProgressionEngine.evaluate(proposal: _proposal(minutes: 20), facts: _facts(declared: 180));
      expect(r.effectiveMinutes, 40);
      expect(r.hasAdjustment(AdjustmentCode.durationPlausibility), isTrue);
    });

    test('the plausibility limit never drops below 15 minutes', () {
      final r = ProgressionEngine.evaluate(proposal: _proposal(minutes: 3), facts: _facts(declared: 15));
      expect(r.effectiveMinutes, 15);
    });

    test('daily tasks are capped at 240 minutes', () {
      final r = ProgressionEngine.evaluate(proposal: _proposal(minutes: 600), facts: _facts(declared: 600));
      expect(r.effectiveMinutes, 240);
      expect(r.hasAdjustment(AdjustmentCode.tierMinutesCap), isTrue);
    });

    test('the daily budget of 960 minutes is respected', () {
      final r = ProgressionEngine.evaluate(
        proposal: _proposal(),
        facts: _facts(),
        day: const DayState(creditedMinutes: 930),
      );
      expect(r.effectiveMinutes, 30);
      expect(r.hasAdjustment(AdjustmentCode.dailyBudget), isTrue);
    });

    test('an exhausted budget grants nothing', () {
      final r = ProgressionEngine.evaluate(
        proposal: _proposal(),
        facts: _facts(),
        day: const DayState(creditedMinutes: 960),
      );
      expect(r.totalXp, 0);
    });
  });

  group('anti-exploitation', () {
    test('a trivial task grants at most 3 XP and no follow-through', () {
      final r = ProgressionEngine.evaluate(proposal: _proposal(minutes: 2, trivial: true), facts: _facts(declared: 2));
      expect(r.trivial, isTrue);
      expect(r.totalXp, lessThanOrEqualTo(3));
      expect(r.hasAdjustment(AdjustmentCode.followThrough), isFalse);
    });

    test('100 trivial tasks in one day yield at most 30 XP', () {
      var day = DayState.empty;
      var total = 0;
      for (var i = 0; i < 100; i++) {
        final r = ProgressionEngine.evaluate(
          proposal: _proposal(minutes: 1, trivial: true, key: 'other.t$i'),
          facts: _facts(declared: 1),
          day: day,
        );
        total += r.totalXp;
        day = r.applyTo(day);
      }
      expect(total, lessThanOrEqualTo(30));
      expect(day.trivialCount, 100);
    });

    test('repeating the same activity decays within a day', () {
      var day = DayState.empty;
      final totals = <int>[];
      for (var i = 0; i < 6; i++) {
        final r = ProgressionEngine.evaluate(proposal: _proposal(), facts: _facts(), day: day);
        totals.add(r.totalXp);
        day = r.applyTo(day);
      }
      for (var i = 1; i < totals.length; i++) {
        expect(totals[i], lessThan(totals[i - 1]));
      }
      expect(totals.last, lessThanOrEqualTo((totals.first * 0.1).ceil() + 1));
    });

    test('a daily habit is not decayed across days', () {
      final first = ProgressionEngine.evaluate(proposal: _proposal(), facts: _facts());
      final nextDay = ProgressionEngine.evaluate(proposal: _proposal(), facts: _facts(), day: DayState.empty);
      expect(nextDay.totalXp, first.totalXp);
    });

    test('soft cap halves XP above 200 raw per attribute per day', () {
      final r = ProgressionEngine.evaluate(
        proposal: _proposal(attributes: const [AttributeWeight(Attribute.intelligence, 1)]),
        facts: _facts(created: _evening, completed: _evening),
        day: const DayState(rawXp: {Attribute.intelligence: 200}),
      );
      expect(r.amountFor(Attribute.intelligence), 21); // 200 + (241 − 200) × 0.5
      expect(r.hasAdjustment(AdjustmentCode.softCap), isTrue);
    });

    test('hard cap stops an attribute at 400 effective XP per day', () {
      final r = ProgressionEngine.evaluate(
        proposal: _proposal(attributes: const [AttributeWeight(Attribute.intelligence, 1)]),
        facts: _facts(created: _evening, completed: _evening),
        day: const DayState(rawXp: {Attribute.intelligence: 600}),
      );
      expect(r.amountFor(Attribute.intelligence), 0);
      expect(r.hasAdjustment(AdjustmentCode.hardCap), isTrue);
    });

    test('capped XP is monotonic and bounded', () {
      var previous = -1.0;
      for (var x = 0; x <= 1000; x += 7) {
        final v = ProgressionEngine.cappedXp(x);
        expect(v, greaterThanOrEqualTo(previous));
        expect(v, lessThanOrEqualTo(400));
        previous = v;
      }
    });

    test('low-confidence AI proposals are discounted, heuristics are not', () {
      final ai = ProgressionEngine.evaluate(proposal: _proposal(confidence: 0.2), facts: _facts());
      final heuristic = ProgressionEngine.evaluate(
        proposal: _proposal(confidence: 0.2, source: ProposalSource.heuristic),
        facts: _facts(),
      );
      expect(ai.hasAdjustment(AdjustmentCode.lowConfidence), isTrue);
      expect(heuristic.hasAdjustment(AdjustmentCode.lowConfidence), isFalse);
      expect(ai.totalXp, lessThan(heuristic.totalXp));
    });

    test('out-of-range difficulty is clamped', () {
      final hi = ProgressionEngine.evaluate(proposal: _proposal(difficulty: 99), facts: _facts());
      final five = ProgressionEngine.evaluate(proposal: _proposal(difficulty: 5), facts: _facts());
      expect(hi.totalXp, five.totalXp);
    });
  });

  group('attribute weights', () {
    test('duplicates keep the higher weight and weights renormalise', () {
      final w = ProgressionEngine.normaliseWeights(const [
        AttributeWeight(Attribute.strength, 0.2),
        AttributeWeight(Attribute.strength, 0.6),
        AttributeWeight(Attribute.vitality, 0.2),
      ]);
      expect(w[Attribute.strength], closeTo(0.75, 1e-9));
      expect(w[Attribute.vitality], closeTo(0.25, 1e-9));
    });

    test('at most three attributes are kept', () {
      final w = ProgressionEngine.normaliseWeights(const [
        AttributeWeight(Attribute.strength, 0.3),
        AttributeWeight(Attribute.vitality, 0.25),
        AttributeWeight(Attribute.discipline, 0.2),
        AttributeWeight(Attribute.social, 0.15),
        AttributeWeight(Attribute.creativity, 0.1),
      ]);
      expect(w.keys, [Attribute.strength, Attribute.vitality, Attribute.discipline]);
      expect(w.values.fold(0.0, (a, b) => a + b), closeTo(1, 1e-9));
    });

    test('weights below 10 % are dropped', () {
      final w = ProgressionEngine.normaliseWeights(const [
        AttributeWeight(Attribute.creativity, 0.95),
        AttributeWeight(Attribute.social, 0.05),
      ]);
      expect(w.keys, [Attribute.creativity]);
    });

    test('empty or invalid weights fall back to category defaults', () {
      final r = ProgressionEngine.evaluate(
        proposal: _proposal(
          category: QuestCategory.fitness,
          attributes: const [AttributeWeight(Attribute.strength, -1)],
        ),
        facts: _facts(),
      );
      expect(r.hasAdjustment(AdjustmentCode.weightsDefaulted), isTrue);
      expect(r.amountFor(Attribute.strength), greaterThan(0));
      expect(r.amountFor(Attribute.vitality), greaterThan(0));
    });
  });

  group('follow-through bonus', () {
    test('requires planning ahead', () {
      final r = ProgressionEngine.evaluate(
        proposal: _proposal(),
        facts: _facts(created: _evening, completed: _evening),
      );
      expect(r.hasAdjustment(AdjustmentCode.followThrough), isFalse);
      expect(r.amountFor(Attribute.discipline), 10);
    });

    test('recurring occurrences count as planned', () {
      final r = ProgressionEngine.evaluate(
        proposal: _proposal(),
        facts: _facts(created: _evening, completed: _evening, recurring: true),
      );
      expect(r.hasAdjustment(AdjustmentCode.followThrough), isTrue);
    });

    test('late completions get no bonus but are never penalised', () {
      final late = ProgressionEngine.evaluate(
        proposal: _proposal(),
        facts: _facts(due: DateTime.utc(2026, 11, 4, 12)),
      );
      final unplanned = ProgressionEngine.evaluate(
        proposal: _proposal(),
        facts: _facts(created: _evening, completed: _evening),
      );
      expect(late.hasAdjustment(AdjustmentCode.followThrough), isFalse);
      expect(late.totalXp, unplanned.totalXp);
    });

    test('an implementation intention adds 5 %', () {
      final plain = ProgressionEngine.evaluate(proposal: _proposal(), facts: _facts());
      final intended = ProgressionEngine.evaluate(proposal: _proposal(), facts: _facts(intention: true));
      expect(intended.amountFor(Attribute.discipline), greaterThan(plain.amountFor(Attribute.discipline)));
    });
  });

  group('tiers', () {
    test('contracts and objectives earn more for the same effort', () {
      int xp(QuestTier t) => ProgressionEngine.evaluate(
        proposal: _proposal(),
        facts: _facts(tier: t),
      ).totalXp;
      expect(xp(QuestTier.contract), greaterThan(xp(QuestTier.daily)));
      expect(xp(QuestTier.objective), greaterThan(xp(QuestTier.contract)));
    });
  });

  group('DayState', () {
    test('applyTo accumulates raw XP, minutes, keys and trivial count', () {
      final r = ProgressionEngine.evaluate(proposal: _proposal(), facts: _facts());
      final day = r.applyTo(DayState.empty);
      expect(day.creditedMinutes, 90);
      expect(day.similarityCounts['study.electronics'], 1);
      expect(day.rawXp[Attribute.intelligence], 31);
      expect(day.trivialCount, 0);
    });

    test('round-trips through JSON', () {
      const day = DayState(
        rawXp: {Attribute.social: 12},
        creditedMinutes: 40,
        similarityCounts: {'social.call': 2},
        trivialCount: 1,
      );
      final copy = DayState.fromJson(day.toJson());
      expect(copy.toJson(), day.toJson());
    });
  });

  group('proposal parsing', () {
    test('accepts valid model output', () {
      final p = EvaluationProposal.fromJson({
        'category': 'fitness',
        'similarityKey': 'Run Park',
        'difficulty': 3,
        'estimatedMinutes': 40,
        'attributes': [
          {'attribute': 'strength', 'weight': 0.7, 'reason': 'Cardio'},
          {'attribute': 'charisma', 'weight': 0.3},
        ],
        'trivial': false,
        'confidence': 0.8,
        'summary': 'A 40-minute run.',
        'source': 'ai',
      });
      expect(p.category, QuestCategory.fitness);
      expect(p.similarityKey, 'fitness.run-park');
      expect(p.attributes, hasLength(1));
      expect(p.source, ProposalSource.ai);
    });

    test('rejects structurally invalid output', () {
      expect(() => EvaluationProposal.fromJson({'attributes': 'nope'}), throwsFormatException);
      expect(() => EvaluationProposal.fromJson({'attributes': <Object>[]}), throwsFormatException);
    });
  });
}
