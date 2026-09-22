import 'package:sqflite/sqflite.dart';
import '../models/sos_event.dart';
import 'database.dart';

class SosRepository {
  final MeshDatabase _meshDb;

  SosRepository([MeshDatabase? meshDb]) : _meshDb = meshDb ?? MeshDatabase();

  Future<void> upsertSosEvent(SosEvent event) async {
    final db = await _meshDb.database;
    await db.insert(
      'sos_events',
      event.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<SosEvent?> getSosEventById(String sosId) async {
    final db = await _meshDb.database;
    final results = await db.query(
      'sos_events',
      where: 'sosId = ?',
      whereArgs: [sosId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return SosEvent.fromDbMap(results.first);
  }

  Future<List<SosEvent>> getAllSosEvents() async {
    final db = await _meshDb.database;
    final results = await db.query(
      'sos_events',
      orderBy: 'timestamp DESC',
    );
    return results.map((m) => SosEvent.fromDbMap(m)).toList();
  }

  Future<SosEvent?> getLatestActiveSos() async {
    final db = await _meshDb.database;
    final results = await db.query(
      'sos_events',
      where: 'status != ?',
      whereArgs: [SosStatus.resolved.name],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (results.isEmpty) return null;
    return SosEvent.fromDbMap(results.first);
  }
}
