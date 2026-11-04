import 'dart:math' as math;

import 'rules.dart' as rules;

/// Position on a progression curve: the current step and the exact XP
/// into and required for the next step. Progress bars use these numbers
/// directly — never an inflated proportion.
class CurveProgress {
  const CurveProgress({
    required this.step,
    required this.xpIntoStep,
    required this.xpForNextStep,
  });

  final int step;
  final int xpIntoStep;
  final int xpForNextStep;

  int get xpRemaining => xpForNextStep - xpIntoStep;
  double get fraction => xpForNextStep == 0 ? 0 : xpIntoStep / xpForNextStep;

  @override
  bool operator ==(Object other) =>
      other is CurveProgress &&
      other.step == step &&
      other.xpIntoStep == xpIntoStep &&
      other.xpForNextStep == xpForNextStep;

  @override
  int get hashCode => Object.hash(step, xpIntoStep, xpForNextStep);

  @override
  String toString() => 'CurveProgress($step, $xpIntoStep/$xpForNextStep)';
}

abstract final class Curves {
  /// XP needed to go from character level [n] to n + 1.
  static int xpToAdvanceLevel(int n) =>
      (rules.levelCurveBase * math.pow(n, rules.levelCurveExponent)).round();

  /// XP needed to go from attribute rank [n] to n + 1.
  static int xpToAdvanceRank(int n) =>
      (rules.rankCurveBase * math.pow(n, rules.rankCurveExponent)).round();

  static CurveProgress level(int totalXp) => _walk(totalXp, xpToAdvanceLevel);

  static CurveProgress rank(int attributeXp) =>
      _walk(attributeXp, xpToAdvanceRank);

  /// Total XP required to reach [level] from zero.
  static int totalXpForLevel(int level) {
    var total = 0;
    for (var n = 1; n < level; n++) {
      total += xpToAdvanceLevel(n);
    }
    return total;
  }

  static CurveProgress _walk(int xp, int Function(int) cost) {
    var step = 1;
    var remaining = math.max(0, xp);
    while (remaining >= cost(step)) {
      remaining -= cost(step);
      step++;
    }
    return CurveProgress(
      step: step,
      xpIntoStep: remaining,
      xpForNextStep: cost(step),
    );
  }
}
