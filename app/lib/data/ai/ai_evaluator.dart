import 'dart:convert';

import 'package:wyrd_engine/wyrd_engine.dart';

import 'ai_client.dart';
import 'evaluation_prompt.dart';

/// Minimised activity data sent to the user's AI provider (rules §8.2):
/// the same fields the server evaluator uses, nothing else.
class AiEvaluationInput {
  const AiEvaluationInput({
    required this.title,
    required this.tier,
    required this.outputLanguage,
    this.notes = '',
    this.categoryHint,
    this.declaredMinutes,
    this.trackedMinutes,
    this.plannedMinutes,
    this.parentObjectiveTitle,
    this.similarCompletionsLast7Days = 0,
  });

  final String title;
  final String notes;
  final QuestTier tier;
  final QuestCategory? categoryHint;
  final int? declaredMinutes;
  final int? trackedMinutes;
  final int? plannedMinutes;
  final String? parentObjectiveTitle;
  final int similarCompletionsLast7Days;
  final String outputLanguage;
}

/// Asks the user's own AI provider for a proposal. The deterministic
/// engine still decides and caps the reward; any failure falls back to the
/// built-in heuristic in the caller.
class AiEvaluator {
  AiEvaluator(this.client);

  final AiClient client;

  static const _languageNames = {'en': 'English', 'fa': 'Persian (Farsi)'};

  /// Extra instruction for providers without schema-enforced output.
  static const jsonInstruction =
      '\n\nReturn only one JSON object with exactly these fields: category, similarityKey, difficulty, '
      'estimatedMinutes, attributes (an array of objects with attribute, weight and reason), trivial, '
      'confidence and summary. Do not add markdown or code fences.';

  static const outputSchema = <String, Object?>{
    'type': 'object',
    'properties': {
      'category': {
        'type': 'string',
        'enum': [
          'study', 'work', 'fitness', 'health', 'creative', 'social', //
          'chores', 'admin', 'mindfulness', 'reading', 'other',
        ],
      },
      'similarityKey': {'type': 'string'},
      'difficulty': {
        'type': 'integer',
        'enum': [1, 2, 3, 4, 5],
      },
      'estimatedMinutes': {'type': 'integer'},
      'attributes': {
        'type': 'array',
        'items': {
          'type': 'object',
          'properties': {
            'attribute': {
              'type': 'string',
              'enum': ['strength', 'intelligence', 'discipline', 'creativity', 'vitality', 'social'],
            },
            'weight': {'type': 'number'},
            'reason': {'type': 'string'},
          },
          'required': ['attribute', 'weight', 'reason'],
          'additionalProperties': false,
        },
      },
      'trivial': {'type': 'boolean'},
      'confidence': {'type': 'number'},
      'summary': {'type': 'string'},
    },
    'required': [
      'category', 'similarityKey', 'difficulty', 'estimatedMinutes', //
      'attributes', 'trivial', 'confidence', 'summary',
    ],
    'additionalProperties': false,
  };

  static String userMessage(AiEvaluationInput i) {
    String clean(String? v, int max) {
      final s = (v ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
      return s.length > max ? s.substring(0, max) : s;
    }

    final lang = i.outputLanguage;
    final payload = {
      'title': clean(i.title, 200),
      'notes': clean(i.notes, 1000),
      'tier': i.tier.name,
      'categoryHint': i.categoryHint?.name,
      'declaredMinutes': i.declaredMinutes,
      'trackedMinutes': i.trackedMinutes,
      'plannedMinutes': i.plannedMinutes,
      'parentObjectiveTitle': i.parentObjectiveTitle == null ? null : clean(i.parentObjectiveTitle, 200),
      'similarCompletionsLast7Days': i.similarCompletionsLast7Days,
      'outputLanguage': '$lang (${_languageNames[lang] ?? lang})',
    };
    // "<" is escaped so user text cannot close the <activity> element.
    final body = const JsonEncoder.withIndent('  ').convert(payload).replaceAll('<', r'<');
    return 'Evaluate this completed activity.\n<activity>\n$body\n</activity>';
  }

  Future<EvaluationProposal> evaluate(AiEvaluationInput input) async {
    final structured = client.config.kind == AiProviderKind.anthropic;
    final text = await client.complete(
      system: structured ? evaluationSystemPrompt : '$evaluationSystemPrompt$jsonInstruction',
      user: userMessage(input),
      schema: outputSchema,
      maxTokens: 1500,
    );
    final proposal = parseProposal(text);
    if (proposal == null) throw const AiException(AiErrorKind.badResponse);
    return proposal;
  }

  /// Extracts and strictly validates a proposal from model text (which may
  /// be wrapped in a code fence or surrounded by prose).
  static EvaluationProposal? parseProposal(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    final Object? decoded;
    try {
      decoded = jsonDecode(text.substring(start, end + 1));
    } on FormatException {
      return null;
    }
    if (decoded is! Map) return null;
    final json = Map<String, Object?>.from(decoded);
    const required = [
      'category', 'similarityKey', 'difficulty', 'estimatedMinutes', //
      'attributes', 'trivial', 'confidence', 'summary',
    ];
    if (!required.every(json.containsKey)) return null;
    if (QuestCategory.values.asNameMap()[json['category']] == null) return null;
    try {
      final p = EvaluationProposal.fromJson({...json, 'source': 'ai'});
      if (p.attributes.isEmpty || p.difficulty < 1 || p.difficulty > 5) return null;
      if (p.estimatedMinutes < 1 || p.estimatedMinutes > 600) return null;
      return p;
    } on FormatException {
      return null;
    }
  }

  /// The proposal as the server expects it (no `source` field).
  static Map<String, Object?> toServerJson(EvaluationProposal p) => Map.of(p.toJson())..remove('source');
}
