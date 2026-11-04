import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:wyrd_engine/wyrd_engine.dart';

import '../db/database.dart';
import '../models.dart';
import '../remote/remote_api.dart';
import '../repositories/data_repository.dart';
import '../repositories/progression_repository.dart';

class SyncReport {
  const SyncReport({this.pushed = 0, this.rejected = 0, this.evaluated = 0, this.pulled = 0, this.settingsFailed = 0});
  final int pushed;
  final int rejected;
  final int evaluated;
  final int pulled;

  /// Settings groups that could not be sent this cycle (retried next time).
  final int settingsFailed;

  @override
  String toString() =>
      'SyncReport(pushed: $pushed, rejected: $rejected, evaluated: $evaluated, pulled: $pulled, '
      'settingsFailed: $settingsFailed)';
}

/// Ends a cycle whose sync was stopped (sign-out, another account, the
/// device being cleared): nothing more is written.
class SyncStopped implements Exception {
  const SyncStopped();

  @override
  String toString() => 'SyncStopped';
}

/// A group of account settings that syncs as a whole, in the form this
/// device sends ([current], sent with [send]).
///
/// With [table], [fromServer] and [apply], changes made on other devices are
/// taken over too. Pulled rows of [table] are turned into the same form and
/// merged key by key against what this device last sent or took over: keys
/// only the server changed are adopted, keys changed here stay and go up. A
/// device that never synced the group (new, or cleared) takes the server's
/// values as they are, so a new device does not overwrite an account's
/// settings with its defaults.
class SyncedSettings {
  const SyncedSettings({
    required this.key,
    required this.current,
    required this.send,
    this.table,
    this.fromServer,
    this.apply,
  });

  /// Where the value last sent or taken over is kept on this device.
  final String key;
  final Future<Map<String, Object?>> Function() current;
  final Future<void> Function(Map<String, Object?> value) send;

  /// The pulled entity that carries these settings, such as `profiles`.
  final String? table;

  /// The settings in a pulled row, or null when it holds nothing to take
  /// over (a profile no client has changed since sign-up).
  final Map<String, Object?>? Function(Map<String, Object?> row)? fromServer;

  /// Makes [value] (in the form of [current]) this device's settings.
  final Future<void> Function(Map<String, Object?> value)? apply;
}

/// Outbox push, authoritative evaluation and cursor pull (ADR-003).
///
/// Local rows stay the UI's source of truth. Pushes carry a fixed-width
/// hybrid logical clock derived from the mutation time so the server can
/// merge fields last-writer-wins; completions are insert-only; the
/// server's evaluation supersedes the provisional local one.
class SyncService {
  SyncService(this._db, this._api, this._progression, {Future<String?> Function()? clientModel})
    : _clientModel = clientModel; // ignore: prefer_initializing_formals

  /// Model name of the user's own AI provider, sent with proposals made
  /// on this device so the server can record it.
  final Future<String?> Function()? _clientModel;

  final AppDatabase _db;
  final RemoteApi _api;
  final ProgressionRepository _progression;
  static const _cursorKey = 'sync_cursor';
  static const _nodeKey = 'sync_node';
  static const _pendingEvalKey = 'sync_pending_evaluations';
  static const _ownerKey = 'sync_owner';

  bool _stopped = false;

  /// Ends this account's sync on this device: a cycle in progress stops at
  /// its next write and nothing is written afterwards, so a device being
  /// cleared or handed to another account is never refilled.
  void stop() => _stopped = true;

  bool get isStopped => _stopped;

  /// Ties this device's data and sync state to [userId] before it syncs.
  /// Data made as a guest (no owner yet) joins the account that signs in
  /// (A2); data another account left on the device is wiped first, so two
  /// accounts never mix on a shared device. Returns whether it wiped.
  Future<bool> claimFor(String userId) => _guarded(() async {
    final owner = await _read(_ownerKey);
    if (owner == userId) return false;
    final other = owner != null;
    if (other) await DataRepository(_db).wipe();
    await _write(_ownerKey, userId);
    return other;
  });

  /// One full cycle. It pulls first, so settings changed on other devices
  /// are taken over before this device sends its own; then come [settings],
  /// the outbox and the authoritative evaluations, and a last pull for what
  /// they produced. Settings are best-effort: a group that fails is retried
  /// next cycle and never holds up the outbox.
  Future<SyncReport> syncOnce({List<SyncedSettings> settings = const []}) async {
    var pulled = await _pull(settings);
    var settingsFailed = 0;
    for (final s in settings) {
      if (!await _pushSettings(s)) settingsFailed++;
    }
    final push = await _push();
    final evaluated = await _evaluatePending();
    pulled += await _pull(settings);
    return SyncReport(
      pushed: push.$1,
      rejected: push.$2,
      evaluated: evaluated,
      pulled: pulled,
      settingsFailed: settingsFailed,
    );
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
          await _guarded(() => (_db.delete(_db.outboxEntries)..where((x) => x.id.equals(o.id))).go());
          continue;
        }
        changes.add(change);
        rows.add(o);
      }
      if (changes.isEmpty) continue;
      final results = await _api.push(changes);
      final retry = await _guarded(() async {
        final completionIds = <String>[];
        var retry = false;
        for (var i = 0; i < changes.length && !retry; i++) {
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
            retry = true;
          } else {
            rejected++;
            await (_db.delete(_db.outboxEntries)..where((x) => x.id.equals(o.id))).go();
          }
        }
        // Completions applied before a retryable failure still need their
        // authoritative evaluation.
        await _addPendingEvaluations(completionIds);
        return retry;
      });
      if (retry) return (pushed, rejected);
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

  // ------------------------------------------------------------- settings

  /// Sends [s] when it differs from what this device last sent or took
  /// over. Returns false when that failed; it is retried next cycle.
  Future<bool> _pushSettings(SyncedSettings s) async {
    try {
      final value = await s.current();
      if (_canon(await _read(s.key)) == _canon(value)) return true;
      if (_stopped) throw const SyncStopped();
      await s.send(value);
      await _guarded(() => _write(s.key, value));
      return true;
    } on SyncStopped {
      rethrow;
    } on Object {
      return false;
    }
  }

  /// Takes over what another device changed in [s] (see [SyncedSettings]).
  /// Runs inside the pull's transaction.
  Future<void> _adopt(SyncedSettings s, Map<String, Object?> row) async {
    final fromServer = s.fromServer;
    final apply = s.apply;
    if (fromServer == null || apply == null) return;
    final server = fromServer(row);
    if (server == null) return;
    final base = await _read(s.key);
    if (base is Map && _canon(base) == _canon(server)) return; // what this device sent or took over
    final local = await s.current();
    final merged = {...local};
    for (final k in server.keys) {
      final changedThere = base is! Map || _canon(server[k]) != _canon(base[k]);
      final changedHere = base is Map && _canon(local[k]) != _canon(base[k]);
      if (changedThere && !changedHere) merged[k] = server[k];
    }
    if (_canon(merged) != _canon(local)) await apply(merged);
    await _write(s.key, server);
  }

  /// JSON with map keys sorted, so equal settings compare equal whatever
  /// order their keys arrived in.
  static String _canon(Object? value) => jsonEncode(_sorted(value));

  static Object? _sorted(Object? value) => switch (value) {
    final Map<Object?, Object?> map => {for (final k in map.keys.map((k) => '$k').toList()..sort()) k: _sorted(map[k])},
    final List<Object?> list => [for (final e in list) _sorted(e)],
    _ => value,
  };

  // ------------------------------------------------------------- evaluate

  Future<int> _evaluatePending() async {
    final pending = await _pendingEvaluations();
    var done = 0;
    final remaining = <String>[];
    for (final id in pending) {
      try {
        // Proposals made with the user's own AI travel with the request;
        // the server validates and bounds them (it never sees the key).
        final local = await (_db.select(_db.evaluations)..where((e) => e.completionId.equals(id))).getSingleOrNull();
        Map<String, Object?>? clientProposal;
        if (local != null && local.source == 'ai') {
          clientProposal = Map<String, Object?>.from(jsonDecode(local.proposalJson) as Map)..remove('source');
        }
        final res = await _api.evaluate(
          id,
          clientProposal: clientProposal,
          clientModel: clientProposal == null ? null : await _clientModel?.call(),
        );
        final result = res?['result'];
        final proposal = res?['proposal'];
        if (result is Map && proposal is Map) {
          await _guarded(
            () => _progression.reconcile(
              id,
              EvaluationProposal.fromJson(Map<String, Object?>.from(proposal)),
              decodeResult(jsonEncode(result)),
            ),
          );
          done++;
        } else {
          remaining.add(id);
        }
      } on SyncStopped {
        rethrow;
      } on Object {
        remaining.add(id);
      }
    }
    await _guarded(() => _write(_pendingEvalKey, remaining));
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

  /// Applies the server's changes page by page; each page and its cursor
  /// land in one transaction.
  Future<int> _pull(List<SyncedSettings> settings) async {
    var cursor = (await _read(_cursorKey) as num?)?.toInt() ?? 0;
    var applied = 0;
    while (true) {
      final res = await _api.pull(cursor);
      final next = (res['cursor'] as num?)?.toInt() ?? cursor;
      applied += await _guarded(() async {
        final changes = (res['changes'] as Map?) ?? const {};
        var n = await _applyQuests((changes['quests'] as List?) ?? const []);
        n += await _applySubtasks((changes['subtasks'] as List?) ?? const []);
        final proposals = <String, Map<String, Object?>>{
          for (final e in ((changes['evaluations'] as List?) ?? const []).whereType<Map<Object?, Object?>>())
            if (e['completion_id'] is String && e['proposal'] is Map)
              e['completion_id']! as String: Map<String, Object?>.from(e['proposal']! as Map),
        };
        n += await _applyCompletions((changes['completions'] as List?) ?? const [], proposals);
        for (final s in settings) {
          final table = s.table;
          if (table == null) continue;
          for (final row in ((changes[table] as List?) ?? const []).whereType<Map<Object?, Object?>>()) {
            await _adopt(s, Map<String, Object?>.from(row));
          }
        }
        await _write(_cursorKey, next);
        return n;
      });
      cursor = next;
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

  Future<int> _applyCompletions(List<Object?> rows, Map<String, Map<String, Object?>> proposals) async {
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
      if (!undone && r['result'] is Map) {
        if (await _applyResult(id, Map<String, Object?>.from(r['result']! as Map), proposals[id], r)) n++;
      }
    }
    return n;
  }

  /// Applies a server-confirmed result: supersedes a provisional local one,
  /// or records it for a completion made on another device.
  Future<bool> _applyResult(
    String completionId,
    Map<String, Object?> result,
    Map<String, Object?>? proposal,
    Map<String, Object?> completionRow,
  ) async {
    final completion = await (_db.select(_db.completions)..where((c) => c.id.equals(completionId))).getSingleOrNull();
    if (completion == null || completion.state == 'undone') return false;
    final local = await (_db.select(
      _db.evaluations,
    )..where((e) => e.completionId.equals(completionId))).getSingleOrNull();
    if (local != null && !local.provisional) return false;
    final parsedResult = decodeResult(jsonEncode(result));
    final parsedProposal = proposal != null
        ? EvaluationProposal.fromJson(proposal)
        : EvaluationProposal(
            category: QuestCategory.parse(completionRow['category']),
            similarityKey: parsedResult.similarityKey,
            difficulty: 3,
            estimatedMinutes: parsedResult.effectiveMinutes.clamp(1, 600),
            attributes: const [],
            source: parsedResult.source,
          );
    if (local == null) {
      await _progression.importConfirmed(completion, parsedProposal, parsedResult);
    } else {
      await _progression.reconcile(completionId, parsedProposal, parsedResult);
    }
    return true;
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
    await _guarded(() => _write(_nodeKey, node));
    return node;
  }

  /// Runs [writes] in one transaction unless sync was stopped. Transactions
  /// run one at a time, so a device being cleared waits for one already
  /// running, and every later one sees the stop.
  Future<T> _guarded<T>(Future<T> Function() writes) {
    if (_stopped) return Future<T>.error(const SyncStopped());
    return _db.transaction(() async {
      if (_stopped) throw const SyncStopped();
      return writes();
    });
  }

  Future<Object?> _read(String key) async {
    final row = await (_db.select(_db.keyValues)..where((k) => k.key.equals(key))).getSingleOrNull();
    return row == null ? null : jsonDecode(row.value);
  }

  Future<void> _write(String key, Object? value) =>
      _db.into(_db.keyValues).insertOnConflictUpdate(KeyValuesCompanion.insert(key: key, value: jsonEncode(value)));
}
