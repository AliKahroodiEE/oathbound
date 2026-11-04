import 'dart:math' as math;

import 'facts.dart';
import 'model.dart';
import 'proposal.dart';
import 'result.dart';
import 'rules.dart' as rules;

/// The deterministic progression engine (progression rules §5).
///
/// A pure function of its inputs: the same proposal, facts and day state
/// always produce the same result on every platform.
abstract final class ProgressionEngine {
  static RewardResult evaluate({
    required EvaluationProposal proposal,
    required CompletionFacts facts,
    DayState day = DayState.empty,
  }) {
    final adjustments = <Adjustment>[];

    // §5.1 Normalise the proposal.
    final difficulty = proposal.difficulty.clamp(1, 5);
    final confidence = proposal.confidence.clamp(0.0, 1.0);
    final estimate = proposal.estimatedMinutes.clamp(1, 600);
    var weights = normaliseWeights(proposal.attributes);
    if (weights.isEmpty) {
      weights = proposal.category.defaultWeights;
      adjustments.add(const Adjustment(AdjustmentCode.weightsDefaulted));
    }

    // §5.2 Effective minutes.
    final minutes = _effectiveMinutes(facts, estimate, day, adjustments);

    // §5.3 Base XP.
    final tierFactor = rules.tierMultiplier[facts.tier]!;
    var base = minutes <= 0
        ? 0.0
        : rules.baseXpConstant *
              math.pow(
                minutes / rules.durationReferenceMinutes,
                rules.durationExponent,
              ) *
              rules.difficultyMultiplier[difficulty]! *
              tierFactor;
    if (facts.tier != QuestTier.daily) {
      adjustments.add(
        Adjustment(AdjustmentCode.tierBonus, {
          'tier': facts.tier.name,
          'multiplier': tierFactor,
        }),
      );
    }

    // §5.4 Trivial tasks.
    final trivial =
        proposal.trivial || minutes < rules.trivialMinutesThreshold;
    if (trivial) {
      if (day.trivialCount >= rules.trivialDailyLimit) {
        base = 0;
        adjustments.add(
          const Adjustment(AdjustmentCode.trivialLimit, {
            'limit': rules.trivialDailyLimit,
          }),
        );
      } else if (base > rules.trivialMaxXp) {
        base = rules.trivialMaxXp;
        adjustments.add(
          const Adjustment(AdjustmentCode.trivialFloor, {
            'max': rules.trivialMaxXp,
          }),
        );
      }
    }

    // §5.5 Repetition.
    final key = normaliseSimilarityKey(
      proposal.similarityKey,
      proposal.category,
    );
    final repeats = day.similarityCounts[key] ?? 0;
    final repetition = repetitionMultiplier(repeats);
    if (repeats > 0) {
      adjustments.add(
        Adjustment(AdjustmentCode.repetition, {
          'count': repeats + 1,
          'multiplier': repetition,
        }),
      );
    }

    // §5.6 Confidence.
    var confidenceFactor = 1.0;
    if (proposal.source == ProposalSource.ai &&
        confidence < rules.lowConfidenceThreshold) {
      confidenceFactor = rules.lowConfidenceMultiplier;
      adjustments.add(
        const Adjustment(AdjustmentCode.lowConfidence, {
          'multiplier': rules.lowConfidenceMultiplier,
        }),
      );
    }

    // §5.7 Distribute.
    final adjusted = base * repetition * confidenceFactor;
    final raw = <Attribute, double>{
      for (final e in weights.entries) e.key: adjusted * e.value,
    };

    // §5.8 Follow-through bonus.
    if (!trivial && adjusted > 0 && _followedThrough(facts)) {
      final rate =
          rules.followThroughRate +
          (facts.hasImplementationIntention ? rules.intentionRate : 0);
      final bonus = math.max(adjusted * rate, rules.followThroughMinimum);
      raw[Attribute.discipline] = (raw[Attribute.discipline] ?? 0) + bonus;
      adjustments.add(
        Adjustment(AdjustmentCode.followThrough, {
          'rate': rate,
          'intention': facts.hasImplementationIntention,
        }),
      );
    }

    // §5.9 Daily caps.
    final grants = <Grant>[];
    for (final attribute in Attribute.values) {
      final value = raw[attribute];
      if (value == null) continue;
      final rawAmount = value.round();
      if (rawAmount <= 0) continue;
      final before = day.rawXp[attribute] ?? 0;
      final amount =
          (cappedXp(before + rawAmount) - cappedXp(before.toDouble())).round();
      if (amount < rawAmount) {
        final saturated =
            before + rawAmount >=
            rules.softCapXp + 2 * (rules.hardCapXp - rules.softCapXp);
        adjustments.add(
          Adjustment(
            saturated ? AdjustmentCode.hardCap : AdjustmentCode.softCap,
            {'attribute': attribute.name},
          ),
        );
      }
      if (amount > 0) grants.add(Grant(attribute, amount, rawAmount));
    }

    return RewardResult(
      grants: grants,
      effectiveMinutes: minutes,
      trivial: trivial,
      similarityKey: key,
      adjustments: adjustments,
      ruleVersion: rules.rulesVersion,
      source: proposal.source,
    );
  }

  /// Normalises proposal weights (progression rules §5.1): drop unknown,
  /// duplicates and non-positive weights; scale to sum 1; keep the top
  /// three; drop weights under 0.10 unless nothing would remain; rescale.
  static Map<Attribute, double> normaliseWeights(List<AttributeWeight> input) {
    final best = <Attribute, double>{};
    for (final w in input) {
      if (!w.weight.isFinite || w.weight <= 0) continue;
      final prev = best[w.attribute];
      if (prev == null || w.weight > prev) best[w.attribute] = w.weight;
    }
    if (best.isEmpty) return const {};
    final total = best.values.fold(0.0, (a, b) => a + b);
    final ranked = best.entries.toList()
      ..sort((a, b) {
        final byWeight = b.value.compareTo(a.value);
        return byWeight != 0 ? byWeight : a.key.index.compareTo(b.key.index);
      });
    final top = ranked.take(rules.maxWeightedAttributes).toList();
    var kept = top
        .where((e) => e.value / total >= rules.minAttributeWeight)
        .toList();
    if (kept.isEmpty) kept = [top.first];
    final keptTotal = kept.fold(0.0, (a, e) => a + e.value);
    return {for (final e in kept) e.key: e.value / keptTotal};
  }

  /// Repetition multiplier for a completion with [priorToday] earlier
  /// same-key completions on the same local day.
  static double repetitionMultiplier(int priorToday) =>
      priorToday < rules.repetitionMultipliers.length
      ? rules.repetitionMultipliers[priorToday]
      : rules.repetitionFloor;

  /// Effective XP for [rawToday] raw XP in one attribute on one day.
  static double cappedXp(num rawToday) {
    final soft = rules.softCapXp;
    final over = (rawToday - soft).clamp(0, 2 * (rules.hardCapXp - soft));
    return math.min(rawToday.toDouble(), soft) + 0.5 * over;
  }

  static int _effectiveMinutes(
    CompletionFacts facts,
    int estimate,
    DayState day,
    List<Adjustment> adjustments,
  ) {
    int minutes;
    final tracked = facts.trackedMinutes;
    final declared = facts.declaredMinutes;
    if (tracked != null && tracked >= 1) {
      minutes = tracked;
    } else if (declared != null && declared > 0) {
      final limit = math.max(
        rules.plausibilityFactor * estimate,
        rules.plausibilityFloorMinutes,
      );
      if (declared > limit) {
        minutes = limit;
        adjustments.add(
          Adjustment(AdjustmentCode.durationPlausibility, {
            'declared': declared,
            'credited': limit,
          }),
        );
      } else {
        minutes = declared;
      }
    } else {
      minutes = estimate;
    }

    final cap = rules.tierMinutesCap[facts.tier]!;
    if (minutes > cap) {
      minutes = cap;
      adjustments.add(
        Adjustment(AdjustmentCode.tierMinutesCap, {'cap': cap}),
      );
    }

    final remaining = math.max(
      0,
      rules.dailyMinutesBudget - day.creditedMinutes,
    );
    if (minutes > remaining) {
      minutes = remaining;
      adjustments.add(
        const Adjustment(AdjustmentCode.dailyBudget, {
          'budget': rules.dailyMinutesBudget,
        }),
      );
    }
    return minutes;
  }

  static bool _followedThrough(CompletionFacts facts) {
    final planned =
        facts.isRecurringOccurrence ||
        facts.completedAt.difference(facts.createdAt) >=
            rules.plannedAheadThreshold;
    final due = facts.dueAt;
    final onTime = due == null || !facts.completedAt.isAfter(due);
    return planned && onTime;
  }
}
