import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wyrd_engine/wyrd_engine.dart';

import '../../app/providers.dart';
import '../../core/format/bidi.dart';
import '../../data/models.dart';
import '../../design/components/game.dart';
import '../../design/components/motion.dart';
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

/// A quest card: completion seal tinted by the quest's attribute, title,
/// meta line and a category badge.
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
    final category =
        q.category ??
        HeuristicEvaluator.evaluate(HeuristicInput(title: q.title, notes: q.notes, tier: q.tier)).category;
    final color = context.palette.category(category);

    final meta = <String>[
      if (q.tier != QuestTier.daily) l10n.tierName(q.tier),
      if (q.dueAt != null && !q.isRecurring) f.relativeDay(q.dueAt!, DateTime.now()),
      if (q.isRecurring) _recurrenceLabel(context, q.recurrence),
      if (q.estimatedMinutes != null) l10n.estimateMinutes(f.number(q.estimatedMinutes!)),
      if (view.subtasksTotal > 0) l10n.objectiveProgress(f.number(view.subtasksDone), f.number(view.subtasksTotal)),
    ];

    final p = context.palette;
    final fill = done
        ? p.sunken.withValues(alpha: p.isDark ? 0.5 : 0.6)
        : (p.isDark ? p.surfaceHigh.withValues(alpha: 0.55) : p.surfaceTop);
    return Pressable(
      child: Material(
        color: fill,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.softAll,
          side: BorderSide(color: done ? p.hairline.withValues(alpha: 0.5) : p.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/quest/${q.id}'),
          child: Stack(
            children: [
              // A ribbon in the quest's colour along the start edge, like a bookmark.
              PositionedDirectional(
                start: 0,
                top: AppSpace.md,
                bottom: AppSpace.md,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: done ? 0.3 : 0.85),
                    borderRadius: const BorderRadiusDirectional.horizontal(end: AppRadius.pill),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(AppSpace.xs, AppSpace.sm, AppSpace.md, AppSpace.sm),
                child: Row(
                  children: [
                    if (showSeal && q.tier != QuestTier.objective)
                      SealCheckbox(
                        checked: done,
                        color: color,
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
                        child: Icon(tierIcon(q.tier), size: 20, color: color),
                      ),
                    const SizedBox(width: AppSpace.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          UserText(
                            q.title,
                            style: text.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: done ? context.palette.inkMuted : context.palette.ink,
                              decoration: done && !q.isRecurring ? TextDecoration.lineThrough : null,
                              decorationColor: context.palette.inkFaint,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (meta.isNotEmpty)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(top: 2),
                              child: Text(
                                meta.join(' · '),
                                style: text.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          if (q.tier == QuestTier.objective && view.subtasksTotal > 0)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(top: AppSpace.sm, end: AppSpace.lg),
                              child: ClipRRect(
                                borderRadius: AppRadius.pillAll,
                                child: LinearProgressIndicator(
                                  value: view.subtasksDone / view.subtasksTotal,
                                  minHeight: 4,
                                  color: color,
                                  backgroundColor: color.withValues(alpha: 0.15),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (timerRunning)
                      Padding(
                        padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.xs),
                        child: Icon(Icons.timer_outlined, size: 18, color: context.palette.accent),
                      ),
                    if (q.isRecurring)
                      Padding(
                        padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.xs),
                        child: Icon(Icons.repeat_rounded, size: 16, color: context.palette.inkFaint),
                      ),
                    const SizedBox(width: AppSpace.xs),
                    Tooltip(
                      message: l10n.categoryName(category),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: done ? 0.08 : 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          categoryIcon(category),
                          size: 18,
                          color: done ? color.withValues(alpha: 0.6) : color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
