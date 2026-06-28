import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Almacenamiento local (SQLite) que da soporte offline a TODA la app.
///
/// Se apoya en dos tablas genericas, de modo que cualquier modulo que pase
/// por [ApiClient] obtiene cache de lecturas y cola de escrituras sin escribir
/// una tabla a medida por entidad:
///
/// - `http_cache`: guarda el cuerpo JSON crudo de cada GET exitoso, indexado
///   por la ruta. Sin conexion, se devuelve la ultima copia guardada.
/// - `outbox`: cola de escrituras (POST/PUT/DELETE) realizadas sin conexion.
///   Mantiene la filosofia `is_synced`/`server_id` del proyecto: cada fila
///   nace con `synced = 0` y un `local_id` temporal; al sincronizar se marca
///   `synced = 1` y se guarda el `server_id` real que devuelve el backend.
class OfflineStore {
  OfflineStore({String databaseName = 'sigat_offline.db'})
    : _databaseName = databaseName;

  static const int _version = 1;
  static const String _cacheTable = 'http_cache';
  static const String _outboxTable = 'outbox';

  final String _databaseName;
  Database? _database;

  Future<Database> get _db async {
    if (_database != null) return _database!;
    _database = await _open();
    return _database!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), _databaseName);
    return openDatabase(path, version: _version, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_cacheTable (
        path        TEXT PRIMARY KEY,
        body        TEXT NOT NULL,
        updated_at  INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $_outboxTable (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        method      TEXT NOT NULL,
        path        TEXT NOT NULL,
        collection  TEXT NOT NULL,
        payload     TEXT,
        local_id    INTEGER,
        server_id   INTEGER,
        created_at  INTEGER NOT NULL,
        synced      INTEGER NOT NULL DEFAULT 0,
        error       TEXT
      )
    ''');
  }

  // ─── Cache de lecturas ──────────────────────────────────────────────

  Future<void> cachePut(String path, String body) async {
    final db = await _db;
    await db.insert(_cacheTable, {
      'path': path,
      'body': body,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> cacheGet(String path) async {
    final db = await _db;
    final rows = await db.query(
      _cacheTable,
      columns: ['body'],
      where: 'path = ?',
      whereArgs: [path],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['body'] as String?;
  }

  // ─── Cola de escrituras (outbox) ────────────────────────────────────

  Future<void> enqueue({
    required String method,
    required String path,
    required String collection,
    Map<String, dynamic>? payload,
    required int localId,
  }) async {
    final db = await _db;
    await db.insert(_outboxTable, {
      'method': method,
      'path': path,
      'collection': collection,
      'payload': payload == null ? null : jsonEncode(payload),
      'local_id': localId,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'synced': 0,
    });
  }

  /// Escrituras pendientes (no sincronizadas), en orden de creacion.
  Future<List<OutboxEntry>> pending() async {
    final db = await _db;
    final rows = await db.query(
      _outboxTable,
      where: 'synced = 0',
      orderBy: 'id ASC',
    );
    return rows.map(OutboxEntry.fromRow).toList();
  }

  Future<int> pendingCount() async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM $_outboxTable WHERE synced = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> markSynced(int id, {int? serverId}) async {
    final db = await _db;
    await db.update(
      _outboxTable,
      {'synced': 1, 'server_id': serverId, 'error': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markError(int id, String message) async {
    final db = await _db;
    await db.update(
      _outboxTable,
      {'error': message},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Borra del historial las escrituras ya sincronizadas correctamente.
  Future<void> clearSynced() async {
    final db = await _db;
    await db.delete(_outboxTable, where: 'synced = 1');
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}

class OutboxEntry {
  OutboxEntry({
    required this.id,
    required this.method,
    required this.path,
    required this.collection,
    required this.payload,
    required this.localId,
    required this.error,
  });

  final int id;
  final String method;
  final String path;
  final String collection;
  final Map<String, dynamic>? payload;
  final int? localId;
  final String? error;

  factory OutboxEntry.fromRow(Map<String, Object?> row) {
    final rawPayload = row['payload'] as String?;
    Map<String, dynamic>? payload;
    if (rawPayload != null && rawPayload.isNotEmpty) {
      final decoded = jsonDecode(rawPayload);
      if (decoded is Map<String, dynamic>) payload = decoded;
    }
    return OutboxEntry(
      id: row['id'] as int,
      method: row['method'] as String,
      path: row['path'] as String,
      collection: row['collection'] as String,
      payload: payload,
      localId: row['local_id'] as int?,
      error: row['error'] as String?,
    );
  }
}
