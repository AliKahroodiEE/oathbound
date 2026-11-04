import 'dart:convert';

import 'package:oathbound_engine/oathbound_engine.dart';

import 'db/database.dart';

/// `yyyy-MM-dd` key for the user's local calendar day.
String dayKey(DateTime local) =>
    '${local.year.toString().padLeft(4, '0')}-'
    '${local.month.toString().padLeft(2, '0')}-'
    '${local.day.toString().padLeft(2, '0')}';

/// Date-only UTC value for engine day arithmetic.
DateTime parseDayKey(String key) {
  final p = key.split('-').map(int.parse).toList();
  return DateTime.utc(p[0], p[1], p[2]);
}

enum Recurrence { none, daily, weekdays, weekly }

enum ShareLevel {
  full,
  titleOnly,
  completionOnly,
  private;

  static ShareLevel parse(String? v) => ShareLevel.values.asNameMap()[v] ?? ShareLevel.private;
}

enum QuestStatus { active, completed, archived }

class Quest {
  const Quest({
    required this.id,
    required this.tier,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.parentId,
    this.notes = '',
    this.category,
    this.priority = 1,
    this.status = QuestStatus.active,
    this.dueAt,
    this.estimatedMinutes,
    this.recurrence = Recurrence.none,
    this.intention,
    this.shareLevel = ShareLevel.private,
  });

  factory Quest.fromRow(QuestRow r) => Quest(
    id: r.id,
    parentId: r.parentId,
    tier: QuestTier.parse(r.tier),
    title: r.title,
    notes: r.notes,
    category: r.category == null ? null : QuestCategory.parse(r.category),
    priority: r.priority,
    status: QuestStatus.values.asNameMap()[r.status] ?? QuestStatus.active,
    dueAt: r.dueAt,
    estimatedMinutes: r.estimatedMinutes,
    recurrence: Recurrence.values.asNameMap()[r.recurrence] ?? Recurrence.none,
    intention: r.intention,
    shareLevel: ShareLevel.parse(r.shareLevel),
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
  );

  final String id;
  final String? parentId;
  final QuestTier tier;
  final String title;
  final String notes;
  final QuestCategory? category;
  final int priority;
  final QuestStatus status;

  /// Local calendar date the quest is planned for (time ignored).
  final DateTime? dueAt;
  final int? estimatedMinutes;
  final Recurrence recurrence;
  final String? intention;
  final ShareLevel shareLevel;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isRecurring => recurrence != Recurrence.none;
  bool get hasIntention => (intention ?? '').trim().isNotEmpty;

  /// Whether a recurring quest has an occurrence on local [day].
  bool occursOn(DateTime day, int firstWeekday) {
    final anchor = dueAt ?? createdAt;
    final d = DateTime(day.year, day.month, day.day);
    final start = DateTime(anchor.year, anchor.month, anchor.day);
    if (d.isBefore(start) && recurrence != Recurrence.none) return false;
    return switch (recurrence) {
      Recurrence.none => true,
      Recurrence.daily => true,
      Recurrence.weekdays => ((d.weekday - firstWeekday) % 7) < 5,
      Recurrence.weekly => d.weekday == anchor.weekday,
    };
  }

  /// End of the planned day, used as the engine's due instant.
  DateTime? get dueInstant => dueAt == null ? null : DateTime(dueAt!.year, dueAt!.month, dueAt!.day, 23, 59, 59);

  Map<String, Object?> toSyncJson() => {
    'id': id,
    'parent_id': parentId,
    'tier': tier.name,
    'title': title,
    'notes': notes,
    'category': category?.name,
    'priority': priority,
    'status': status.name,
    'due_at': dueAt?.toUtc().toIso8601String(),
    'estimated_minutes': estimatedMinutes,
    'recurrence': recurrence.name,
    'intention': intention,
    'share_level': shareLevel.name,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };
}

/// Editable fields for creating or updating a quest.
class QuestDraft {
  const QuestDraft({
    required this.title,
    this.tier = QuestTier.daily,
    this.notes = '',
    this.category,
    this.priority = 1,
    this.dueAt,
    this.estimatedMinutes,
    this.recurrence = Recurrence.none,
    this.intention,
    this.shareLevel = ShareLevel.private,
    this.parentId,
  });

  factory QuestDraft.fromQuest(Quest q) => QuestDraft(
    title: q.title,
    tier: q.tier,
    notes: q.notes,
    category: q.category,
    priority: q.priority,
    dueAt: q.dueAt,
    estimatedMinutes: q.estimatedMinutes,
    recurrence: q.recurrence,
    intention: q.intention,
    shareLevel: q.shareLevel,
    parentId: q.parentId,
  );

  final String title;
  final QuestTier tier;
  final String notes;
  final QuestCategory? category;
  final int priority;
  final DateTime? dueAt;
  final int? estimatedMinutes;
  final Recurrence recurrence;
  final String? intention;
  final ShareLevel shareLevel;
  final String? parentId;
}

/// A quest as shown in a list, with today's completion state.
class QuestView {
  const QuestView({
    required this.quest,
    this.completedToday = false,
    this.todayCompletionId,
    this.subtasksDone = 0,
    this.subtasksTotal = 0,
  });

  final Quest quest;
  final bool completedToday;
  final String? todayCompletionId;
  final int subtasksDone;
  final int subtasksTotal;
}

/// One recorded reward, for "Recent growth" and the ledger.
class RewardRecord {
  const RewardRecord({
    required this.completionId,
    required this.questTitle,
    required this.questTier,
    required this.result,
    required this.proposal,
    required this.provisional,
    required this.createdAt,
    required this.undone,
  });

  factory RewardRecord.fromRows({
    required EvaluationRow evaluation,
    required String questTitle,
    required QuestTier questTier,
    required bool undone,
  }) => RewardRecord(
    completionId: evaluation.completionId,
    questTitle: questTitle,
    questTier: questTier,
    result: decodeResult(evaluation.resultJson),
    proposal: EvaluationProposal.fromJson(jsonDecode(evaluation.proposalJson) as Map<String, Object?>),
    provisional: evaluation.provisional,
    createdAt: evaluation.createdAt,
    undone: undone,
  );

  final String completionId;
  final String questTitle;
  final QuestTier questTier;
  final RewardResult result;
  final EvaluationProposal proposal;
  final bool provisional;
  final DateTime createdAt;
  final bool undone;
}

RewardResult decodeResult(String json) {
  final m = jsonDecode(json) as Map<String, Object?>;
  return RewardResult(
    grants: [for (final g in (m['grants']! as List<Object?>)) Grant.fromJson(g! as Map<String, Object?>)],
    effectiveMinutes: (m['effectiveMinutes']! as num).round(),
    trivial: m['trivial'] == true,
    similarityKey: m['similarityKey']! as String,
    adjustments: [
      for (final a in (m['adjustments']! as List<Object?>)) Adjustment.fromJson(a! as Map<String, Object?>),
    ],
    ruleVersion: m['ruleVersion']! as String,
    source: ProposalSource.parse(m['source']),
  );
}
