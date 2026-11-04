import 'model.dart';

/// Deterministic facts about one completion (progression rules §4).
class CompletionFacts {
  const CompletionFacts({
    required this.tier,
    required this.createdAt,
    required this.completedAt,
    this.declaredMinutes,
    this.trackedMinutes,
    this.dueAt,
    this.isRecurringOccurrence = false,
    this.hasImplementationIntention = false,
  });

  final QuestTier tier;
  final DateTime createdAt;
  final DateTime completedAt;
  final int? declaredMinutes;
  final int? trackedMinutes;
  final DateTime? dueAt;
  final bool isRecurringOccurrence;
  final bool hasImplementationIntention;

  factory CompletionFacts.fromJson(Map<String, Object?> json) {
    DateTime? date(Object? v) => v is String ? DateTime.parse(v) : null;
    int? integer(Object? v) => v is num ? v.round() : null;
    return CompletionFacts(
      tier: QuestTier.parse(json['tier']),
      createdAt: date(json['createdAt'])!,
      completedAt: date(json['completedAt'])!,
      declaredMinutes: integer(json['declaredMinutes']),
      trackedMinutes: integer(json['trackedMinutes']),
      dueAt: date(json['dueAt']),
      isRecurringOccurrence: json['isRecurringOccurrence'] == true,
      hasImplementationIntention: json['hasImplementationIntention'] == true,
    );
  }

  Map<String, Object?> toJson() => {
    'tier': tier.name,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'completedAt': completedAt.toUtc().toIso8601String(),
    'declaredMinutes': declaredMinutes,
    'trackedMinutes': trackedMinutes,
    'dueAt': dueAt?.toUtc().toIso8601String(),
    'isRecurringOccurrence': isRecurringOccurrence,
    'hasImplementationIntention': hasImplementationIntention,
  };
}

/// What has already been credited during the user's current local day.
class DayState {
  const DayState({
    this.rawXp = const {},
    this.creditedMinutes = 0,
    this.similarityCounts = const {},
    this.trivialCount = 0,
  });

  static const empty = DayState();

  /// Pre-cap XP already granted per attribute today.
  final Map<Attribute, int> rawXp;
  final int creditedMinutes;
  final Map<String, int> similarityCounts;
  final int trivialCount;

  factory DayState.fromJson(Map<String, Object?> json) {
    final raw = <Attribute, int>{};
    final rawJson = json['rawXp'];
    if (rawJson is Map) {
      rawJson.forEach((k, v) {
        final a = Attribute.tryParse(k);
        if (a != null && v is num) raw[a] = v.round();
      });
    }
    final sim = <String, int>{};
    final simJson = json['similarityCounts'];
    if (simJson is Map) {
      simJson.forEach((k, v) {
        if (k is String && v is num) sim[k] = v.round();
      });
    }
    final minutes = json['creditedMinutes'];
    final trivial = json['trivialCount'];
    return DayState(
      rawXp: raw,
      creditedMinutes: minutes is num ? minutes.round() : 0,
      similarityCounts: sim,
      trivialCount: trivial is num ? trivial.round() : 0,
    );
  }

  Map<String, Object?> toJson() => {
    'rawXp': {for (final e in rawXp.entries) e.key.name: e.value},
    'creditedMinutes': creditedMinutes,
    'similarityCounts': similarityCounts,
    'trivialCount': trivialCount,
  };
}
