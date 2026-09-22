import 'package:sqflite/sqflite.dart';
import '../models/peer.dart';
import 'database.dart';

class PeerRepository {
  final MeshDatabase _meshDb;

  PeerRepository([MeshDatabase? meshDb]) : _meshDb = meshDb ?? MeshDatabase();

  Future<void> upsertPeer(Peer peer) async {
    final db = await _meshDb.database;
    await db.insert(
      'peers',
      peer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Peer?> getPeerById(String meshId) async {
    final db = await _meshDb.database;
    final results = await db.query(
      'peers',
      where: 'meshId = ?',
      whereArgs: [meshId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Peer.fromMap(results.first);
  }

  Future<List<Peer>> getAllPeers() async {
    final db = await _meshDb.database;
    final results = await db.query(
      'peers',
      orderBy: 'lastSeen DESC',
    );
    return results.map((m) => Peer.fromMap(m)).toList();
  }

  Future<void> updatePeerConnectionState(String meshId, PeerConnectionState state) async {
    final db = await _meshDb.database;
    await db.update(
      'peers',
      {
        'connectionState': state.name,
        'lastSeen': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'meshId = ?',
      whereArgs: [meshId],
    );
  }

  Future<int> getDiscoveredCount() async {
    final db = await _meshDb.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM peers');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getConnectedCount() async {
    final db = await _meshDb.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM peers WHERE connectionState = ?',
      [PeerConnectionState.connected.name],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
