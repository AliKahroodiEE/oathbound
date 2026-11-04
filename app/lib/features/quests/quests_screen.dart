import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:go_router/go_router.dart';
import 'package:wyrd_engine/wyrd_engine.dart';

import '../../app/providers.dart';
import '../../core/format/bidi.dart';
import '../../data/models.dart';
import '../../design/components/states.dart';
import '../../design/tokens.dart';
import 'quest_tile.dart';

/// Quests: Today · Upcoming · Contracts · Objectives · Completed.
class QuestsScreen extends ConsumerWidget {
  const QuestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(l10n.questsTitle),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: l10n.tabToday),
              Tab(text: l10n.tabUpcoming),
              Tab(text: l10n.tabContracts),
              Tab(text: l10n.tabObjectives),
              Tab(text: l10n.tabCompleted),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _QuestList(
              provider: todayQuestsProvider,
              empty: l10n.questsEmptyToday,
              action: l10n.todayEmptyAction,
              newRoute: '/quest/new',
            ),
            _QuestList(provider: upcomingQuestsProvider, empty: l10n.questsEmptyUpcoming),
            _QuestList(
              provider: questsByTierProvider(QuestTier.contract),
              empty: l10n.questsEmptyContracts,
              action: l10n.newQuest,
              newRoute: '/quest/new?tier=contract',
            ),
            _QuestList(
              provider: questsByTierProvider(QuestTier.objective),
              empty: l10n.questsEmptyObjectives,
              action: l10n.newQuest,
              newRoute: '/quest/new?tier=objective',
            ),
            const _CompletedList(),
          ],
        ),
      ),
    );
  }
}

class _QuestList extends ConsumerWidget {
  const _QuestList({required this.provider, required this.empty, this.action, this.newRoute});

  final ProviderListenable<AsyncValue<List<QuestView>>> provider;
  final String empty;
  final String? action;
  final String? newRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(provider);
    return value.when(
      loading: () => const LoadingPanels(count: 2),
      error: (_, _) => Padding(
        padding: const EdgeInsetsDirectional.all(AppSpace.lg),
        child: ErrorState(message: context.l10n.errorGeneric),
      ),
      data: (list) => list.isEmpty
          ? Center(
              child: EmptyState(
                message: empty,
                actionLabel: action,
                onAction: newRoute == null ? null : () => context.push(newRoute!),
              ),
            )
          : Align(
              alignment: AlignmentDirectional.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: ListView.separated(
                  padding: const EdgeInsetsDirectional.fromSTEB(AppSpace.lg, AppSpace.md, AppSpace.lg, 104),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpace.sm),
                  itemBuilder: (_, i) => QuestTile(view: list[i]),
                ),
              ),
            ),
    );
  }
}

class _CompletedList extends ConsumerWidget {
  const _CompletedList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final f = ref.fmt(context);
    final text = Theme.of(context).textTheme;
    return ref
        .watch(rewardsProvider)
        .when(
          loading: () => const LoadingPanels(count: 2),
          error: (_, _) => ErrorState(message: l10n.errorGeneric),
          data: (records) {
            final done = records.where((r) => !r.undone).toList();
            if (done.isEmpty) return Center(child: EmptyState(message: l10n.questsEmptyCompleted));
            return Align(
              alignment: AlignmentDirectional.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: ListView.separated(
                  padding: const EdgeInsetsDirectional.fromSTEB(AppSpace.lg, AppSpace.md, AppSpace.lg, 96),
                  itemCount: done.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (_, i) {
                    final r = done[i];
                    return ListTile(
                      contentPadding: EdgeInsetsDirectional.zero,
                      leading: const Icon(Icons.verified_outlined, color: AppColors.crimson),
                      title: UserText(r.questTitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text('${f.date(r.createdAt)} · ${f.time(r.createdAt)}'),
                      trailing: Text(
                        l10n.rewardTotal(f.number(r.result.totalXp)),
                        style: text.labelMedium?.copyWith(color: AppColors.ember),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
  }
}
