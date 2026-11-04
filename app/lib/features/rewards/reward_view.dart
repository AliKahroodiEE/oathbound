import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oathbound_engine/oathbound_engine.dart';

import '../../app/providers.dart';
import '../../design/sigils.dart';
import '../../design/tokens.dart';
import '../../l10n/content.dart';

/// Per-attribute grants with reasons, adjustments in plain language and
/// the evaluation source — the "why" behind every reward (FR-2, P3).
class RewardExplanation extends ConsumerWidget {
  const RewardExplanation({
    super.key,
    required this.result,
    required this.proposal,
    required this.provisional,
    this.showAdjustments = true,
  });

  final RewardResult result;
  final EvaluationProposal proposal;
  final bool provisional;
  final bool showAdjustments;

  String _reason(BuildContext context, Attribute a) {
    for (final w in proposal.attributes) {
      if (w.attribute == a && w.reason.trim().isNotEmpty) return w.reason;
    }
    final l10n = context.l10n;
    return l10n.reasonDefault(l10n.attributeName(a), l10n.categoryName(proposal.category));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final f = ref.fmt(context);
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (result.grants.isEmpty)
          Text(l10n.rewardNone, style: text.bodyMedium)
        else
          for (final g in result.grants)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: AppSpace.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: 2),
                    child: AttributeSigil(g.attribute, size: 20),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(l10n.attributeName(g.attribute), style: text.titleSmall)),
                            Text(
                              f.signedNumber(g.amount),
                              style: text.titleSmall?.copyWith(color: AppColors.forAttribute(g.attribute)),
                            ),
                          ],
                        ),
                        Text(_reason(context, g.attribute), style: text.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        if (showAdjustments && result.adjustments.isNotEmpty) ...[
          const Divider(),
          const SizedBox(height: AppSpace.sm),
          for (final a in result.adjustments)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: AppSpace.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsetsDirectional.only(top: 7, end: AppSpace.sm),
                    child: SizedBox.square(dimension: 4, child: ColoredBox(color: AppColors.ashMuted)),
                  ),
                  Expanded(child: Text(l10n.adjustmentText(a, f), style: text.bodySmall)),
                ],
              ),
            ),
        ],
        const SizedBox(height: AppSpace.sm),
        Text(
          [
            l10n.creditedMinutes(f.number(result.effectiveMinutes)),
            result.source == ProposalSource.ai ? l10n.rewardSourceAi : l10n.rewardSourceHeuristic,
          ].join(' · '),
          style: text.bodySmall?.copyWith(color: AppColors.ashFaint),
        ),
        if (provisional) ...[
          const SizedBox(height: AppSpace.xs),
          Text(l10n.rewardProvisional, style: text.bodySmall?.copyWith(color: AppColors.warning)),
        ],
      ],
    );
  }
}
