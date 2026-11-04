import 'package:flutter/material.dart' hide Curves;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:oathbound_engine/oathbound_engine.dart';

import '../../app/providers.dart';
import '../../data/models.dart';
import '../../data/repositories/character_repository.dart';
import '../../design/components/background.dart';
import '../../design/components/panel.dart';
import '../../design/components/progress.dart';
import '../../design/components/states.dart';
import '../../design/sigils.dart';
import '../../design/tokens.dart';
import '../../l10n/content.dart';
import '../quests/quest_tile.dart';
import '../rewards/reward_view.dart';

/// The home screen: the character sheet (ux-spec §3).
class CharacterScreen extends ConsumerWidget {
  const CharacterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(characterStateProvider);
    return Scaffold(
      body: AppBackground(
        reducedEffects: state.value?.profile.reducedEffects ?? false,
        child: SafeArea(
          child: state.when(
            loading: () => const LoadingPanels(),
            error: (e, _) => Padding(
              padding: const EdgeInsetsDirectional.all(AppSpace.lg),
              child: ErrorState(
                message: context.l10n.errorGeneric,
                retryLabel: context.l10n.actionRetry,
                onRetry: () => ref.invalidate(characterStateProvider),
              ),
            ),
            data: (s) => _CharacterLayout(state: s),
          ),
        ),
      ),
    );
  }
}

class _CharacterLayout extends StatelessWidget {
  const _CharacterLayout({required this.state});
  final CharacterState state;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final widthClass = WidthClass.of(width);
    final header = _Header(state: state);
    final returning = state.showReturn(dayKey(DateTime.now())) ? const _ReturnCard() : null;
    final attributes = _AttributesPanel(state: state);
    final consistency = _ConsistencyPanel(state: state);
    const today = _TodayPanel();
    final growth = _GrowthPanel(state: state);
    final achievements = _AchievementsPanel(state: state);
    const gap = SizedBox(height: AppSpace.lg, width: AppSpace.lg);

    Widget column(List<Widget?> children) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final c in children.whereType<Widget>()) ...[c, gap],
      ],
    );

    final padding = EdgeInsetsDirectional.symmetric(
      horizontal: widthClass == WidthClass.compact ? AppSpace.lg : AppSpace.xl,
      vertical: AppSpace.lg,
    );

    if (widthClass == WidthClass.compact) {
      return ListView(
        padding: padding,
        children: [column([header, returning, today, attributes, consistency, growth, achievements])],
      );
    }
    if (widthClass == WidthClass.medium) {
      return SingleChildScrollView(
        padding: padding,
        child: Column(
          children: [
            header,
            gap,
            if (returning != null) ...[returning, gap],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: column([attributes, consistency])),
                gap,
                Expanded(child: column([today, growth, achievements])),
              ],
            ),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 5, child: column([header, attributes, consistency])),
          gap,
          Expanded(flex: 5, child: column([returning, today, achievements])),
          gap,
          Expanded(flex: 4, child: column([growth])),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.state});
  final CharacterState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final f = ref.fmt(context);
    final text = Theme.of(context).textTheme;
    final level = state.level;
    final p = state.profile;
    final subtitle = [
      if (p.equippedTitle != null) l10n.titleName(p.equippedTitle!),
      if (state.characterClass != null) l10n.className(state.characterClass!),
    ].join(' · ');
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.abyss,
                  border: Border.all(color: AppColors.hairline),
                ),
                child: Icon(portraitGlyphs[p.portrait] ?? Icons.castle_outlined, color: AppColors.bone, size: 30),
              ),
              const SizedBox(width: AppSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.characterName.isEmpty ? l10n.appName : p.characterName,
                      style: text.headlineSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle.isEmpty ? l10n.classUnrevealed : subtitle,
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: l10n.navSettings,
                onPressed: () => context.push('/settings'),
                icon: const Icon(Icons.settings_outlined),
              ),
              LevelSeal(level: f.number(level.step), caption: l10n.levelLabel),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          XpBar(fraction: level.fraction, semanticsLabel: l10n.characterLevel(f.number(level.step))),
          const SizedBox(height: AppSpace.sm),
          Row(
            children: [
              Text(
                l10n.xpProgress(f.number(level.xpIntoStep), f.number(level.xpForNextStep)),
                style: text.labelMedium,
              ),
              const Spacer(),
              Text(
                l10n.xpToNextLevel(f.number(level.xpRemaining), f.number(level.step + 1)),
                style: text.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReturnCard extends ConsumerWidget {
  const _ReturnCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    Future<void> dismiss() => ref.read(settingsRepositoryProvider).updateProfile(
      (p) => p.copyWith(returnAcknowledgedDay: dayKey(DateTime.now())),
    );
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.returnTitle, style: text.titleMedium),
          const SizedBox(height: AppSpace.sm),
          Text(l10n.returnBody, style: text.bodyMedium),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              FilledButton(
                onPressed: () async {
                  await dismiss();
                  if (context.mounted) context.push('/quest/new');
                },
                child: Text(l10n.returnAction),
              ),
              const SizedBox(width: AppSpace.sm),
              TextButton(onPressed: dismiss, child: Text(l10n.actionClose)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttributesPanel extends ConsumerWidget {
  const _AttributesPanel({required this.state});
  final CharacterState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final f = ref.fmt(context);
    return Panel(
      title: l10n.sectionAttributes,
      child: Column(
        children: [
          for (final a in Attribute.values)
            AttributeRow(
              attribute: a,
              name: l10n.attributeName(a),
              rankLabel: l10n.attributeRank(f.number(state.rank(a).step)),
              fraction: state.rank(a).fraction,
              todayLabel: (state.todayXp[a] ?? 0) > 0 ? l10n.xpToday(f.number(state.todayXp[a]!)) : null,
              onTap: () => showAttributeSheet(context, a),
            ),
        ],
      ),
    );
  }
}

/// Attribute detail: what it means, rank progress and lifetime XP.
void showAttributeSheet(BuildContext context, Attribute a) {
  showModalBottomSheet<void>(
    context: context,
    builder: (context) => Consumer(
      builder: (context, ref, _) {
        final l10n = context.l10n;
        final f = ref.fmt(context);
        final text = Theme.of(context).textTheme;
        final s = ref.watch(characterStateProvider).value;
        final rank = s?.rank(a) ?? Curves.rank(0);
        return Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(AppSpace.xl, 0, AppSpace.xl, AppSpace.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  AttributeSigil(a, size: 28),
                  const SizedBox(width: AppSpace.md),
                  Expanded(child: Text(l10n.attributeName(a), style: text.titleLarge)),
                  Text(l10n.attributeRank(f.number(rank.step)), style: text.titleSmall),
                ],
              ),
              const SizedBox(height: AppSpace.md),
              Text(l10n.attributeDescription(a), style: text.bodyMedium),
              const SizedBox(height: AppSpace.lg),
              XpBar(fraction: rank.fraction, color: AppColors.forAttribute(a)),
              const SizedBox(height: AppSpace.sm),
              Text(
                '${l10n.xpProgress(f.number(rank.xpIntoStep), f.number(rank.xpForNextStep))} · '
                '${l10n.totalXp(f.number(s?.attributeXp[a] ?? 0))}',
                style: text.bodySmall,
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _ConsistencyPanel extends ConsumerWidget {
  const _ConsistencyPanel({required this.state});
  final CharacterState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final f = ref.fmt(context);
    final text = Theme.of(context).textTheme;
    final (label, help, color) = switch (state.conditionLabel) {
      ConditionLabel.rested => (l10n.conditionRested, l10n.conditionRestedHelp, AppColors.attrVitality),
      ConditionLabel.steady => (l10n.conditionSteady, l10n.conditionSteadyHelp, AppColors.warning),
      ConditionLabel.strained => (l10n.conditionStrained, l10n.conditionStrainedHelp, AppColors.ember),
    };
    final w = state.weekly;
    return Panel(
      title: l10n.sectionConsistency,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Tooltip(
            message: help,
            triggerMode: TooltipTriggerMode.tap,
            child: Row(
              children: [
                Text(l10n.conditionLabel, style: text.bodyMedium),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: AppSpace.sm),
                Text('$label · ${f.number(state.condition)}', style: text.titleSmall),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            l10n.weeklyTargetProgress(f.number(w.activeDaysThisWeek), f.number(w.targetThisWeek)),
            style: text.bodyMedium,
          ),
          const SizedBox(height: AppSpace.xs),
          XpBar(
            fraction: w.targetThisWeek == 0 ? 0 : w.activeDaysThisWeek / w.targetThisWeek,
            color: AppColors.attrDiscipline,
            height: 4,
          ),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  value: l10n.weeksKept(w.currentStreak, f.number(w.currentStreak)),
                  caption: l10n.bestRecord(f.number(w.bestStreak)),
                ),
              ),
              Expanded(
                child: _Stat(
                  value: l10n.chainDays(state.chain.current, f.number(state.chain.current)),
                  caption: l10n.bestRecord(f.number(state.chain.best)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.caption});
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: text.titleSmall),
        Text(caption, style: text.bodySmall),
      ],
    );
  }
}

class _TodayPanel extends ConsumerWidget {
  const _TodayPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final quests = ref.watch(todayQuestsProvider);
    return Panel(
      title: l10n.sectionToday,
      padding: const EdgeInsetsDirectional.fromSTEB(AppSpace.sm, AppSpace.lg, AppSpace.sm, AppSpace.sm),
      trailing: TextButton(
        onPressed: () => context.go('/quests'),
        child: Text(l10n.navQuests),
      ),
      child: quests.when(
        loading: () => const Skeleton(height: 48),
        error: (_, _) => ErrorState(message: l10n.errorGeneric),
        data: (list) => list.isEmpty
            ? EmptyState(
                message: l10n.todayEmpty,
                actionLabel: l10n.todayEmptyAction,
                onAction: () => context.push('/quest/new'),
              )
            : Column(children: [for (final v in list.take(5)) QuestTile(view: v)]),
      ),
    );
  }
}

class _GrowthPanel extends ConsumerWidget {
  const _GrowthPanel({required this.state});
  final CharacterState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final f = ref.fmt(context);
    final text = Theme.of(context).textTheme;
    return Panel(
      title: l10n.sectionRecentGrowth,
      trailing: TextButton(
        onPressed: () => context.go('/chronicle/ledger'),
        child: Text(l10n.ledgerTitle),
      ),
      child: state.recent.isEmpty
          ? EmptyState(message: l10n.growthEmpty, icon: Icons.trending_up)
          : Column(
              children: [
                for (final r in state.recent)
                  ExpansionTile(
                    tilePadding: EdgeInsetsDirectional.zero,
                    childrenPadding: const EdgeInsetsDirectional.only(bottom: AppSpace.md),
                    shape: const Border(),
                    collapsedShape: const Border(),
                    title: Text(
                      r.questTitle,
                      style: text.bodyMedium?.copyWith(
                        decoration: r.undone ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Wrap(
                      spacing: AppSpace.sm,
                      children: [
                        for (final g in r.result.grants)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AttributeSigil(g.attribute, size: 12),
                              const SizedBox(width: 3),
                              Text(f.signedNumber(g.amount), style: text.bodySmall),
                            ],
                          ),
                      ],
                    ),
                    trailing: Text(
                      l10n.rewardTotal(f.number(r.result.totalXp)),
                      style: text.labelMedium?.copyWith(color: AppColors.ember),
                    ),
                    children: [
                      RewardExplanation(result: r.result, proposal: r.proposal, provisional: r.provisional),
                    ],
                  ),
              ],
            ),
    );
  }
}

class _AchievementsPanel extends ConsumerWidget {
  const _AchievementsPanel({required this.state});
  final CharacterState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final f = ref.fmt(context);
    final text = Theme.of(context).textTheme;
    return Panel(
      title: l10n.sectionAchievements,
      child: state.achievements.isEmpty
          ? EmptyState(message: l10n.achievementsEmpty, icon: Icons.military_tech_outlined)
          : Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: [
                for (final a in state.achievements)
                  Tooltip(
                    message: '${l10n.achievementDescription(a.id)} · ${f.date(a.unlockedAt)}',
                    triggerMode: TooltipTriggerMode.tap,
                    child: Chip(
                      avatar: const Icon(Icons.military_tech_outlined, size: 16, color: AppColors.ember),
                      label: Text(l10n.achievementName(a.id), style: text.labelMedium),
                    ),
                  ),
              ],
            ),
    );
  }
}
