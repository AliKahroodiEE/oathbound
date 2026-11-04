import 'model.dart';

/// One attribute an evaluator believes the activity developed.
class AttributeWeight {
  const AttributeWeight(this.attribute, this.weight, [this.reason = '']);

  final Attribute attribute;
  final double weight;

  /// Free-text rationale in the user's AI language; empty for heuristic
  /// proposals (clients render a localized default instead).
  final String reason;

  Map<String, Object?> toJson() => {'attribute': attribute.name, 'weight': weight, 'reason': reason};

  @override
  String toString() => 'AttributeWeight(${attribute.name}, $weight)';
}

/// The evaluator's structured interpretation of a completion
/// (progression rules §3). It is advice, not a grant.
class EvaluationProposal {
  const EvaluationProposal({
    required this.category,
    required this.similarityKey,
    required this.difficulty,
    required this.estimatedMinutes,
    required this.attributes,
    this.trivial = false,
    this.confidence = 1,
    this.summary = '',
    this.source = ProposalSource.heuristic,
  });

  final QuestCategory category;
  final String similarityKey;
  final int difficulty;
  final int estimatedMinutes;
  final List<AttributeWeight> attributes;
  final bool trivial;
  final double confidence;
  final String summary;
  final ProposalSource source;

  /// Parses untrusted JSON (e.g. model output). Throws [FormatException]
  /// when required structure is missing; tolerates out-of-range numbers,
  /// which the engine clamps.
  factory EvaluationProposal.fromJson(Map<String, Object?> json) {
    final rawAttributes = json['attributes'];
    if (rawAttributes is! List) {
      throw const FormatException('attributes must be a list');
    }
    final attributes = <AttributeWeight>[];
    for (final item in rawAttributes) {
      if (item is! Map) continue;
      final attribute = Attribute.tryParse(item['attribute']);
      final weight = item['weight'];
      if (attribute == null || weight is! num || !weight.isFinite) continue;
      final reason = item['reason'];
      attributes.add(AttributeWeight(attribute, weight.toDouble(), reason is String ? reason : ''));
    }
    final difficulty = json['difficulty'];
    final minutes = json['estimatedMinutes'];
    if (difficulty is! num || minutes is! num) {
      throw const FormatException('difficulty and estimatedMinutes required');
    }
    final key = json['similarityKey'];
    final confidence = json['confidence'];
    final summary = json['summary'];
    final category = QuestCategory.parse(json['category']);
    return EvaluationProposal(
      category: category,
      similarityKey: normaliseSimilarityKey(key is String ? key : '', category),
      difficulty: difficulty.round(),
      estimatedMinutes: minutes.round(),
      attributes: attributes,
      trivial: json['trivial'] == true,
      confidence: confidence is num && confidence.isFinite ? confidence.toDouble() : 0.5,
      summary: summary is String ? summary : '',
      source: ProposalSource.parse(json['source']),
    );
  }

  Map<String, Object?> toJson() => {
    'category': category.name,
    'similarityKey': similarityKey,
    'difficulty': difficulty,
    'estimatedMinutes': estimatedMinutes,
    'attributes': [for (final a in attributes) a.toJson()],
    'trivial': trivial,
    'confidence': confidence,
    'summary': summary,
    'source': source.name,
  };
}

/// Lowercases, collapses whitespace/punctuation to `-`, guarantees a
/// `category.` prefix and caps the length at 48 characters.
String normaliseSimilarityKey(String key, QuestCategory category) {
  var k = key.trim().toLowerCase();
  k = k.replaceAll(RegExp(r'[\s_/\\,;:!?"()\[\]{}]+'), '-');
  k = k.replaceAll(RegExp(r'-+'), '-');
  k = k.replaceAll(RegExp(r'^-|-$'), '');
  if (k.isEmpty) k = category.name;
  if (!k.startsWith('${category.name}.') && k != category.name) {
    k = '${category.name}.$k';
  }
  if (k.length > 48) k = k.substring(0, 48);
  return k;
}
