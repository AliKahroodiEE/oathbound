import 'dart:async';
import 'dart:ui' show Locale;

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wyrd/core/locale/regional_settings.dart';
import 'package:wyrd/data/db/database.dart';
import 'package:wyrd/data/models.dart';
import 'package:wyrd/data/remote/remote_api.dart';
import 'package:wyrd/data/repositories/progression_repository.dart';
import 'package:wyrd/data/repositories/quest_repository.dart';
import 'package:wyrd/data/repositories/settings_repository.dart';
import 'package:wyrd/data/sync/sync_coordinator.dart';
import 'package:wyrd/data/sync/sync_service.dart';
import 'package:wyrd_engine/wyrd_engine.dart';

class FakeApi implements RemoteApi {
  final pushed = <Map<String, Object?>>[];
  Map<String, Object?> pullResponse = {'cursor': 0, 'has_more': false, 'changes': <String, Object?>{}};
  Map<String, Object?>? evaluation;
  bool failRetryable = false;

  /// Changes from this position in a batch on come back retryable.
  int? retryableFrom;

  /// Holds a pull until it completes.
  Future<void>? pullGate;
  final profiles = <Map<String, Object?>>[];

  @override
  Future<List<Map<String, Object?>>> push(List<Map<String, Object?>> changes) async {
    if (failRetryable) {
      return [
        for (final c in changes) {'id': c['id'], 'status': 'rejected', 'retryable': true},
      ];
    }
    final from = retryableFrom ?? changes.length;
    pushed.addAll(changes.take(from));
    return [
      for (var i = 0; i < changes.length; i++)
        i < from
            ? {'id': changes[i]['id'], 'status': 'applied'}
            : {'id': changes[i]['id'], 'status': 'rejected', 'retryable': true},
    ];
  }

  /// Like the server: only what changed after [cursor].
  @override
  Future<Map<String, Object?>> pull(int cursor) async {
    if (pullGate != null) await pullGate;
    final next = (pullResponse['cursor']! as num).toInt();
    if (cursor >= next) return {'cursor': cursor, 'has_more': false, 'changes': <String, Object?>{}};
    return pullResponse;
  }

  Map<String, Object?>? lastClientProposal;
  String? lastClientModel;

  @override
  Future<Map<String, Object?>?> evaluate(
    String completionId, {
    Map<String, Object?>? clientProposal,
    String? clientModel,
  }) async {
    lastClientProposal = clientProposal;
    lastClientModel = clientModel;
    return evaluation;
  }

  @override
  Future<void> updateProfile(Map<String, Object?> fields) async => profiles.add(fields);

  final notificationPrefs = <Map<String, Object?>>[];

  @override
  Future<void> updateNotificationPrefs(Map<String, Object?> prefs) async => notificationPrefs.add(prefs);
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
    sync = SyncService(db, api, progression, clientModel: () async => 'my-model');
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

  test('a settings group is sent only when it changes', () async {
    var value = <String, Object?>{'locale': 'fa', 'ai_evaluation_enabled': false};
    final group = SyncedSettings(key: 'sync_test', current: () async => value, send: (v) async => api.profiles.add(v));
    await sync.syncOnce(settings: [group]);
    await sync.syncOnce(settings: [group]);
    expect(api.profiles, hasLength(1));
    value = {...value, 'ai_evaluation_enabled': true};
    await sync.syncOnce(settings: [group]);
    expect(api.profiles, hasLength(2));
  });

  test('a settings group that fails does not hold up the outbox', () async {
    await quests.create(const QuestDraft(title: 'Read'));
    final report = await sync.syncOnce(
      settings: [
        SyncedSettings(
          key: 'sync_test',
          current: () async => {'a': 1},
          send: (_) async => throw StateError('function set_notification_prefs does not exist'),
        ),
      ],
    );
    expect(report.settingsFailed, 1);
    expect(report.pushed, 1);
    expect(await db.select(db.outboxEntries).get(), isEmpty);
  });

  test('completions applied before a retryable failure still get evaluated', () async {
    final q = await quests.create(const QuestDraft(title: 'Write report'));
    await progression.complete(q, provisional: true);
    await quests.create(const QuestDraft(title: 'Read'));
    api.retryableFrom = 2; // quest and completion go through, the next quest waits
    await sync.syncOnce();
    expect(await db.select(db.outboxEntries).get(), hasLength(1));
    api
      ..retryableFrom = null
      ..evaluation = {'result': serverResult(5), 'proposal': serverProposal()};
    final next = await sync.syncOnce();
    expect(next.evaluated, 1);
    expect(await progression.attributeTotals(), {Attribute.discipline: 5});
  });

  group('the device belongs to one account', () {
    Future<List<KeyValueRow>> key(String name) => (db.select(db.keyValues)..where((k) => k.key.equals(name))).get();

    test('guest data joins the first account that signs in', () async {
      await quests.create(const QuestDraft(title: 'Made as a guest'));
      expect(await sync.claimFor('user-a'), isFalse);
      expect(await sync.claimFor('user-a'), isFalse);
      expect(await db.select(db.quests).get(), hasLength(1));
      expect(await db.select(db.outboxEntries).get(), hasLength(1));
    });

    test('another account\'s data is wiped before a new account syncs', () async {
      await sync.claimFor('user-a');
      await quests.create(const QuestDraft(title: 'A\'s quest'));
      api.pullResponse = {'cursor': 900, 'has_more': false, 'changes': <String, Object?>{}};
      await sync.syncOnce();
      await quests.create(const QuestDraft(title: 'A\'s unsynced quest'));
      expect(await key('sync_cursor'), isNotEmpty);

      expect(await sync.claimFor('user-b'), isTrue);
      expect(await db.select(db.quests).get(), isEmpty);
      expect(await db.select(db.outboxEntries).get(), isEmpty, reason: 'never uploaded into B');
      expect(await key('sync_cursor'), isEmpty, reason: 'B downloads its own history from the start');
      expect(await sync.claimFor('user-b'), isFalse);
    });
  });

  test('a stop while a page downloads keeps it off the device', () async {
    final gate = Completer<void>();
    api
      ..pullGate = gate.future
      ..pullResponse = {
        'cursor': 7,
        'has_more': false,
        'changes': {
          'quests': [
            {
              'id': '018f0000-0000-7000-8000-000000000009',
              'tier': 'daily',
              'title': 'Arrives late',
              'created_at': '2026-11-04T05:00:00Z',
              'updated_at': '2026-11-04T05:00:00Z',
            },
          ],
        },
      };
    final cycle = sync.syncOnce();
    await pumpEventQueue();
    sync.stop();
    gate.complete();
    await expectLater(cycle, throwsA(isA<SyncStopped>()));
    expect(await db.select(db.quests).get(), isEmpty);
    expect(await (db.select(db.keyValues)..where((k) => k.key.equals('sync_cursor'))).get(), isEmpty);
    await expectLater(sync.syncOnce(), throwsA(isA<SyncStopped>()));
  });

  group('account settings', () {
    late SettingsRepository settings;
    late List<SyncedSettings> groups;

    setUp(() {
      settings = SettingsRepository(db);
      groups = syncedSettings(
        settings: settings,
        api: api,
        regional: () => const RegionalPrefs(language: 'en').resolve(const Locale('en')),
      );
    });

    Map<String, Object?> prefsRow({bool guild = true, bool weekly = true, String start = '22:00:00'}) => {
      'user_id': 'u',
      'categories': {
        'reminders': true,
        'guild_reactions': guild,
        'guild_comments': guild,
        'challenge_milestones': guild,
        'weekly_summary': weekly,
        'briefing': false,
      },
      'quiet_hours_start': start,
      'quiet_hours_end': '08:00:00',
    };

    test('notification settings go up in the shape set_notification_prefs takes', () async {
      await settings.updateProfile(
        (p) => p.copyWith(notifGuild: false, quietStartMinutes: 23 * 60 + 30, quietEndMinutes: 7 * 60),
      );
      await sync.syncOnce(settings: groups);
      expect(api.notificationPrefs.single, {
        'categories': {
          'reminders': true,
          'guild_reactions': false,
          'guild_comments': false,
          'challenge_milestones': false,
          'weekly_summary': true,
        },
        'quiet_hours_start': '23:30',
        'quiet_hours_end': '07:00',
      });
      await sync.syncOnce(settings: groups);
      expect(api.notificationPrefs, hasLength(1), reason: 'unchanged settings are not sent again');
    });

    test('a new device takes over the account\'s notification settings instead of sending its defaults', () async {
      api.pullResponse = {
        'cursor': 5,
        'has_more': false,
        'changes': {
          'notification_prefs': [prefsRow(guild: false, start: '23:30:00')],
        },
      };
      await sync.syncOnce(settings: groups);
      final p = await settings.profile();
      expect(p.notifGuild, isFalse);
      expect(p.quietStartMinutes, 23 * 60 + 30);
      expect(api.notificationPrefs, isEmpty, reason: 'nothing to send back');
    });

    test('changes from another device merge key by key with changes made here', () async {
      await sync.syncOnce(settings: groups);
      expect(api.notificationPrefs, hasLength(1));
      // Here: weekly summary off, not sent yet. Elsewhere: guild off.
      await settings.updateProfile((p) => p.copyWith(notifWeekly: false));
      api.pullResponse = {
        'cursor': 9,
        'has_more': false,
        'changes': {
          'notification_prefs': [prefsRow(guild: false)],
        },
      };
      await sync.syncOnce(settings: groups);
      final p = await settings.profile();
      expect(p.notifGuild, isFalse, reason: 'taken over from the other device');
      expect(p.notifWeekly, isFalse, reason: 'kept from this device');
      final sent = api.notificationPrefs.last['categories']! as Map;
      expect(sent['guild_comments'], isFalse);
      expect(sent['weekly_summary'], isFalse);
    });

    test('a profile untouched since sign-up gets this device\'s choices', () async {
      await settings.updateProfile((p) => p.copyWith(characterName: 'Arin', weeklyTarget: 5));
      api.pullResponse = {
        'cursor': 3,
        'has_more': false,
        'changes': {
          'profiles': [
            {
              'id': 'u',
              'display_name': '',
              'weekly_target': 4,
              'motivation': <String, Object?>{},
              'ai_evaluation_enabled': true,
              'created_at': '2026-11-04T05:00:00+00:00',
              'updated_at': '2026-11-04T05:00:00+00:00',
            },
          ],
        },
      };
      await sync.syncOnce(settings: groups);
      expect((await settings.profile()).weeklyTarget, 5);
      expect(api.profiles.any((f) => f['display_name'] == 'Arin' && f['weekly_target'] == 5), isTrue);
    });

    test('an account set up elsewhere comes to a new device', () async {
      api.pullResponse = {
        'cursor': 3,
        'has_more': false,
        'changes': {
          'profiles': [
            {
              'id': 'u',
              'display_name': 'Arin Vale',
              'weekly_target': 6,
              'motivation': {
                'drivers': ['mastery'],
                'tone': 'warm',
              },
              'ai_evaluation_enabled': false,
              'locale': 'fa',
              'created_at': '2026-11-01T05:00:00+00:00',
              'updated_at': '2026-11-03T05:00:00+00:00',
            },
          ],
        },
      };
      await sync.syncOnce(settings: groups);
      final p = await settings.profile();
      expect(p.characterName, 'Arin Vale');
      expect(p.weeklyTarget, 6);
      expect(p.aiEnabled, isFalse);
      expect(p.tone, 'warm');
      expect(p.drivers, ['mastery']);
      expect(api.profiles.where((f) => f.containsKey('weekly_target')), isEmpty, reason: 'nothing sent back');
      expect(api.profiles.single['locale'], 'en', reason: 'where this device is still goes up');
    });
  });

  test('HLC strings sort in mutation order', () {
    final a = SyncService.hlcFor(DateTime.utc(2026, 11, 4, 8), 1, 'aaaaaaaa');
    final b = SyncService.hlcFor(DateTime.utc(2026, 11, 4, 8), 2, 'aaaaaaaa');
    final c = SyncService.hlcFor(DateTime.utc(2026, 11, 4, 8, 0, 1), 1, 'aaaaaaaa');
    expect(a.compareTo(b), lessThan(0));
    expect(b.compareTo(c), lessThan(0));
  });

  test('proposals from the user\'s own AI are sent to the server, heuristics are not', () async {
    final q = await quests.create(const QuestDraft(title: 'Write report'));
    final own = EvaluationProposal.fromJson({...serverProposal(), 'source': 'ai'});
    await progression.complete(q, provisional: true, aiProposal: own);
    api.evaluation = {'result': serverResult(7), 'proposal': serverProposal()};
    await sync.syncOnce();
    expect(api.lastClientProposal, isNotNull);
    expect(api.lastClientProposal!.containsKey('source'), isFalse);
    expect(api.lastClientModel, 'my-model');

    final q2 = await quests.create(const QuestDraft(title: 'Read'));
    await progression.complete(q2, provisional: true);
    await sync.syncOnce();
    expect(api.lastClientProposal, isNull);
  });
}
