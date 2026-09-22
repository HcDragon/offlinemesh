import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../core/constants/app_constants.dart';

class MeshDatabase {
  static final MeshDatabase _instance = MeshDatabase._internal();
  factory MeshDatabase() => _instance;
  MeshDatabase._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Messages table
    await db.execute('''
      CREATE TABLE messages (
        messageId TEXT PRIMARY KEY,
        protocolVersion INTEGER,
        messageType TEXT,
        senderId TEXT,
        destinationId TEXT,
        createdAt INTEGER,
        ttl INTEGER,
        hopCount INTEGER,
        priority TEXT,
        payload TEXT,
        signature TEXT,
        nonce TEXT,
        status TEXT,
        relayHops TEXT
      )
    ''');

    // Peers table
    await db.execute('''
      CREATE TABLE peers (
        meshId TEXT PRIMARY KEY,
        displayName TEXT,
        publicKey TEXT,
        lastSeen INTEGER,
        rssi INTEGER,
        estimatedDistanceMeters REAL,
        hopCount INTEGER,
        isRelay INTEGER,
        isSosNode INTEGER,
        isShelterNode INTEGER,
        isRescueNode INTEGER,
        connectionState TEXT,
        latitude REAL,
        longitude REAL
      )
    ''');

    // Routes table
    await db.execute('''
      CREATE TABLE routes (
        sourceId TEXT,
        destinationId TEXT,
        nextHopId TEXT,
        hopCount INTEGER,
        score REAL,
        lastUpdated INTEGER,
        linkQuality REAL,
        PRIMARY KEY (sourceId, destinationId)
      )
    ''');

    // SOS events table
    await db.execute('''
      CREATE TABLE sos_events (
        sosId TEXT PRIMARY KEY,
        originPeerId TEXT,
        originDisplayName TEXT,
        timestamp INTEGER,
        status TEXT,
        latitude REAL,
        longitude REAL,
        emergencyNote TEXT,
        relayHistory TEXT,
        acknowledgedAt INTEGER
      )
    ''');
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('messages');
    await db.delete('peers');
    await db.delete('routes');
    await db.delete('sos_events');
  }
}
