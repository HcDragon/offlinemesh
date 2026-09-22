import 'package:sqflite/sqflite.dart';
import '../models/mesh_message.dart';
import '../models/message_status.dart';
import 'database.dart';

class MessageRepository {
  final MeshDatabase _meshDb;

  MessageRepository([MeshDatabase? meshDb]) : _meshDb = meshDb ?? MeshDatabase();

  Future<void> insertMessage(MeshMessage message) async {
    final db = await _meshDb.database;
    await db.insert(
      'messages',
      message.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<MeshMessage?> getMessageById(String messageId) async {
    final db = await _meshDb.database;
    final results = await db.query(
      'messages',
      where: 'messageId = ?',
      whereArgs: [messageId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return MeshMessage.fromDbMap(results.first);
  }

  Future<void> updateMessageStatus(String messageId, MessageStatus status) async {
    final db = await _meshDb.database;
    await db.update(
      'messages',
      {'status': status.name},
      where: 'messageId = ?',
      whereArgs: [messageId],
    );
  }

  Future<List<MeshMessage>> getConversation(String peerMeshId) async {
    final db = await _meshDb.database;
    final results = await db.query(
      'messages',
      where: '(senderId = ? OR destinationId = ?) OR destinationId = "*"',
      whereArgs: [peerMeshId, peerMeshId],
      orderBy: 'createdAt ASC',
    );
    return results.map((m) => MeshMessage.fromDbMap(m)).toList();
  }

  Future<List<MeshMessage>> getAllMessages() async {
    final db = await _meshDb.database;
    final results = await db.query(
      'messages',
      orderBy: 'createdAt DESC',
    );
    return results.map((m) => MeshMessage.fromDbMap(m)).toList();
  }

  Future<List<MeshMessage>> getPendingQueuedMessages() async {
    final db = await _meshDb.database;
    final results = await db.query(
      'messages',
      where: 'status = ? OR status = ?',
      whereArgs: [MessageStatus.queued.name, MessageStatus.relaying.name],
      orderBy: 'createdAt ASC',
    );
    return results.map((m) => MeshMessage.fromDbMap(m)).toList();
  }

  Future<int> getQueuedCount() async {
    final db = await _meshDb.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM messages WHERE status = ?',
      [MessageStatus.queued.name],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getRelayedCount() async {
    final db = await _meshDb.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM messages WHERE status = ?',
      [MessageStatus.relayed.name],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getDeliveredCount() async {
    final db = await _meshDb.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM messages WHERE status = ? OR status = ?',
      [MessageStatus.delivered.name, MessageStatus.ackReceived.name],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
