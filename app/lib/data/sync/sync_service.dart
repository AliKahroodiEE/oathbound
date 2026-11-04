import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:oathbound_engine/oathbound_engine.dart';

import '../db/database.dart';
import '../models.dart';
import '../remote/remote_api.dart';
import '../repositories/progression_repository.dart';

class SyncReport {
  const SyncReport({this.pushed = 0, this.rejected = 0, this.evaluated = 0, this.pulled = 0});
  final int pushed;
  final int rejected;
  final int evaluated;
  final int pulled;

  @override
  String toString() => 'SyncReport(pushed: $pushed, rejected: $rejected, evaluated: $evaluated, pulled: $pulled)';
}

/// Outbox push, authoritative evaluation and cursor pull (ADR-003).
///
/// Local rows stay the UI's source of truth. Pushes carry a fixed-width
/// hybrid logical clock derived from the mutation time so the server can
/// merge fields last-writer-wins; completions are insert-only; the
/// server's evaluation supersedes the provisional local one.
class SyncService {
  SyncService(this._db, this._api, this._progression);

  final AppDatabase _db;
  final RemoteApi _api;
  final ProgressionRepository _progression;
  static const _cursorKey = 'sync_cursor';
  static const _nodeKey = 'sync_node';
  static const _pendingEvalKey = 'sync_pending_evaluations';

  Future<SyncReport> syncOnce({required bool useAi}) async {
    final push = await _push();
    final evaluated = await _evaluatePending(useAi: useAi);
    final pulled = await _pull();
    return SyncReport(pushed: push.$1, rejected: push.$2, evaluated: evaluated, pulled: pulled);
  }

  // ----------------------------------------------------------------- push

  Future<(int, int)> _push() async {
    var pushed = 0;
    var rejected = 0;
    final node = await _nodeId();
    while (true) {
      final batch =
          await (_db.select(_db.outboxEntries)
                ..orderBy([(o) => OrderingTerm.asc(o.id)])
                ..limit(100))
              .get();
      if (batch.isEmpty) break;
      final changes = <Map<String, Object?>>[];
      final rows = <OutboxRow>[];
      for (final o in batch) {
        final change = await _envelope(o, node);
        if (change == null) {
          await (_db.delete(_db.outboxEntries)..where((x) => x.id.equals(o.id))).go();
          continue;
        }
        changes.add(change);
        rows.add(o);
      }
      if (changes.isEmpty) continue;
      final results = await _api.push(changes);
      final completionIds = <String>[];
      for (var i = 0; i < changes.length; i++) {
        final c = changes[i];
        final o = rows[i];
        final r = i < results.length ? results[i] : const <String, Object?>{};
        final status = r['status'];
        if (status == 'applied' || status == 'ignored') {
          pushed++;
          await (_db.delete(_db.outboxEntries)..where((x) => x.id.equals(o.id))).go();
          if (c['entity'] == 'completion' && c['op'] == 'insert') completionIds.add(c['id']! as String);
        } else if (r['retryable'] == true || status == null) {
          await (_db.update(
            _db.outboxEntries,
          )..where((x) => x.id.equals(o.id))).write(OutboxEntriesCompanion(attempts: Value(o.attempts + 1)));
          return (pushed, rejected);
        } else {
          rejected++;
          await (_db.delete(_db.outboxEntries)..where((x) => x.id.equals(o.id))).go();
        }
      }
      await _addPendingEvaluations(completionIds);
    }
    return (pushed, rejected);
  }

  Future<Map<String, Object?>?> _envelope(OutboxRow o, String node) async {
    final hlc = hlcFor(o.createdAt, o.id, node);
    switch (o.entity) {
      case 'quest':
        final q = await (_db.select(_db.quests)..where((x) => x.id.equals(o.entityId))).getSingleOrNull();
        if (q == null) return null;
        return {'entity': 'quest', 'op': 'upsert', 'id': q.id, 'hlc': hlc, 'payload': questPayload(q)};
      case 'subtask':
        final s = await (_db.select(_db.subtasks)..where((x) => x.id.equals(o.entityId))).getSingleOrNull();
        if (s == null) return null;
        return {
          'entity': 'subtask',
          'op': 'upsert',
          'id': s.id,
          'hlc': hlc,
          'payload': {
            'quest_id': s.questId,
            'title': s.title,
            'done': s.done,
            'position': s.position,
            'deleted_at': s.deletedAt?.toUtc().toIso8601String(),
          },
        };
      case 'completion':
        final c = await (_db.select(_db.completions)..where((x) => x.id.equals(o.entityId))).getSingleOrNull();
        if (c == null) return null;
        return {
          'entity': 'completion',
          'op': 'insert',
          'id': c.id,
          'hlc': hlc,
          'payload': {
            'quest_id': c.questId,
            'occurrence_day': c.occurrenceDay,
            'completed_at': c.completedAt.toUtc().toIso8601String(),
            'declared_minutes': c.declaredMinutes,
            'tracked_minutes': c.trackedMinutes,
          },
        };
      case 'completion_undo':
        return {
          'entity': 'completion',
          'op': 'undo',
          'id': o.entityId,
          'hlc': hlc,
          'payload': {'undone_at': o.createdAt.toUtc().toIso8601String()},
        };
    }
    return null;
  }

  /// Server representation of a local quest row.
  static Map<String, Object?> questPayload(QuestRow q) {
    final anchor = q.dueAt ?? q.createdAt;
    final reminder = q.remindAt == null
        ? null
        : DateTime(anchor.year, anchor.month, anchor.day, q.remindAt! ~/ 60, q.remindAt! % 60);
    return {
      'parent_id': q.parentId,
      'tier': q.tier,
      'title': q.title,
      'notes': q.notes,
      'category': q.category,
      'priority': q.priority,
      'status': q.status,
      'due_at': q.dueAt?.toUtc().toIso8601String(),
      'estimated_minutes': q.estimatedMinutes,
      'recurrence': q.recurrence == 'none' ? null : {'kind': q.recurrence},
      'intention': q.intention,
      'share_level': _shareToServer[q.shareLevel] ?? 'private',
      'reminder_at': reminder?.toUtc().toIso8601String(),
      'deleted_at': q.deletedAt?.toUtc().toIso8601String(),
      'created_at': q.createdAt.toUtc().toIso8601String(),
    };
  }

  static const _shareToServer = {
    'full': 'full',
    'titleOnly': 'title_only',
    'completionOnly': 'completion_only',
    'private': 'private',
  };

  /// Fixed-width, lexicographically ordered HLC:
  /// `<ISO-8601 UTC millis>-<4 hex counter>-<node>`.
  static String hlcFor(DateTime at, int counter, String node) {
    final iso = DateTime.fromMillisecondsSinceEpoch(at.millisecondsSinceEpoch, isUtc: true).toIso8601String();
    return '$iso-${(counter & 0xffff).toRadixString(16).padLeft(4, '0')}-$node';
  }

  // ------------------------------------------------------------- evaluate

  Future<int> _evaluatePending({required bool useAi}) async {
    final pending = await _pendingEvaluations();
    var done = 0;
    final remaining = <String>[];
    for (final id in pending) {
      try {
        final res = await _api.evaluate(id, useAi: useAi);
        final result = res?['result'];
        final proposal = res?['proposal'];
        if (result is Map && proposal is Map) {
          await _progression.reconcile(
            id,
            EvaluationProposal.fromJson(Map<String, Object?>.from(proposal)),
            decodeResult(jsonEncode(result)),
          );
          done++;
        } else {
          remaining.add(id);
        }
      } on Object {
        remaining.add(id);
      }
    }
    await _write(_pendingEvalKey, remaining);
    return done;
  }

  Future<List<String>> _pendingEvaluations() async {
    final v = await _read(_pendingEvalKey);
    return v is List ? v.whereType<String>().toList() : <String>[];
  }

  Future<void> _addPendingEvaluations(List<String> ids) async {
    if (ids.isEmpty) return;
    await _write(_pendingEvalKey, {...await _pendingEvaluations(), ...ids}.toList());
  }

  // ----------------------------------------------------------------- pull

  Future<int> _pull() async {
    var cursor = (await _read(_cursorKey) as num?)?.toInt() ?? 0;
    var applied = 0;
    while (true) {
      final res = await _api.pull(cursor);
      final changes = (res['changes'] as Map?) ?? const {};
      applied += await _applyQuests((changes['quests'] as List?) ?? const []);
      applied += await _applySubtasks((changes['subtasks'] as List?) ?? const []);
      applied += await _applyCompletions((changes['completions'] as List?) ?? const []);
      applied += await _applyEvaluations((changes['evaluations'] as List?) ?? const []);
      cursor = (res['cursor'] as num?)?.toInt() ?? cursor;
      await _write(_cursorKey, cursor);
      if (res['has_more'] != true) break;
    }
    return applied;
  }

  Future<int> _applyQuests(List<Object?> rows) async {
    var n = 0;
    for (final raw in rows.whereType<Map<Object?, Object?>>()) {
      final r = Map<String, Object?>.from(raw);
      final id = r['id'] as String?;
      if (id == null || await _hasPending('quest', id)) continue;
      DateTime? ts(String k) => r[k] is String ? DateTime.parse(r[k]! as String).toLocal() : null;
      final due = ts('due_at');
      final reminder = ts('reminder_at');
      final recurrence = r['recurrence'] is Map ? (r['recurrence']! as Map)['kind'] as String? : null;
      await _db
          .into(_db.quests)
          .insertOnConflictUpdate(
            QuestsCompanion.insert(
              id: id,
              parentId: Value(r['parent_id'] as String?),
              tier: r['tier'] as String? ?? 'daily',
              title: r['title'] as String? ?? '',
              notes: Value(r['notes'] as String? ?? ''),
              category: Value(r['category'] as String?),
              priority: Value((r['priority'] as num?)?.toInt() ?? 1),
              status: Value(r['status'] as String? ?? 'active'),
              dueAt: Value(due == null ? null : DateTime(due.year, due.month, due.day)),
              estimatedMinutes: Value((r['estimated_minutes'] as num?)?.toInt()),
              recurrence: Value(recurrence ?? 'none'),
              intention: Value(r['intention'] as String?),
              shareLevel: Value(_shareFromServer[r['share_level']] ?? 'private'),
              remindAt: Value(reminder == null ? null : reminder.hour * 60 + reminder.minute),
              createdAt: ts('created_at') ?? DateTime.now(),
              updatedAt: ts('updated_at') ?? DateTime.now(),
              deletedAt: Value(ts('deleted_at')),
            ),
          );
      n++;
    }
    return n;
  }

  static const _shareFromServer = {
    'full': 'full',
    'title_only': 'titleOnly',
    'completion_only': 'completionOnly',
    'private': 'private',
  };

  Future<int> _applySubtasks(List<Object?> rows) async {
    var n = 0;
    for (final raw in rows.whereType<Map<Object?, Object?>>()) {
      final r = Map<String, Object?>.from(raw);
      final id = r['id'] as String?;
      final questId = r['quest_id'] as String?;
      if (id == null || questId == null || await _hasPending('subtask', id)) continue;
      final quest = await (_db.select(_db.quests)..where((q) => q.id.equals(questId))).getSingleOrNull();
      if (quest == null) continue;
      await _db
          .into(_db.subtasks)
          .insertOnConflictUpdate(
            SubtasksCompanion.insert(
              id: id,
              questId: questId,
              title: r['title'] as String? ?? '',
              done: Value(r['done'] == true),
              position: Value((r['position'] as num?)?.toInt() ?? 0),
              updatedAt: DateTime.tryParse(r['updated_at'] as String? ?? '')?.toLocal() ?? DateTime.now(),
              deletedAt: Value(DateTime.tryParse(r['deleted_at'] as String? ?? '')?.toLocal()),
            ),
          );
      n++;
    }
    return n;
  }

  Future<int> _applyCompletions(List<Object?> rows) async {
    var n = 0;
    for (final raw in rows.whereType<Map<Object?, Object?>>()) {
      final r = Map<String, Object?>.from(raw);
      final id = r['id'] as String?;
      final questId = r['quest_id'] as String?;
      if (id == null || questId == null) continue;
      final quest = await (_db.select(_db.quests)..where((q) => q.id.equals(questId))).getSingleOrNull();
      if (quest == null) continue;
      final undone = r['undone_at'] != null || r['state'] == 'undone';
      final completedAt = DateTime.tryParse(r['completed_at'] as String? ?? '')?.toLocal() ?? DateTime.now();
      final existing = await (_db.select(_db.completions)..where((c) => c.id.equals(id))).getSingleOrNull();
      if (existing == null) {
        final occurrence = r['occurrence_day'] as String? ?? dayKey(completedAt);
        await _db
            .into(_db.completions)
            .insert(
              CompletionsCompanion.insert(
                id: id,
                questId: questId,
                occurrenceDay: occurrence,
                localDay: r['local_day'] as String? ?? occurrence,
                completedAt: completedAt,
                declaredMinutes: Value((r['declared_minutes'] as num?)?.toInt()),
                trackedMinutes: Value((r['tracked_minutes'] as num?)?.toInt()),
                state: Value(undone ? 'undone' : 'active'),
                createdAt: completedAt,
              ),
              mode: InsertMode.insertOrIgnore,
            );
        n++;
      } else if (undone && existing.state != 'undone') {
        await (_db.update(
          _db.completions,
        )..where((c) => c.id.equals(id))).write(const CompletionsCompanion(state: Value('undone')));
        await (_db.update(
          _db.ledgerEntries,
        )..where((l) => l.completionId.equals(id))).write(const LedgerEntriesCompanion(superseded: Value(true)));
        n++;
      }
    }
    return n;
  }

  /// Server evaluations carry the authoritative result; they supersede
  /// provisional local rows or create them for completions made on other
  /// devices.
  Future<int> _applyEvaluations(List<Object?> rows) async {
    var n = 0;
    for (final raw in rows.whereType<Map<Object?, Object?>>()) {
      final r = Map<String, Object?>.from(raw);
      final id = r['completion_id'] as String?;
      final proposal = r['proposal'];
      final result = r['result'];
      if (id == null || proposal is! Map || result is! Map) continue;
      final completion = await (_db.select(_db.completions)..where((c) => c.id.equals(id))).getSingleOrNull();
      if (completion == null || completion.state == 'undone') continue;
      final local = await (_db.select(_db.evaluations)..where((e) => e.completionId.equals(id))).getSingleOrNull();
      if (local != null && !local.provisional) continue;
      final parsedProposal = EvaluationProposal.fromJson(Map<String, Object?>.from(proposal));
      final parsedResult = decodeResult(jsonEncode(result));
      if (local == null) {
        await _progression.importConfirmed(completion, parsedProposal, parsedResult);
      } else {
        await _progression.reconcile(id, parsedProposal, parsedResult);
      }
      n++;
    }
    return n;
  }

  Future<bool> _hasPending(String entity, String id) async => (await (_db.select(
    _db.outboxEntries,
  )..where((o) => o.entity.equals(entity) & o.entityId.equals(id))).get()).isNotEmpty;

  // ------------------------------------------------------------ key-value

  Future<String> _nodeId() async {
    final v = await _read(_nodeKey);
    if (v is String && v.length == 8) return v;
    final r = Random.secure();
    final node = List.generate(8, (_) => r.nextInt(16).toRadixString(16)).join();
    await _write(_nodeKey, node);
    return node;
  }

  Future<Object?> _read(String key) async {
    final row = await (_db.select(_db.keyValues)..where((k) => k.key.equals(key))).getSingleOrNull();
    return row == null ? null : jsonDecode(row.value);
  }

  Future<void> _write(String key, Object? value) =>
      _db.into(_db.keyValues).insertOnConflictUpdate(KeyValuesCompanion.insert(key: key, value: jsonEncode(value)));
}
