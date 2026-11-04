import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oathbound_engine/oathbound_engine.dart';

import '../../app/providers.dart';
import '../../core/format/bidi.dart';
import '../../data/models.dart';
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
  final outcome = await ref.read(progressionRepositoryProvider).complete(
    quest,
    declaredMinutes: declared,
    trackedMinutes: tracked,
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
    final guess = widget.quest.estimatedMinutes ??
        HeuristicEvaluator.extractMinutes(HeuristicEvaluator.normaliseText(widget.quest.title));
    _minutes = TextEditingController(text: guess?.toString() ?? '');
  }

  @override
  void dispose() {
    _minutes.dispose();
    super.dispose();
  }

  void _submit() {
    final v = int.tryParse(
      HeuristicEvaluator.normaliseText(_minutes.text).replaceAll(RegExp(r'[^0-9]'), ''),
    );
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
              builder: (context, v, _) => Text(
                l10n.rewardTotal(f.number(v.round())),
                style: text.displayLarge?.copyWith(color: AppColors.ember),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            for (final b in banners)
              Container(
                margin: const EdgeInsetsDirectional.only(bottom: AppSpace.sm),
                padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
                decoration: const BoxDecoration(
                  color: AppColors.wine,
                  borderRadius: AppRadius.sharpAll,
                ),
                child: Text(b, style: text.labelLarge),
              ),
            if (banners.isNotEmpty) const SizedBox(height: AppSpace.md),
            RewardExplanation(
              result: outcome.result,
              proposal: outcome.proposal,
              provisional: outcome.provisional,
            ),
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
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.actionDone),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
