import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// Daily quests, contracts and long-term objectives.
@DataClassName('QuestRow')
class Quests extends Table {
  TextColumn get id => text()();
  TextColumn get parentId => text().nullable()();
  TextColumn get tier => text()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get notes => text().withDefault(const Constant(''))();

  /// Category chosen by the user; null lets the evaluator decide.
  TextColumn get category => text().nullable()();
  IntColumn get priority => integer().withDefault(const Constant(1))();

  /// `active`, `completed` or `archived`.
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get dueAt => dateTime().nullable()();
  IntColumn get estimatedMinutes => integer().nullable()();

  /// `none`, `daily`, `weekdays` or `weekly`.
  TextColumn get recurrence => text().withDefault(const Constant('none'))();
  TextColumn get intention => text().nullable()();
  TextColumn get shareLevel => text().withDefault(const Constant('private'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SubtaskRow')
class Subtasks extends Table {
  TextColumn get id => text()();
  TextColumn get questId => text().references(Quests, #id)();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  BoolColumn get done => boolean().withDefault(const Constant(false))();
  IntColumn get position => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Append-only completion facts; the client UUID is the idempotency key.
@DataClassName('CompletionRow')
class Completions extends Table {
  TextColumn get id => text()();
  TextColumn get questId => text().references(Quests, #id)();

  /// Local day (yyyy-MM-dd) of the occurrence this completion fulfils.
  TextColumn get occurrenceDay => text()();
  TextColumn get localDay => text()();
  DateTimeColumn get completedAt => dateTime()();
  IntColumn get declaredMinutes => integer().nullable()();
  IntColumn get trackedMinutes => integer().nullable()();

  /// `active` or `undone`.
  TextColumn get state => text().withDefault(const Constant('active'))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Evaluator proposal plus engine result for one completion.
@DataClassName('EvaluationRow')
class Evaluations extends Table {
  TextColumn get completionId => text().references(Completions, #id)();
  TextColumn get localDay => text()();
  TextColumn get category => text()();
  TextColumn get similarityKey => text()();
  IntColumn get effectiveMinutes => integer()();
  IntColumn get totalXp => integer()();
  BoolColumn get trivial => boolean()();
  TextColumn get source => text()();
  TextColumn get proposalJson => text()();
  TextColumn get resultJson => text()();

  /// True until the server confirms (signed-in users only).
  BoolColumn get provisional => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {completionId};
}

/// Append-only attribute grants and reversals.
@DataClassName('LedgerRow')
class LedgerEntries extends Table {
  TextColumn get id => text()();
  TextColumn get completionId => text().nullable()();
  TextColumn get attribute => text()();
  IntColumn get amount => integer()();
  IntColumn get rawAmount => integer()();

  /// `grant` or `reversal`.
  TextColumn get kind => text()();
  TextColumn get ruleVersion => text()();
  TextColumn get localDay => text()();
  BoolColumn get provisional => boolean().withDefault(const Constant(false))();
  BoolColumn get superseded => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AchievementRow')
class UnlockedAchievements extends Table {
  TextColumn get id => text()();
  DateTimeColumn get unlockedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Rest and pause markers per local day.
@DataClassName('DayMarkRow')
class DayMarks extends Table {
  TextColumn get localDay => text()();
  BoolColumn get rest => boolean().withDefault(const Constant(false))();
  BoolColumn get paused => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {localDay};
}

/// Small JSON documents: profile, preferences, regional settings.
@DataClassName('KeyValueRow')
class KeyValues extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Pending mutations to push to the server, in order (ADR-003).
@DataClassName('OutboxRow')
class OutboxEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entity => text()();
  TextColumn get entityId => text()();
  TextColumn get op => text()();
  TextColumn get payload => text()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
}

@DriftDatabase(
  tables: [
    Quests,
    Subtasks,
    Completions,
    Evaluations,
    LedgerEntries,
    UnlockedAchievements,
    DayMarks,
    KeyValues,
    OutboxEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement(
        'CREATE INDEX idx_completions_quest ON completions (quest_id, occurrence_day)',
      );
      await customStatement(
        'CREATE INDEX idx_ledger_day ON ledger_entries (local_day)',
      );
      await customStatement(
        'CREATE INDEX idx_evaluations_day ON evaluations (local_day)',
      );
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  static QueryExecutor _open() => driftDatabase(
    name: 'oathbound',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}
