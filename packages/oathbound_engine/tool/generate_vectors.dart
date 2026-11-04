// Generates test/vectors/reward_cases.json from the case inputs below.
//
// Run after an intentional rule change (and bump rulesVersion):
//   dart run tool/generate_vectors.dart
// Review the diff: every changed number must be explainable by the change.
import 'dart:convert';
import 'dart:io';

import 'package:oathbound_engine/oathbound_engine.dart';

Map<String, Object?> proposal({
  String category = 'study',
  String key = 'study.electronics',
  int difficulty = 3,
  int minutes = 90,
  List<List<Object>> attributes = const [
    ['intelligence', 0.75],
    ['discipline', 0.25],
  ],
  bool trivial = false,
  double confidence = 0.9,
  String source = 'ai',
}) => {
  'category': category,
  'similarityKey': key,
  'difficulty': difficulty,
  'estimatedMinutes': minutes,
  'attributes': [
    for (final a in attributes) {'attribute': a[0], 'weight': a[1], 'reason': ''},
  ],
  'trivial': trivial,
  'confidence': confidence,
  'summary': '',
  'source': source,
};

Map<String, Object?> facts({
  String tier = 'daily',
  int? declared = 90,
  int? tracked,
  String created = '2026-11-04T08:00:00.000Z',
  String completed = '2026-11-04T19:00:00.000Z',
  String? due,
  bool recurring = false,
  bool intention = false,
}) => {
  'tier': tier,
  'createdAt': created,
  'completedAt': completed,
  'declaredMinutes': declared,
  'trackedMinutes': tracked,
  'dueAt': due,
  'isRecurringOccurrence': recurring,
  'hasImplementationIntention': intention,
};

const unplanned = '2026-11-04T19:00:00.000Z';

final cases = <String, (Map<String, Object?>, Map<String, Object?>, Map<String, Object?>)>{
  'worked_example': (proposal(), facts(), {}),
  'unplanned_no_bonus': (proposal(), facts(created: unplanned), {}),
  'recurring_counts_as_planned': (proposal(), facts(created: unplanned, recurring: true), {}),
  'intention_bonus': (proposal(), facts(intention: true), {}),
  'late_no_bonus': (proposal(), facts(due: '2026-11-04T12:00:00.000Z'), {}),
  'tracked_beats_declared': (proposal(), facts(declared: 300, tracked: 45), {}),
  'implausible_declared': (proposal(minutes: 20), facts(declared: 180), {}),
  'plausibility_floor': (proposal(minutes: 3), facts(declared: 15), {}),
  'estimate_only': (proposal(minutes: 50), facts(declared: null), {}),
  'daily_tier_cap': (proposal(minutes: 600), facts(declared: 600), {}),
  'contract_tier': (proposal(minutes: 300), facts(tier: 'contract', declared: 300), {}),
  'objective_tier': (proposal(minutes: 120, difficulty: 5), facts(tier: 'objective', declared: 120), {}),
  'daily_budget': (proposal(), facts(), {'creditedMinutes': 930}),
  'budget_exhausted': (proposal(), facts(), {'creditedMinutes': 960}),
  'trivial_floor': (proposal(minutes: 2, trivial: true, key: 'other.tea', category: 'other'), facts(declared: 2), {}),
  'trivial_limit': (proposal(minutes: 2, trivial: true, key: 'other.tea', category: 'other'), facts(declared: 2), {'trivialCount': 10}),
  'short_is_trivial': (proposal(minutes: 4), facts(declared: 4), {}),
  'repetition_second': (proposal(), facts(), {'similarityCounts': {'study.electronics': 1}}),
  'repetition_fifth': (proposal(), facts(), {'similarityCounts': {'study.electronics': 4}}),
  'repetition_floor': (proposal(), facts(), {'similarityCounts': {'study.electronics': 9}}),
  'low_confidence_ai': (proposal(confidence: 0.3), facts(), {}),
  'low_confidence_heuristic': (proposal(confidence: 0.3, source: 'heuristic'), facts(), {}),
  'soft_cap': (proposal(attributes: [['intelligence', 1.0]]), facts(created: unplanned), {'rawXp': {'intelligence': 200}}),
  'straddle_soft_cap': (proposal(attributes: [['intelligence', 1.0]]), facts(created: unplanned), {'rawXp': {'intelligence': 180}}),
  'hard_cap': (proposal(attributes: [['intelligence', 1.0]]), facts(created: unplanned), {'rawXp': {'intelligence': 600}}),
  'discipline_cap_with_bonus': (proposal(), facts(), {'rawXp': {'discipline': 395}}),
  'weights_dedupe': (proposal(attributes: [['strength', 0.2], ['strength', 0.6], ['vitality', 0.2]], category: 'fitness', key: 'fitness.run'), facts(declared: 40), {}),
  'weights_top_three': (proposal(attributes: [['strength', 0.3], ['vitality', 0.25], ['discipline', 0.2], ['social', 0.15], ['creativity', 0.1]], category: 'fitness', key: 'fitness.match'), facts(declared: 60), {}),
  'weights_drop_small': (proposal(attributes: [['creativity', 0.95], ['social', 0.05]], category: 'creative', key: 'creative.sketch'), facts(declared: 45), {}),
  'weights_unnormalised': (proposal(attributes: [['social', 3], ['vitality', 1]], category: 'social', key: 'social.dinner'), facts(declared: 120), {}),
  'weights_defaulted': (proposal(attributes: [['strength', -1]], category: 'fitness', key: 'fitness.gym'), facts(declared: 60), {}),
  'difficulty_clamped_high': (proposal(difficulty: 99), facts(), {}),
  'difficulty_clamped_low': (proposal(difficulty: 0), facts(), {}),
  'difficulty_1': (proposal(difficulty: 1, minutes: 15), facts(declared: 15), {}),
  'difficulty_4': (proposal(difficulty: 4, minutes: 60), facts(declared: 60), {}),
  'key_normalised': (proposal(key: '  Study  Electronics!! '), facts(), {}),
  'key_missing_prefix': (proposal(key: 'electronics'), facts(), {}),
};

void main() {
  final out = <Map<String, Object?>>[];
  for (final entry in cases.entries) {
    final (p, f, d) = entry.value;
    final result = ProgressionEngine.evaluate(
      proposal: EvaluationProposal.fromJson(p),
      facts: CompletionFacts.fromJson(f),
      day: DayState.fromJson(d),
    );
    out.add({
      'name': entry.key,
      'proposal': p,
      'facts': f,
      'day': d,
      'expected': result.toJson(),
    });
  }
  final curves = {
    'levelCosts': [for (var n = 1; n <= 50; n++) Curves.xpToAdvanceLevel(n)],
    'rankCosts': [for (var n = 1; n <= 50; n++) Curves.xpToAdvanceRank(n)],
    'levelAt': {
      for (final xp in [0, 99, 100, 382, 383, 5000, 50000, 250000])
        '$xp': Curves.level(xp).step,
    },
  };
  const encoder = JsonEncoder.withIndent('  ');
  File('test/vectors/reward_cases.json').writeAsStringSync(
    '${encoder.convert({'ruleVersion': rulesVersion, 'cases': out})}\n',
  );
  File('test/vectors/curves.json').writeAsStringSync(
    '${encoder.convert({'ruleVersion': rulesVersion, ...curves})}\n',
  );
  stdout.writeln('Wrote ${out.length} reward cases and curve vectors.');
}
