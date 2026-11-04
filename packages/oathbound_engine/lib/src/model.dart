/// Core vocabulary shared by every part of the engine.
library;

/// The six permanent character attributes.
enum Attribute {
  strength,
  intelligence,
  discipline,
  creativity,
  vitality,
  social;

  static Attribute? tryParse(Object? value) {
    if (value is! String) return null;
    for (final a in Attribute.values) {
      if (a.name == value) return a;
    }
    return null;
  }
}

/// Activity categories understood by both evaluators.
enum QuestCategory {
  study,
  work,
  fitness,
  health,
  creative,
  social,
  chores,
  admin,
  mindfulness,
  reading,
  other;

  static QuestCategory parse(Object? value) {
    if (value is String) {
      for (final c in QuestCategory.values) {
        if (c.name == value) return c;
      }
    }
    return QuestCategory.other;
  }

  /// Fallback attribute weights (progression rules §8.1).
  Map<Attribute, double> get defaultWeights => switch (this) {
    QuestCategory.study => const {
      Attribute.intelligence: 0.8,
      Attribute.discipline: 0.2,
    },
    QuestCategory.reading => const {
      Attribute.intelligence: 0.8,
      Attribute.creativity: 0.2,
    },
    QuestCategory.work => const {
      Attribute.discipline: 0.6,
      Attribute.intelligence: 0.4,
    },
    QuestCategory.fitness => const {
      Attribute.strength: 0.7,
      Attribute.vitality: 0.3,
    },
    QuestCategory.health => const {
      Attribute.vitality: 0.8,
      Attribute.discipline: 0.2,
    },
    QuestCategory.mindfulness => const {
      Attribute.vitality: 0.6,
      Attribute.discipline: 0.4,
    },
    QuestCategory.creative => const {
      Attribute.creativity: 0.8,
      Attribute.discipline: 0.2,
    },
    QuestCategory.social => const {Attribute.social: 1.0},
    QuestCategory.chores => const {
      Attribute.discipline: 0.7,
      Attribute.vitality: 0.3,
    },
    QuestCategory.admin => const {
      Attribute.discipline: 0.8,
      Attribute.intelligence: 0.2,
    },
    QuestCategory.other => const {Attribute.discipline: 1.0},
  };
}

/// The three quest tiers.
enum QuestTier {
  daily,
  contract,
  objective;

  static QuestTier parse(Object? value) {
    if (value is String) {
      for (final t in QuestTier.values) {
        if (t.name == value) return t;
      }
    }
    return QuestTier.daily;
  }
}

/// Where a proposal came from.
enum ProposalSource {
  ai,
  heuristic;

  static ProposalSource parse(Object? value) =>
      value == 'ai' ? ProposalSource.ai : ProposalSource.heuristic;
}
