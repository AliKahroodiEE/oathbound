import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wyrd_engine/wyrd_engine.dart';

import '../../app/providers.dart';
import '../../core/format/bidi.dart';
import '../../data/ai/ai_client.dart';
import '../../data/ai/ai_evaluator.dart';
import '../../data/models.dart';
import '../../data/sync/sync_coordinator.dart';
import '../../data/repositories/progression_repository.dart';
import '../../design/components/motion.dart';
import '../../design/tokens.dart';
import '../../l10n/content.dart';
import '../rewards/reward_view.dart';
import 'quest_timer.dart';

/// Completes [quest]: asks for minutes (optional), runs the engine, then
/// reveals the reward. Returns the outcome, or null if cancelled.
Future<CompletionOutcome?> completeQuest(BuildContext context, WidgetRef ref, Quest quest) async {
  final tracked = ref.read(questTimerProvider.notifier).stop(quest.id);
  int? declared;
  if (tracked == null) {
    final input = await showModalBottomSheet<_MinutesInput>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _MinutesSheet(quest: quest),
    );
    if (input == null) return null;
    declared = input.minutes;
  }
  final profile = ref.read(profileProvider).value;
  final regional = ref.read(regionalProvider);
  final aiProposal = (profile?.aiEnabled ?? true) && context.mounted
      ? await _askOwnAi(context, ref, quest, declared: declared, tracked: tracked)
      : null;
  if (!context.mounted) return null;
  final outcome = await ref
      .read(progressionRepositoryProvider)
      .complete(
        quest,
        declaredMinutes: declared,
        trackedMinutes: tracked,
        aiProposal: aiProposal,
        provisional: ref.read(provisionalCompletionsProvider),
        weeklyTarget: profile?.weeklyTarget ?? 4,
        firstWeekday: regional.firstWeekday,
      );
  if (outcome == null || !context.mounted) return outcome;
  HapticFeedback.mediumImpact();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => RewardSheet(outcome: outcome, questTitle: quest.title),
  );
  return outcome;
}

/// Offers to undo today's completion of a quest.
Future<void> confirmUndo(BuildContext context, WidgetRef ref, String completionId) async {
  final l10n = context.l10n;
  final ok = await ref.read(progressionRepositoryProvider).undo(completionId);
  if (!context.mounted || !ok) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.completionUndone)));
}

class _MinutesInput {
  const _MinutesInput(this.minutes);
  final int? minutes;
}

class _MinutesSheet extends StatefulWidget {
  const _MinutesSheet({required this.quest});
  final Quest quest;

  @override
  State<_MinutesSheet> createState() => _MinutesSheetState();
}

class _MinutesSheetState extends State<_MinutesSheet> {
  late final TextEditingController _minutes;

  @override
  void initState() {
    super.initState();
    final guess =
        widget.quest.estimatedMinutes ??
        HeuristicEvaluator.extractMinutes(HeuristicEvaluator.normaliseText(widget.quest.title));
    _minutes = TextEditingController(text: guess?.toString() ?? '');
  }

  @override
  void dispose() {
    _minutes.dispose();
    super.dispose();
  }

  void _submit() {
    final v = int.tryParse(HeuristicEvaluator.normaliseText(_minutes.text).replaceAll(RegExp(r'[^0-9]'), ''));
    Navigator.of(context).pop(_MinutesInput(v != null && v > 0 ? v.clamp(1, 960) : null));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: AppSpace.xl,
        end: AppSpace.xl,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpace.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.completeSheetTitle, style: text.titleLarge),
          const SizedBox(height: AppSpace.xs),
          UserText(widget.quest.title, style: text.bodyMedium),
          const SizedBox(height: AppSpace.xl),
          TextField(
            controller: _minutes,
            autofocus: true,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: l10n.completeSheetMinutes,
              helperText: l10n.completeSheetMinutesHelp,
            ),
          ),
          const SizedBox(height: AppSpace.xl),
          FilledButton(onPressed: _submit, child: Text(l10n.completeSheetConfirm)),
        ],
      ),
    );
  }
}

/// The reward reveal (ux-spec §3, "Completion and reward").
class RewardSheet extends ConsumerWidget {
  const RewardSheet({super.key, required this.outcome, required this.questTitle});

  final CompletionOutcome outcome;
  final String questTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final f = ref.fmt(context);
    final text = Theme.of(context).textTheme;
    final level = outcome.levelAfter;
    final banners = <String>[
      if (outcome.leveledUp) l10n.levelUp(f.number(level.step)),
      for (final e in outcome.rankUps.entries) l10n.rankUp(l10n.attributeName(e.key), f.number(e.value)),
      for (final a in outcome.newAchievements) l10n.achievementUnlocked(l10n.achievementName(a.id)),
      for (final a in outcome.newAchievements)
        if (a.titleId != null) l10n.titleUnlocked(l10n.titleName(a.titleId!)),
    ];
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(AppSpace.xl, 0, AppSpace.xl, AppSpace.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.rewardTitle, style: text.labelSmall),
            const SizedBox(height: AppSpace.xs),
            UserText(questTitle, style: text.titleMedium),
            const SizedBox(height: AppSpace.lg),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: outcome.result.totalXp.toDouble()),
              duration: motion(context, AppMotion.reveal),
              curve: AppMotion.emphasizedDecelerate,
              builder: (context, v, _) => Container(
                padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpace.xl),
                decoration: const BoxDecoration(
                  // A static radial burst behind the number: celebratory, cheap.
                  gradient: RadialGradient(
                    radius: 0.9,
                    colors: [Color(0x55FF5A64), Color(0x228B6CFF), Color(0x00000000)],
                    stops: [0, 0.45, 1],
                  ),
                ),
                alignment: Alignment.center,
                child: ShaderMask(
                  shaderCallback: (r) =>
                      AppGradients.emberDiagonal.createShader(r, textDirection: Directionality.of(context)),
                  child: Text(
                    l10n.rewardTotal(f.number(v.round())),
                    style: text.displayLarge?.copyWith(color: Colors.white, fontSize: 46),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            for (final b in banners)
              Container(
                margin: const EdgeInsetsDirectional.only(bottom: AppSpace.sm),
                padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm + 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      context.palette.gold.withValues(alpha: 0.22),
                      context.palette.arcane.withValues(alpha: 0.12),
                    ],
                  ),
                  borderRadius: AppRadius.softAll,
                  border: Border.all(color: context.palette.gold.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 18, color: context.palette.gold),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(child: Text(b, style: text.labelLarge)),
                  ],
                ),
              ),
            if (banners.isNotEmpty) const SizedBox(height: AppSpace.md),
            RewardExplanation(result: outcome.result, proposal: outcome.proposal, provisional: outcome.provisional),
            const SizedBox(height: AppSpace.xl),
            Row(
              children: [
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await confirmUndo(context, ref, outcome.completionId);
                  },
                  child: Text(l10n.actionUndo),
                ),
                const Spacer(),
                FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.actionDone)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Asks the user's own AI provider (if configured) for a proposal, showing
/// a small progress dialog. Returns null when no provider is set or the
/// call fails; the built-in rules are then used and the user is told.
Future<EvaluationProposal?> _askOwnAi(
  BuildContext context,
  WidgetRef ref,
  Quest quest, {
  required int? declared,
  required int? tracked,
}) async {
  final AiClient? client;
  try {
    client = await ref.read(aiSettingsRepositoryProvider).client();
  } on Object {
    return null; // secure storage unavailable on this platform/session
  }
  if (client == null || !context.mounted) return null;
  final l10n = context.l10n;
  final navigator = Navigator.of(context, rootNavigator: true);
  final messenger = ScaffoldMessenger.of(context);
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: AppSpace.lg),
            Expanded(child: Text(l10n.aiInterpreting)),
          ],
        ),
      ),
    ),
  );
  try {
    final repo = ref.read(questRepositoryProvider);
    final parent = quest.parentId == null ? null : await repo.byId(quest.parentId!);
    final heuristicKey = HeuristicEvaluator.evaluate(HeuristicInput(title: quest.title, tier: quest.tier))
        .similarityKey;
    final similar = await ref
        .read(progressionRepositoryProvider)
        .similarCountSince(heuristicKey, DateTime.now().subtract(const Duration(days: 7)));
    final profile = ref.read(profileProvider).value;
    return await AiEvaluator(client).evaluate(
      AiEvaluationInput(
        title: quest.title,
        notes: quest.notes,
        tier: quest.tier,
        categoryHint: quest.category,
        declaredMinutes: declared,
        trackedMinutes: tracked,
        plannedMinutes: quest.estimatedMinutes,
        parentObjectiveTitle: parent?.title,
        similarCompletionsLast7Days: similar,
        outputLanguage: profile?.aiLocale ?? ref.read(regionalProvider).locale.languageCode,
      ),
    );
  } on Object {
    messenger.showSnackBar(SnackBar(content: Text(l10n.aiFallbackUsed)));
    return null;
  } finally {
    navigator.pop();
  }
}
