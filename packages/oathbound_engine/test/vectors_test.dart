import 'dart:convert';
import 'dart:io';

import 'package:oathbound_engine/oathbound_engine.dart';
import 'package:test/test.dart';

/// Conformance vectors shared with the TypeScript server engine
/// (ADR-004). Both implementations must reproduce `expected` exactly.
void main() {
  final rewards = jsonDecode(File('test/vectors/reward_cases.json').readAsStringSync()) as Map<String, Object?>;
  final curves = jsonDecode(File('test/vectors/curves.json').readAsStringSync()) as Map<String, Object?>;

  test('vectors match the current rule version', () {
    expect(rewards['ruleVersion'], rulesVersion);
    expect(curves['ruleVersion'], rulesVersion);
  });

  group('reward vectors', () {
    for (final raw in rewards['cases']! as List<Object?>) {
      final c = raw! as Map<String, Object?>;
      test(c['name'], () {
        final result = ProgressionEngine.evaluate(
          proposal: EvaluationProposal.fromJson(c['proposal']! as Map<String, Object?>),
          facts: CompletionFacts.fromJson(c['facts']! as Map<String, Object?>),
          day: DayState.fromJson(c['day']! as Map<String, Object?>),
        );
        expect(jsonDecode(jsonEncode(result.toJson())), c['expected']);
      });
    }
  });

  test('curve vectors', () {
    final levelCosts = (curves['levelCosts']! as List<Object?>).cast<int>();
    final rankCosts = (curves['rankCosts']! as List<Object?>).cast<int>();
    for (var n = 1; n <= levelCosts.length; n++) {
      expect(Curves.xpToAdvanceLevel(n), levelCosts[n - 1]);
      expect(Curves.xpToAdvanceRank(n), rankCosts[n - 1]);
    }
    (curves['levelAt']! as Map<String, Object?>).forEach((xp, level) {
      expect(Curves.level(int.parse(xp)).step, level);
    });
  });
}
