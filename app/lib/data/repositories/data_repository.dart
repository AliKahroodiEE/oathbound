import 'package:drift/drift.dart';

import '../db/database.dart';

/// Data export and deletion (requirements A4, §17 privacy).
class DataRepository {
  DataRepository(this._db);

  final AppDatabase _db;

  /// Every user-owned row on this device as JSON-ready maps.
  Future<Map<String, Object?>> exportAll() async {
    Future<List<Map<String, Object?>>> rows(TableInfo<Table, DataClass> t) async =>
        [for (final r in await _db.select(t).get()) r.toJson()];
    return {
      'format': 'oathbound-export',
      'version': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'quests': await rows(_db.quests),
      'subtasks': await rows(_db.subtasks),
      'completions': await rows(_db.completions),
      'evaluations': await rows(_db.evaluations),
      'ledgerEntries': await rows(_db.ledgerEntries),
      'achievements': await rows(_db.unlockedAchievements),
      'dayMarks': await rows(_db.dayMarks),
      'preferences': await rows(_db.keyValues),
    };
  }

  /// Permanently deletes all local data.
  Future<void> wipe() => _db.transaction(() async {
    for (final TableInfo<Table, dynamic> t in [
      _db.ledgerEntries,
      _db.evaluations,
      _db.completions,
      _db.subtasks,
      _db.quests,
      _db.unlockedAchievements,
      _db.dayMarks,
      _db.keyValues,
      _db.outboxEntries,
    ]) {
      await _db.delete(t).go();
    }
  });
}
