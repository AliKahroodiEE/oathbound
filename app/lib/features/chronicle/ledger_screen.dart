import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../design/components/states.dart';
import '../../design/tokens.dart';
import '../../l10n/content.dart';
import '../rewards/reward_view.dart';

/// Every reward with its reasons — the auditable ledger (FR-2).
class LedgerScreen extends ConsumerWidget {
  const LedgerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final f = ref.fmt(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.ledgerTitle)),
      body: ref.watch(rewardsProvider).when(
        loading: () => const LoadingPanels(),
        error: (_, _) => ErrorState(message: l10n.errorGeneric),
        data: (records) => records.isEmpty
            ? Center(child: EmptyState(message: l10n.ledgerEmpty, icon: Icons.receipt_long_outlined))
            : Align(
                alignment: AlignmentDirectional.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: ListView.separated(
                    padding: const EdgeInsetsDirectional.all(AppSpace.lg),
                    itemCount: records.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (_, i) {
                      final r = records[i];
                      return ExpansionTile(
                        tilePadding: EdgeInsetsDirectional.zero,
                        shape: const Border(),
                        collapsedShape: const Border(),
                        childrenPadding: const EdgeInsetsDirectional.only(bottom: AppSpace.lg),
                        title: Text(
                          r.questTitle,
                          style: text.bodyLarge?.copyWith(
                            decoration: r.undone ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        subtitle: Text(
                          [
                            l10n.tierName(r.questTier),
                            f.date(r.createdAt),
                            if (r.undone) l10n.completionUndone,
                          ].join(' · '),
                          style: text.bodySmall,
                        ),
                        trailing: Text(
                          l10n.rewardTotal(f.number(r.undone ? 0 : r.result.totalXp)),
                          style: text.labelLarge?.copyWith(color: AppColors.ember),
                        ),
                        children: [
                          RewardExplanation(result: r.result, proposal: r.proposal, provisional: r.provisional),
                        ],
                      );
                    },
                  ),
                ),
              ),
      ),
    );
  }
}
