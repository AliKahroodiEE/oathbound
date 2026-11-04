import 'package:supabase_flutter/supabase_flutter.dart';

/// Server operations used by the sync engine; an interface so the engine
/// can be tested without a network.
abstract class RemoteApi {
  /// Applies outbox changes; returns one result per change
  /// (`{id, status: applied|ignored|rejected, retryable?}`).
  Future<List<Map<String, Object?>>> push(List<Map<String, Object?>> changes);

  /// Rows changed after [cursor]: `{cursor, has_more, changes: {table: [rows]}}`.
  Future<Map<String, Object?>> pull(int cursor);

  /// Authoritative evaluation: `{result, proposal, source}`, or null when
  /// the server could not evaluate yet (retried on the next sync).
  Future<Map<String, Object?>?> evaluate(String completionId, {required bool useAi});
}

class SupabaseRemoteApi implements RemoteApi {
  SupabaseRemoteApi(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Map<String, Object?>>> push(List<Map<String, Object?>> changes) async {
    final res = await _client.rpc<Map<String, dynamic>>('sync_push', params: {'changes': changes});
    return [for (final r in (res['results'] as List? ?? const [])) Map<String, Object?>.from(r as Map)];
  }

  @override
  Future<Map<String, Object?>> pull(int cursor) async {
    final res = await _client.rpc<Map<String, dynamic>>('sync_pull', params: {'cursor': cursor});
    return Map<String, Object?>.from(res);
  }

  @override
  Future<Map<String, Object?>?> evaluate(String completionId, {required bool useAi}) async {
    final res = await _client.functions.invoke(
      'evaluate-completion',
      body: {'completion_id': completionId, 'use_ai': useAi},
    );
    final data = res.data;
    return data is Map ? Map<String, Object?>.from(data) : null;
  }
}
