import 'package:sqflite/sqflite.dart';
import '../models/mesh_route.dart';
import 'database.dart';

class RouteRepository {
  final MeshDatabase _meshDb;

  RouteRepository([MeshDatabase? meshDb]) : _meshDb = meshDb ?? MeshDatabase();

  Future<void> upsertRoute(MeshRoute route) async {
    final db = await _meshDb.database;
    await db.insert(
      'routes',
      route.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<MeshRoute?> getBestRoute(String destinationId) async {
    final db = await _meshDb.database;
    final results = await db.query(
      'routes',
      where: 'destinationId = ?',
      whereArgs: [destinationId],
      orderBy: 'score DESC',
      limit: 1,
    );
    if (results.isEmpty) return null;
    return MeshRoute.fromDbMap(results.first);
  }

  Future<List<MeshRoute>> getAllRoutes() async {
    final db = await _meshDb.database;
    final results = await db.query(
      'routes',
      orderBy: 'score DESC',
    );
    return results.map((m) => MeshRoute.fromDbMap(m)).toList();
  }

  Future<void> deleteRoute(String destinationId, String nextHopId) async {
    final db = await _meshDb.database;
    await db.delete(
      'routes',
      where: 'destinationId = ? AND nextHopId = ?',
      whereArgs: [destinationId, nextHopId],
    );
  }

  Future<void> purgeStaleRoutes(int maxAgeSeconds) async {
    final cutoff = DateTime.now().subtract(Duration(seconds: maxAgeSeconds)).millisecondsSinceEpoch;
    final db = await _meshDb.database;
    await db.delete(
      'routes',
      where: 'lastUpdated < ?',
      whereArgs: [cutoff],
    );
  }
}
