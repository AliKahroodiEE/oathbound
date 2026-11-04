import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:oathbound_engine/oathbound_engine.dart';

import '../../app/providers.dart';
import '../../data/models.dart';
import '../../design/components/seal.dart';
import '../../design/tokens.dart';
import '../../l10n/content.dart';
import 'complete_flow.dart';
import 'quest_timer.dart';

IconData tierIcon(QuestTier t) => switch (t) {
  QuestTier.daily => Icons.radio_button_unchecked,
  QuestTier.contract => Icons.description_outlined,
  QuestTier.objective => Icons.flag_outlined,
};

/// A quest row: completion seal, title, meta line, timer indicator.
class QuestTile extends ConsumerWidget {
  const QuestTile({super.key, required this.view, this.showSeal = true});

  final QuestView view;
  final bool showSeal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = view.quest;
    final l10n = context.l10n;
    final f = ref.fmt(context);
    final text = Theme.of(context).textTheme;
    final done = view.completedToday || q.status == QuestStatus.completed;
    final timerRunning = ref.watch(questTimerProvider.select((t) => t.containsKey(q.id)));

    final meta = <String>[
      if (q.tier != QuestTier.daily) l10n.tierName(q.tier),
      if (q.dueAt != null && !q.isRecurring) f.relativeDay(q.dueAt!, DateTime.now()),
      if (q.isRecurring) _recurrenceLabel(context, q.recurrence),
      if (q.estimatedMinutes != null) l10n.estimateMinutes(f.number(q.estimatedMinutes!)),
      if (q.category != null) l10n.categoryName(q.category!),
      if (view.subtasksTotal > 0)
        l10n.objectiveProgress(f.number(view.subtasksDone), f.number(view.subtasksTotal)),
    ];

    return InkWell(
      onTap: () => context.push('/quest/${q.id}'),
      borderRadius: AppRadius.softAll,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpace.xs),
        child: Row(
          children: [
            if (showSeal && q.tier != QuestTier.objective)
              SealCheckbox(
                checked: done,
                semanticLabel: done ? l10n.completedLabel : l10n.completeQuest,
                onPressed: () async {
                  if (done) {
                    final id = view.todayCompletionId;
                    if (id != null) await confirmUndo(context, ref, id);
                  } else {
                    await completeQuest(context, ref, q);
                  }
                },
              )
            else
              Padding(
                padding: const EdgeInsetsDirectional.all(AppSpace.md),
                child: Icon(tierIcon(q.tier), size: 20, color: AppColors.ashMuted),
              ),
            const SizedBox(width: AppSpace.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    q.title,
                    style: text.bodyLarge?.copyWith(
                      color: done ? AppColors.ashMuted : AppColors.bone,
                      decoration: done && !q.isRecurring ? TextDecoration.lineThrough : null,
                      decorationColor: AppColors.ashFaint,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (meta.isNotEmpty)
                    Text(meta.join(' · '), style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (q.tier == QuestTier.objective && view.subtasksTotal > 0)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(top: AppSpace.xs, end: AppSpace.lg),
                      child: ClipRRect(
                        borderRadius: AppRadius.sharpAll,
                        child: LinearProgressIndicator(
                          value: view.subtasksDone / view.subtasksTotal,
                          minHeight: 3,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (timerRunning)
              Tooltip(
                message: l10n.timerRunning(''),
                child: const Padding(
                  padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpace.sm),
                  child: Icon(Icons.timer_outlined, size: 18, color: AppColors.ember),
                ),
              ),
            if (q.isRecurring)
              const Padding(
                padding: EdgeInsetsDirectional.only(end: AppSpace.sm),
                child: Icon(Icons.repeat, size: 16, color: AppColors.ashFaint),
              ),
          ],
        ),
      ),
    );
  }

  static String _recurrenceLabel(BuildContext context, Recurrence r) {
    final l10n = context.l10n;
    return switch (r) {
      Recurrence.none => l10n.recurrenceNone,
      Recurrence.daily => l10n.recurrenceDaily,
      Recurrence.weekdays => l10n.recurrenceWeekdays,
      Recurrence.weekly => l10n.recurrenceWeekly,
    };
  }
}
