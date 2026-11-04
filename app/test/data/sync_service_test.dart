import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oathbound/data/db/database.dart';
import 'package:oathbound/data/models.dart';
import 'package:oathbound/data/remote/remote_api.dart';
import 'package:oathbound/data/repositories/progression_repository.dart';
import 'package:oathbound/data/repositories/quest_repository.dart';
import 'package:oathbound/data/sync/sync_service.dart';
import 'package:oathbound_engine/oathbound_engine.dart';

class FakeApi implements RemoteApi {
  final pushed = <Map<String, Object?>>[];
  Map<String, Object?> pullResponse = {'cursor': 0, 'has_more': false, 'changes': <String, Object?>{}};
  Map<String, Object?>? evaluation;
  bool failRetryable = false;
  final profiles = <Map<String, Object?>>[];

  @override
  Future<List<Map<String, Object?>>> push(List<Map<String, Object?>> changes) async {
    if (failRetryable) {
      return [
        for (final c in changes) {'id': c['id'], 'status': 'rejected', 'retryable': true},
      ];
    }
    pushed.addAll(changes);
    return [
      for (final c in changes) {'id': c['id'], 'status': 'applied'},
    ];
  }

  @override
  Future<Map<String, Object?>> pull(int cursor) async => pullResponse;

  @override
  Future<Map<String, Object?>?> evaluate(String completionId) async => evaluation;

  @override
  Future<void> updateProfile(Map<String, Object?> fields) async => profiles.add(fields);
}

Map<String, Object?> serverResult(int discipline) => {
  'grants': [
    {'attribute': 'discipline', 'amount': discipline, 'rawAmount': discipline},
  ],
  'totalXp': discipline,
  'effectiveMinutes': 45,
  'trivial': false,
  'similarityKey': 'work.report',
  'adjustments': <Object>[],
  'ruleVersion': rulesVersion,
  'source': 'ai',
};

Map<String, Object?> serverProposal() => {
  'category': 'work',
  'similarityKey': 'work.report',
  'difficulty': 3,
  'estimatedMinutes': 45,
  'attributes': [
    {'attribute': 'discipline', 'weight': 1.0, 'reason': 'Finished a report.'},
  ],
  'confidence': 0.9,
  'source': 'ai',
};

void main() {
  late AppDatabase db;
  late QuestRepository quests;
  late ProgressionRepository progression;
  late FakeApi api;
  late SyncService sync;

  setUp(() {
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    quests = QuestRepository(db);
    progression = ProgressionRepository(db);
    api = FakeApi();
    sync = SyncService(db, api, progression);
  });
  tearDown(() => db.close());

  test('pushes quests and completions with server field names and an HLC', () async {
    final q = await quests.create(
      const QuestDraft(title: 'Write report', shareLevel: ShareLevel.titleOnly, remindAt: 18 * 60),
    );
    await progression.complete(q, provisional: true);
    api.evaluation = {'result': serverResult(7), 'proposal': serverProposal(), 'source': 'ai'};

    final report = await sync.syncOnce();

    expect(report.pushed, 2);
    final quest = api.pushed.firstWhere((c) => c['entity'] == 'quest');
    final payload = quest['payload']! as Map<String, Object?>;
    expect(payload['share_level'], 'title_only');
    expect(payload['reminder_at'], isNotNull);
    expect(
      quest['hlc'] as String,
      matches(RegExp(r'^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d\.\d{3}Z-[0-9a-f]{4}-[0-9a-f]{8}$')),
    );
    expect(api.pushed.any((c) => c['entity'] == 'completion' && c['op'] == 'insert'), isTrue);
    expect(await db.select(db.outboxEntries).get(), isEmpty);

    expect(report.evaluated, 1);
    expect(await progression.attributeTotals(), {Attribute.discipline: 7});
  });

  test('a retryable rejection keeps the outbox for the next attempt', () async {
    await quests.create(const QuestDraft(title: 'Read'));
    api.failRetryable = true;
    await sync.syncOnce();
    final outbox = await db.select(db.outboxEntries).get();
    expect(outbox, hasLength(1));
    expect(outbox.single.attempts, 1);
  });

  test('evaluations that fail stay pending and are retried', () async {
    final q = await quests.create(const QuestDraft(title: 'Write report'));
    await progression.complete(q, provisional: true);
    await sync.syncOnce();
    expect((await db.select(db.evaluations).getSingle()).provisional, isTrue);
    api.evaluation = {'result': serverResult(9), 'proposal': serverProposal()};
    final second = await sync.syncOnce();
    expect(second.evaluated, 1);
    expect(await progression.attributeTotals(), {Attribute.discipline: 9});
  });

  test('pulls quests, completions and evaluations from another device', () async {
    api.pullResponse = {
      'cursor': 42,
      'has_more': false,
      'changes': {
        'quests': [
          {
            'id': '018f0000-0000-7000-8000-000000000001',
            'tier': 'daily',
            'title': 'مطالعه الکترونیک',
            'status': 'completed',
            'share_level': 'completion_only',
            'recurrence': null,
            'created_at': '2026-11-04T05:00:00Z',
            'updated_at': '2026-11-04T05:00:00Z',
          },
        ],
        'completions': [
          {
            'id': '018f0000-0000-7000-8000-0000000000c1',
            'quest_id': '018f0000-0000-7000-8000-000000000001',
            'occurrence_day': '2026-11-04',
            'local_day': '2026-11-04',
            'completed_at': '2026-11-04T06:00:00Z',
            'state': 'active',
            'result': serverResult(11),
            'category': 'work',
          },
        ],
        'evaluations': [
          {'completion_id': '018f0000-0000-7000-8000-0000000000c1', 'proposal': serverProposal()},
        ],
      },
    };
    final report = await sync.syncOnce();
    expect(report.pulled, 3); // quest, completion, confirmed result
    final q = await quests.byId('018f0000-0000-7000-8000-000000000001');
    expect(q!.title, 'مطالعه الکترونیک');
    expect(q.shareLevel, ShareLevel.completionOnly);
    expect(await progression.attributeTotals(), {Attribute.discipline: 11});

    // Pulling the same rows again changes nothing.
    await sync.syncOnce();
    expect(await progression.attributeTotals(), {Attribute.discipline: 11});
  });

  test('pushes the profile only when it changes', () async {
    const profile = {'locale': 'fa', 'ai_locale': 'fa', 'ai_evaluation_enabled': false};
    await sync.syncOnce(profile: profile);
    await sync.syncOnce(profile: profile);
    expect(api.profiles, hasLength(1));
    await sync.syncOnce(profile: {...profile, 'ai_evaluation_enabled': true});
    expect(api.profiles, hasLength(2));
  });

  test('HLC strings sort in mutation order', () {
    final a = SyncService.hlcFor(DateTime.utc(2026, 11, 4, 8), 1, 'aaaaaaaa');
    final b = SyncService.hlcFor(DateTime.utc(2026, 11, 4, 8), 2, 'aaaaaaaa');
    final c = SyncService.hlcFor(DateTime.utc(2026, 11, 4, 8, 0, 1), 1, 'aaaaaaaa');
    expect(a.compareTo(b), lessThan(0));
    expect(b.compareTo(c), lessThan(0));
  });
}
