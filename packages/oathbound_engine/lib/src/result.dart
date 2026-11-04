import 'facts.dart';
import 'model.dart';

/// XP credited to one attribute.
class Grant {
  const Grant(this.attribute, this.amount, this.rawAmount);

  final Attribute attribute;

  /// XP actually credited after caps.
  final int amount;

  /// XP before daily caps; feeds tomorrow-independent cap accounting.
  final int rawAmount;

  Map<String, Object?> toJson() => {'attribute': attribute.name, 'amount': amount, 'rawAmount': rawAmount};

  factory Grant.fromJson(Map<String, Object?> json) => Grant(
    Attribute.tryParse(json['attribute'])!,
    (json['amount']! as num).round(),
    (json['rawAmount']! as num).round(),
  );

  @override
  bool operator ==(Object other) =>
      other is Grant && other.attribute == attribute && other.amount == amount && other.rawAmount == rawAmount;

  @override
  int get hashCode => Object.hash(attribute, amount, rawAmount);

  @override
  String toString() => 'Grant(${attribute.name}: $amount/$rawAmount)';
}

/// Stable codes for every rule that changed a result. Clients localize
/// them; the server stores them in the ledger.
abstract final class AdjustmentCode {
  static const durationPlausibility = 'duration_plausibility';
  static const tierMinutesCap = 'tier_minutes_cap';
  static const dailyBudget = 'daily_budget';
  static const tierBonus = 'tier_bonus';
  static const trivialFloor = 'trivial_floor';
  static const trivialLimit = 'trivial_limit';
  static const repetition = 'repetition';
  static const lowConfidence = 'low_confidence';
  static const followThrough = 'follow_through';
  static const softCap = 'soft_cap';
  static const hardCap = 'hard_cap';
  static const weightsDefaulted = 'weights_defaulted';
}

class Adjustment {
  const Adjustment(this.code, [this.params = const {}]);

  final String code;
  final Map<String, Object> params;

  Map<String, Object?> toJson() => {'code': code, 'params': params};

  factory Adjustment.fromJson(Map<String, Object?> json) =>
      Adjustment(json['code']! as String, Map<String, Object>.from((json['params'] as Map?) ?? const {}));

  @override
  String toString() => 'Adjustment($code, $params)';
}

/// The engine's validated, capped and explained outcome for a completion.
class RewardResult {
  const RewardResult({
    required this.grants,
    required this.effectiveMinutes,
    required this.trivial,
    required this.similarityKey,
    required this.adjustments,
    required this.ruleVersion,
    required this.source,
  });

  final List<Grant> grants;
  final int effectiveMinutes;
  final bool trivial;
  final String similarityKey;
  final List<Adjustment> adjustments;
  final String ruleVersion;
  final ProposalSource source;

  int get totalXp => grants.fold(0, (sum, g) => sum + g.amount);

  bool hasAdjustment(String code) => adjustments.any((a) => a.code == code);

  int amountFor(Attribute attribute) {
    for (final g in grants) {
      if (g.attribute == attribute) return g.amount;
    }
    return 0;
  }

  /// The day state after this result has been credited.
  DayState applyTo(DayState day) {
    final raw = Map<Attribute, int>.of(day.rawXp);
    for (final g in grants) {
      raw[g.attribute] = (raw[g.attribute] ?? 0) + g.rawAmount;
    }
    final sim = Map<String, int>.of(day.similarityCounts);
    sim[similarityKey] = (sim[similarityKey] ?? 0) + 1;
    return DayState(
      rawXp: raw,
      creditedMinutes: day.creditedMinutes + effectiveMinutes,
      similarityCounts: sim,
      trivialCount: day.trivialCount + (trivial ? 1 : 0),
    );
  }

  Map<String, Object?> toJson() => {
    'grants': [for (final g in grants) g.toJson()],
    'totalXp': totalXp,
    'effectiveMinutes': effectiveMinutes,
    'trivial': trivial,
    'similarityKey': similarityKey,
    'adjustments': [for (final a in adjustments) a.toJson()],
    'ruleVersion': ruleVersion,
    'source': source.name,
  };
}
