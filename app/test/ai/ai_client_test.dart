import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wyrd/data/ai/ai_client.dart';
import 'package:wyrd/data/ai/ai_evaluator.dart';
import 'package:wyrd/data/ai/ai_settings_repository.dart';
import 'package:wyrd/data/ai/evaluation_prompt.dart';
import 'package:wyrd/data/db/database.dart';
import 'package:wyrd_engine/wyrd_engine.dart';

const _proposal = {
  'category': 'study',
  'similarityKey': 'study.electronics',
  'difficulty': 3,
  'estimatedMinutes': 90,
  'attributes': [
    {'attribute': 'intelligence', 'weight': 0.8, 'reason': 'Analysing circuits builds knowledge.'},
    {'attribute': 'discipline', 'weight': 0.2, 'reason': 'A long focused session.'},
  ],
  'trivial': false,
  'confidence': 0.9,
  'summary': '90 minutes of electronics study',
};

const _input = AiEvaluationInput(title: 'Study electronics <script>', tier: QuestTier.daily, outputLanguage: 'fa');

void main() {
  test('Anthropic: documented headers, structured output, text parsed', () async {
    late http.Request seen;
    final client = MockClient((req) async {
      seen = req;
      return http.Response(
        jsonEncode({
          'stop_reason': 'end_turn',
          'content': [
            {'type': 'text', 'text': jsonEncode(_proposal)},
          ],
        }),
        200,
      );
    });
    final ai = AiClient(
      const AiProviderConfig(kind: AiProviderKind.anthropic, model: 'claude-opus-5-5'),
      'sk-test',
      httpClient: client,
      isWeb: true,
    );
    final p = await AiEvaluator(ai).evaluate(_input);
    expect(seen.url.toString(), 'https://api.anthropic.com/v1/messages');
    expect(seen.headers['x-api-key'], 'sk-test');
    expect(seen.headers['anthropic-version'], AiClient.anthropicVersion);
    expect(seen.headers['anthropic-dangerous-direct-browser-access'], 'true');
    final body = jsonDecode(seen.body) as Map<String, Object?>;
    expect((body['output_config']! as Map)['format'], isNotNull);
    expect(body['system'], evaluationSystemPrompt);
    expect(body['messages'].toString(), contains(r'<script>'));
    expect(p.category, QuestCategory.study);
    expect(p.source, ProposalSource.ai);
  });

  test('OpenAI-compatible: base URL, bearer key, JSON mode, retry without it on 400', () async {
    final bodies = <Map<String, Object?>>[];
    late Uri url;
    late Map<String, String> headers;
    final client = MockClient((req) async {
      url = req.url;
      headers = req.headers;
      final body = jsonDecode(req.body) as Map<String, Object?>;
      bodies.add(body);
      if (body.containsKey('response_format')) return http.Response('{"error":"unsupported"}', 400);
      return http.Response(
        jsonEncode({
          'choices': [
            {
              'finish_reason': 'stop',
              'message': {'content': 'Here you go:\n```json\n${jsonEncode(_proposal)}\n```'},
            },
          ],
        }),
        200,
      );
    });
    final ai = AiClient(
      const AiProviderConfig(
        kind: AiProviderKind.openaiCompatible,
        model: 'meta-llama/llama-4',
        baseUrl: 'https://openrouter.ai/api/v1/',
      ),
      'or-key',
      httpClient: client,
      isWeb: false,
    );
    final p = await AiEvaluator(ai).evaluate(_input);
    expect(url.toString(), 'https://openrouter.ai/api/v1/chat/completions');
    expect(headers['authorization'], 'Bearer or-key');
    expect(bodies, hasLength(2));
    expect(bodies.first['response_format'], {'type': 'json_object'});
    expect(bodies.last.containsKey('response_format'), isFalse);
    expect(((bodies.last['messages']! as List).first as Map)['content'], contains(AiEvaluator.jsonInstruction.trim()));
    expect(p.similarityKey, 'study.electronics');
  });

  test('Gemini: generateContent URL, key header, JSON mode, thoughts skipped', () async {
    late http.Request seen;
    final client = MockClient((req) async {
      seen = req;
      return http.Response.bytes(
        utf8.encode(
          jsonEncode({
            'candidates': [
              {
                'finishReason': 'STOP',
                'content': {
                  'parts': [
                    {'text': 'thinking…', 'thought': true},
                    {'text': jsonEncode(_proposal)},
                  ],
                },
              },
            ],
          }),
        ),
        200,
      );
    });
    final ai = AiClient(
      const AiProviderConfig(kind: AiProviderKind.gemini, model: 'models/gemini-pro'),
      'g-key',
      httpClient: client,
    );
    final p = await AiEvaluator(ai).evaluate(_input);
    expect(seen.url.toString(), 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent');
    expect(seen.headers['x-goog-api-key'], 'g-key');
    expect(seen.url.queryParameters, isEmpty, reason: 'the key never goes in the URL');
    final body = jsonDecode(seen.body) as Map<String, Object?>;
    expect((body['generationConfig']! as Map)['responseMimeType'], 'application/json');
    expect(((body['systemInstruction']! as Map)['parts'] as List).first.toString(), contains('JSON object'));
    expect(p.estimatedMinutes, 90);
  });

  test('Gemini safety blocks are reported as refusals', () async {
    final ai = AiClient(
      const AiProviderConfig(kind: AiProviderKind.gemini, model: 'gemini-pro'),
      'k',
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'candidates': [
              {'finishReason': 'SAFETY'},
            ],
          }),
          200,
        ),
      ),
    );
    expect(
      () => ai.complete(system: 's', user: 'u'),
      throwsA(isA<AiException>().having((e) => e.kind, 'kind', AiErrorKind.refused)),
    );
  });

  test('errors map to clear kinds', () async {
    Future<AiErrorKind> kindFor(http.Response r) async {
      final ai = AiClient(
        const AiProviderConfig(kind: AiProviderKind.openai, model: 'm'),
        'k',
        httpClient: MockClient((_) async => r),
      );
      try {
        await ai.complete(system: 's', user: 'u');
        return AiErrorKind.http;
      } on AiException catch (e) {
        return e.kind;
      }
    }

    expect(await kindFor(http.Response('', 401)), AiErrorKind.auth);
    expect(await kindFor(http.Response('', 429)), AiErrorKind.rateLimited);
    expect(
      await kindFor(
        http.Response(
          jsonEncode({
            'choices': [
              {
                'finish_reason': 'stop',
                'message': {'content': null, 'refusal': 'no'},
              },
            ],
          }),
          200,
        ),
      ),
      AiErrorKind.refused,
    );
  });

  test('parser rejects incomplete or invalid proposals', () {
    expect(AiEvaluator.parseProposal('no json here'), isNull);
    expect(AiEvaluator.parseProposal(jsonEncode({..._proposal}..remove('summary'))), isNull);
    expect(AiEvaluator.parseProposal(jsonEncode({..._proposal, 'category': 'hacking'})), isNull);
    expect(AiEvaluator.parseProposal(jsonEncode({..._proposal, 'difficulty': 9})), isNull);
    expect(AiEvaluator.toServerJson(AiEvaluator.parseProposal(jsonEncode(_proposal))!).containsKey('source'), isFalse);
  });

  test('the app prompt matches the server prompt byte for byte', () {
    final ts = File('../backend/supabase/functions/_shared/ai/evaluation.ts').readAsStringSync();
    final server = RegExp(r'export const EVALUATION_SYSTEM_PROMPT = `(.*?)`;', dotAll: true).firstMatch(ts)!.group(1);
    expect(evaluationSystemPrompt, server);
  });

  test('settings keep the key in the key store and build a client', () async {
    final db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    addTearDown(db.close);
    final keys = MemoryKeyStore();
    final repo = AiSettingsRepository(db, keys);
    expect(await repo.client(), isNull);
    await repo.save(
      const AiProviderConfig(kind: AiProviderKind.anthropic, model: 'claude-opus-5-5'),
      apiKey: ' sk ',
    );
    expect(keys.value, 'sk');
    expect((await repo.config())!.model, 'claude-opus-5-5');
    expect(await repo.client(), isNotNull);
    final stored = await db.select(db.keyValues).get();
    expect(stored.any((r) => r.value.contains('sk')), isFalse, reason: 'key never stored in the database');
    await repo.clear();
    expect(await repo.hasKey(), isFalse);
  });
}
