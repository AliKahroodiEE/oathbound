import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// AI services a user can connect with their own key.
enum AiProviderKind {
  anthropic,
  openai,
  gemini,
  anthropicCompatible,
  openaiCompatible;

  bool get anthropicProtocol => this == anthropic || this == anthropicCompatible;
  bool get geminiProtocol => this == gemini;
  bool get customEndpoint => this == anthropicCompatible || this == openaiCompatible;

  String get defaultBaseUrl => switch (this) {
    anthropic => 'https://api.anthropic.com',
    openai => 'https://api.openai.com/v1',
    gemini => 'https://generativelanguage.googleapis.com/v1beta',
    _ => '',
  };

  static AiProviderKind? parse(Object? v) => AiProviderKind.values.asNameMap()[v];
}

/// Non-secret provider settings. The API key is stored separately in the
/// platform's secure storage and never synced.
@immutable
class AiProviderConfig {
  const AiProviderConfig({required this.kind, required this.model, this.baseUrl = ''});

  final AiProviderKind kind;
  final String model;

  /// Only used for compatible endpoints; official providers use theirs.
  final String baseUrl;

  String get effectiveBaseUrl {
    final url = (kind.customEndpoint ? baseUrl : kind.defaultBaseUrl).trim();
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  bool get isComplete => model.trim().isNotEmpty && effectiveBaseUrl.startsWith(RegExp('https?://'));

  Map<String, Object> toJson() => {'kind': kind.name, 'model': model, 'baseUrl': baseUrl};

  static AiProviderConfig? fromJson(Map<String, Object?> j) {
    final kind = AiProviderKind.parse(j['kind']);
    final model = j['model'];
    if (kind == null || model is! String) return null;
    return AiProviderConfig(kind: kind, model: model, baseUrl: j['baseUrl'] is String ? j['baseUrl']! as String : '');
  }
}

enum AiErrorKind { auth, rateLimited, network, refused, badResponse, http }

class AiException implements Exception {
  const AiException(this.kind, [this.status]);
  final AiErrorKind kind;
  final int? status;

  @override
  String toString() => 'AiException(${kind.name}${status == null ? '' : ', $status'})';
}

/// Minimal client for the Anthropic Messages API, the OpenAI Chat
/// Completions API and Google's Gemini API, including services that
/// implement the first two protocols (OpenRouter, Groq, DeepSeek, Together,
/// Ollama, LM Studio, …). Requests are raw HTTP.
class AiClient {
  AiClient(this.config, this._apiKey, {http.Client? httpClient, bool? isWeb})
    : _http = httpClient ?? http.Client(),
      _isWeb = isWeb ?? kIsWeb;

  final AiProviderConfig config;
  final String _apiKey;
  final http.Client _http;
  final bool _isWeb;

  static const anthropicVersion = '2026-10-21';

  /// Returns the model's text reply. When [schema] is given, official
  /// Anthropic requests use structured output and OpenAI-protocol requests
  /// ask for a JSON object; endpoints that reject those options are retried
  /// once without them (the prompt itself also asks for JSON).
  Future<String> complete({
    required String system,
    required String user,
    Map<String, Object?>? schema,
    int maxTokens = 2048,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final structured = schema != null;
    try {
      return await _send(system, user, schema, maxTokens, structured: structured).timeout(timeout);
    } on AiException catch (e) {
      if (structured && e.kind == AiErrorKind.http && e.status == 400) {
        return _send(system, user, schema, maxTokens, structured: false).timeout(timeout);
      }
      rethrow;
    } on TimeoutException {
      throw const AiException(AiErrorKind.network);
    }
  }

  Future<String> _send(
    String system,
    String user,
    Map<String, Object?>? schema,
    int maxTokens, {
    required bool structured,
  }) => config.kind.anthropicProtocol
      ? _anthropic(system, user, schema, maxTokens, structured: structured)
      : config.kind.geminiProtocol
      ? _gemini(system, user, structured: structured)
      : _openai(system, user, maxTokens, structured: structured);

  Future<String> _anthropic(
    String system,
    String user,
    Map<String, Object?>? schema,
    int maxTokens, {
    required bool structured,
  }) async {
    final base = config.effectiveBaseUrl;
    final url = Uri.parse(base.endsWith('/v1') ? '$base/messages' : '$base/v1/messages');
    final body = <String, Object?>{
      'model': config.model.trim(),
      'max_tokens': maxTokens,
      'system': system,
      'messages': [
        {'role': 'user', 'content': user},
      ],
      // Structured output only on Anthropic's own API; compatible services
      // may not support output_config.
      if (structured && schema != null && config.kind == AiProviderKind.anthropic)
        'output_config': {
          'format': {'type': 'json_schema', 'schema': schema},
        },
    };
    final json = await _post(url, {
      'x-api-key': _apiKey,
      'anthropic-version': anthropicVersion,
      // Required for calls made directly from a browser (CORS).
      if (_isWeb) 'anthropic-dangerous-direct-browser-access': 'true',
    }, body);
    if (json['stop_reason'] == 'refusal') throw const AiException(AiErrorKind.refused);
    final content = json['content'];
    if (content is! List) throw const AiException(AiErrorKind.badResponse);
    final text = content
        .whereType<Map<Object?, Object?>>()
        .where((b) => b['type'] == 'text')
        .map((b) => b['text'])
        .whereType<String>()
        .join();
    if (text.trim().isEmpty) throw const AiException(AiErrorKind.badResponse);
    return text;
  }

  Future<String> _openai(String system, String user, int maxTokens, {required bool structured}) async {
    final url = Uri.parse('${config.effectiveBaseUrl}/chat/completions');
    final body = <String, Object?>{
      'model': config.model.trim(),
      'messages': [
        {'role': 'system', 'content': system},
        {'role': 'user', 'content': user},
      ],
      if (structured) 'response_format': {'type': 'json_object'},
    };
    final json = await _post(url, {'authorization': 'Bearer $_apiKey'}, body);
    final choices = json['choices'];
    if (choices is! List || choices.isEmpty || choices.first is! Map) {
      throw const AiException(AiErrorKind.badResponse);
    }
    final choice = choices.first as Map;
    final message = choice['message'];
    if (choice['finish_reason'] == 'content_filter' || (message is Map && message['refusal'] != null)) {
      throw const AiException(AiErrorKind.refused);
    }
    final text = message is Map ? message['content'] : null;
    if (text is! String || text.trim().isEmpty) throw const AiException(AiErrorKind.badResponse);
    return text;
  }

  /// Google Gemini `generateContent`. JSON mode via `responseMimeType`;
  /// no output-token cap, because thinking models count their reasoning
  /// against it and could cut the answer short.
  Future<String> _gemini(String system, String user, {required bool structured}) async {
    final model = config.model.trim().replaceFirst(RegExp(r'^models/'), '');
    final url = Uri.parse('${config.effectiveBaseUrl}/models/${Uri.encodeComponent(model)}:generateContent');
    final body = <String, Object?>{
      'systemInstruction': {
        'parts': [
          {'text': system},
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': user},
          ],
        },
      ],
      if (structured) 'generationConfig': {'responseMimeType': 'application/json'},
    };
    final json = await _post(url, {'x-goog-api-key': _apiKey}, body);
    final feedback = json['promptFeedback'];
    if (feedback is Map && feedback['blockReason'] != null) throw const AiException(AiErrorKind.refused);
    final candidates = json['candidates'];
    if (candidates is! List || candidates.isEmpty || candidates.first is! Map) {
      throw const AiException(AiErrorKind.badResponse);
    }
    final candidate = candidates.first as Map;
    const blocked = {'SAFETY', 'PROHIBITED_CONTENT', 'BLOCKLIST', 'SPII', 'RECITATION'};
    if (blocked.contains(candidate['finishReason'])) throw const AiException(AiErrorKind.refused);
    final content = candidate['content'];
    final parts = content is Map ? content['parts'] : null;
    if (parts is! List) throw const AiException(AiErrorKind.badResponse);
    final text = parts
        .whereType<Map<Object?, Object?>>()
        .where((p) => p['thought'] != true)
        .map((p) => p['text'])
        .whereType<String>()
        .join();
    if (text.trim().isEmpty) throw const AiException(AiErrorKind.badResponse);
    return text;
  }

  Future<Map<String, Object?>> _post(Uri url, Map<String, String> headers, Map<String, Object?> body) async {
    final http.Response res;
    try {
      res = await _http.post(url, headers: {'content-type': 'application/json', ...headers}, body: jsonEncode(body));
    } on Object {
      // Offline, DNS, TLS or a browser CORS block.
      throw const AiException(AiErrorKind.network);
    }
    if (res.statusCode == 401 || res.statusCode == 403) throw AiException(AiErrorKind.auth, res.statusCode);
    if (res.statusCode == 429) throw AiException(AiErrorKind.rateLimited, res.statusCode);
    if (res.statusCode < 200 || res.statusCode >= 300) throw AiException(AiErrorKind.http, res.statusCode);
    final decoded = jsonDecode(utf8.decode(res.bodyBytes));
    if (decoded is! Map) throw const AiException(AiErrorKind.badResponse);
    return Map<String, Object?>.from(decoded);
  }
}
