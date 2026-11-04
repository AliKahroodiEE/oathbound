import 'package:flutter/material.dart' hide Curves;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wyrd_engine/wyrd_engine.dart';

import '../../app/providers.dart';
import '../../core/format/bidi.dart';
import '../../data/models.dart';
import '../../data/repositories/character_repository.dart';
import '../../design/components/game.dart';
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
      backgroundColor: Colors.transparent,
      body: SafeArea(
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
    );
  }
}

class _CharacterLayout extends StatelessWidget {
  const _CharacterLayout({required this.state});
  final CharacterState state;

  @override
  Widget build(BuildContext context) {
    final widthClass = WidthClass.of(MediaQuery.sizeOf(context).width);
    final hero = _Hero(state: state);
    final returning = state.showReturn(dayKey(DateTime.now())) ? const _ReturnCard() : null;
    final attributes = _AttributesPanel(state: state);
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

    final side = widthClass == WidthClass.compact ? AppSpace.lg : AppSpace.xl;
    final padding = EdgeInsetsDirectional.fromSTEB(
      side,
      AppSpace.lg,
      side,
      widthClass == WidthClass.compact ? 96 : AppSpace.lg,
    );

    if (widthClass == WidthClass.compact) {
      return ListView(
        padding: padding,
        children: [
          column([hero, returning, today, attributes, growth, achievements]),
        ],
      );
    }
    if (widthClass == WidthClass.medium) {
      return SingleChildScrollView(
        padding: padding,
        child: Column(
          children: [
            hero,
            gap,
            if (returning != null) ...[returning, gap],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: column([attributes, achievements])),
                gap,
                Expanded(child: column([today, growth])),
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
          Expanded(flex: 6, child: column([hero, attributes])),
          gap,
          Expanded(flex: 5, child: column([returning, today, achievements])),
          gap,
          Expanded(flex: 4, child: column([growth])),
        ],
      ),
    );
  }
}

class _Hero extends ConsumerWidget {
  const _Hero({required this.state});
  final CharacterState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final f = ref.fmt(context);
    final text = Theme.of(context).textTheme;
    final level = state.level;
    final p = state.profile;
    final w = state.weekly;
    final (conditionText, conditionHelp, conditionColor) = switch (state.conditionLabel) {
      ConditionLabel.rested => (l10n.conditionRested, l10n.conditionRestedHelp, context.palette.success),
      ConditionLabel.steady => (l10n.conditionSteady, l10n.conditionSteadyHelp, context.palette.warning),
      ConditionLabel.strained => (l10n.conditionStrained, l10n.conditionStrainedHelp, context.palette.accent),
    };

    return Panel(
      accent: context.palette.accent,
      padding: const EdgeInsetsDirectional.fromSTEB(AppSpace.lg, AppSpace.xl, AppSpace.lg, AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              XpRing(
                fraction: level.fraction,
                size: 108,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [context.palette.glow, context.palette.sunken]),
                  ),
                  child: Center(
                    child: Icon(
                      portraitGlyphs[p.portrait] ?? Icons.castle_outlined,
                      color: context.palette.ink,
                      size: 38,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: UserText(
                            p.characterName.isEmpty ? l10n.appName : p.characterName,
                            style: text.headlineSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.navSettings,
                          visualDensity: VisualDensity.compact,
                          onPressed: () => context.push('/settings'),
                          icon: const Icon(Icons.settings_outlined, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Wrap(
                      spacing: AppSpace.xs + 2,
                      runSpacing: AppSpace.xs + 2,
                      children: [
                        LevelSeal(level: f.number(level.step), caption: l10n.levelLabel),
                        if (p.equippedTitle != null)
                          Pill(
                            l10n.titleName(p.equippedTitle!),
                            color: context.palette.gold,
                            icon: Icons.workspace_premium,
                          ),
                        if (state.characterClass != null)
                          Pill(
                            l10n.className(state.characterClass!),
                            color: context.palette.arcane,
                            icon: Icons.shield_moon,
                          ),
                      ],
                    ),
                    if (state.characterClass == null) ...[
                      const SizedBox(height: AppSpace.xs),
                      Text(l10n.classUnrevealed, style: text.bodySmall),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          XpBar(fraction: level.fraction, semanticsLabel: l10n.characterLevel(f.number(level.step))),
          const SizedBox(height: AppSpace.sm),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: AppSpace.md,
            runSpacing: AppSpace.xs,
            children: [
              Text(l10n.xpProgress(f.number(level.xpIntoStep), f.number(level.xpForNextStep)), style: text.labelLarge),
              Text(l10n.xpToNextLevel(f.number(level.xpRemaining), f.number(level.step + 1)), style: text.bodySmall),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          LayoutBuilder(
            builder: (context, c) {
              final tiles = [
                Tooltip(
                  message: conditionHelp,
                  triggerMode: TooltipTriggerMode.tap,
                  child: StatTile(
                    vertical: true,
                    icon: Icons.favorite_rounded,
                    color: conditionColor,
                    value: '$conditionText · ${f.number(state.condition)}',
                    label: l10n.conditionLabel,
                  ),
                ),
                StatTile(
                  vertical: true,
                  icon: Icons.local_fire_department_rounded,
                  color: context.palette.flame,
                  value: l10n.weeksKept(w.currentStreak, f.number(w.currentStreak)),
                  label: l10n.bestRecord(f.number(w.bestStreak)),
                ),
                StatTile(
                  vertical: true,
                  icon: Icons.link_rounded,
                  color: context.palette.gold,
                  value: l10n.chainDays(state.chain.current, f.number(state.chain.current)),
                  label: l10n.bestRecord(f.number(state.chain.best)),
                ),
              ];
              if (c.maxWidth < 300) {
                return Column(
                  children: [
                    for (final t in tiles)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(bottom: AppSpace.sm),
                        child: t,
                      ),
                  ],
                );
              }
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var k = 0; k < tiles.length; k++) ...[
                      if (k > 0) const SizedBox(width: AppSpace.sm),
                      Expanded(child: tiles[k]),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.weeklyTargetProgress(f.number(w.activeDaysThisWeek), f.number(w.targetThisWeek)),
                  style: text.bodySmall,
                ),
              ),
              for (var i = 0; i < w.targetThisWeek; i++)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 4),
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: i < w.activeDaysThisWeek ? AppGradients.emberDiagonal : null,
                      border: i < w.activeDaysThisWeek ? null : Border.all(color: context.palette.hairline, width: 2),
                    ),
                  ),
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
    Future<void> dismiss() => ref
        .read(settingsRepositoryProvider)
        .updateProfile((p) => p.copyWith(returnAcknowledgedDay: dayKey(DateTime.now())));
    return Panel(
      accent: context.palette.arcane,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.returnTitle, style: text.titleLarge),
          const SizedBox(height: AppSpace.sm),
          Text(l10n.returnBody, style: text.bodyMedium),
          const SizedBox(height: AppSpace.lg),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              GlowButton(
                label: l10n.returnAction,
                icon: Icons.add_rounded,
                onPressed: () async {
                  await dismiss();
                  if (context.mounted) context.push('/quest/new');
                },
              ),
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
    final maxRank = Attribute.values.map((a) => state.rank(a).step).reduce((a, b) => a > b ? a : b);
    final radar = Center(
      child: AttributeRadar(
        size: 236,
        values: {for (final a in Attribute.values) a: state.rank(a).step / maxRank},
        labels: {for (final a in Attribute.values) a: l10n.attributeName(a)},
      ),
    );
    Widget tile(Attribute a) => AttributeTile(
      attribute: a,
      name: l10n.attributeName(a),
      rankLabel: l10n.attributeRank(f.number(state.rank(a).step)),
      fraction: state.rank(a).fraction,
      todayLabel: (state.todayXp[a] ?? 0) > 0 ? l10n.xpToday(f.number(state.todayXp[a]!)) : null,
      onTap: () => showAttributeSheet(context, a),
    );
    return Panel(
      title: l10n.sectionAttributes,
      icon: Icons.hexagon_outlined,
      child: LayoutBuilder(
        builder: (context, c) {
          final cols = c.maxWidth >= 300 ? 2 : 1;
          final w = (c.maxWidth - AppSpace.sm * (cols - 1)) / cols;
          return Column(
            children: [
              radar,
              const SizedBox(height: AppSpace.md),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: [for (final a in Attribute.values) SizedBox(width: w, child: tile(a))],
              ),
            ],
          );
        },
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
        final color = context.palette.attribute(a);
        return Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(AppSpace.xl, 0, AppSpace.xl, AppSpace.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.16), shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: AttributeSigil(a, size: 26),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(child: Text(l10n.attributeName(a), style: text.titleLarge)),
                  Pill(l10n.attributeRank(f.number(rank.step)), color: color),
                ],
              ),
              const SizedBox(height: AppSpace.md),
              Text(l10n.attributeDescription(a), style: text.bodyMedium),
              const SizedBox(height: AppSpace.lg),
              XpBar(fraction: rank.fraction, color: color),
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

class _TodayPanel extends ConsumerWidget {
  const _TodayPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final quests = ref.watch(todayQuestsProvider);
    return Panel(
      title: l10n.sectionToday,
      icon: Icons.wb_twilight_rounded,
      padding: const EdgeInsetsDirectional.fromSTEB(AppSpace.md, AppSpace.lg, AppSpace.md, AppSpace.md),
      trailing: TextButton(onPressed: () => context.go('/quests'), child: Text(l10n.navQuests)),
      child: quests.when(
        loading: () => const Skeleton(height: 48),
        error: (_, _) => ErrorState(message: l10n.errorGeneric),
        data: (list) => list.isEmpty
            ? EmptyState(
                message: l10n.todayEmpty,
                actionLabel: l10n.todayEmptyAction,
                onAction: () => context.push('/quest/new'),
              )
            : Column(
                children: [
                  for (final v in list.take(5))
                    Padding(
                      padding: const EdgeInsetsDirectional.only(bottom: AppSpace.sm),
                      child: QuestTile(view: v),
                    ),
                ],
              ),
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
      icon: Icons.trending_up_rounded,
      trailing: IconButton(
        tooltip: l10n.ledgerTitle,
        visualDensity: VisualDensity.compact,
        icon: Icon(Icons.receipt_long_outlined, size: 20, color: context.palette.accent),
        onPressed: () => context.go('/chronicle/ledger'),
      ),
      child: state.recent.isEmpty
          ? EmptyState(message: l10n.growthEmpty, icon: Icons.trending_up)
          : Column(
              children: [
                for (final r in state.recent)
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsetsDirectional.zero,
                      childrenPadding: const EdgeInsetsDirectional.only(bottom: AppSpace.md),
                      shape: const Border(),
                      collapsedShape: const Border(),
                      title: UserText(
                        r.questTitle,
                        style: text.bodyMedium?.copyWith(
                          color: context.palette.ink,
                          decoration: r.undone ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsetsDirectional.only(top: 4),
                        child: Wrap(
                          spacing: AppSpace.xs,
                          runSpacing: AppSpace.xs,
                          children: [
                            for (final g in r.result.grants)
                              Pill(f.signedNumber(g.amount), color: context.palette.attribute(g.attribute)),
                          ],
                        ),
                      ),
                      trailing: Text(
                        l10n.rewardTotal(f.number(r.result.totalXp)),
                        style: text.labelLarge?.copyWith(color: context.palette.accent),
                      ),
                      children: [RewardExplanation(result: r.result, proposal: r.proposal, provisional: r.provisional)],
                    ),
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
      icon: Icons.military_tech_rounded,
      accent: context.palette.gold,
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
                    child: Container(
                      padding: const EdgeInsetsDirectional.fromSTEB(6, 6, AppSpace.md, 6),
                      decoration: BoxDecoration(
                        color: context.palette.gold.withValues(alpha: 0.08),
                        borderRadius: AppRadius.pillAll,
                        border: Border.all(color: context.palette.gold.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(colors: [context.palette.gold, AppColors.emberGlow]),
                            ),
                            child: Icon(Icons.star_rounded, size: 15, color: context.palette.canvas),
                          ),
                          const SizedBox(width: AppSpace.sm),
                          Text(
                            l10n.achievementName(a.id),
                            style: text.labelMedium?.copyWith(color: context.palette.ink),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
