import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;
  static bool _sqfliteFactoryInitialized = false;

  DatabaseHelper._init() {
    _initializeDatabaseFactoryIfNeeded();
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('luckyly_local.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    _initializeDatabaseFactoryIfNeeded();

    DatabaseFactory df = databaseFactory;
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      df = databaseFactoryFfi;
    }

    final dbPath = await df.getDatabasesPath();
    final path = join(dbPath, filePath);

    return await df.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _createDB,
        onOpen: (db) async {
          // Ensure required local tables exist even for pre-existing/legacy DB files.
          await _ensureLocalTables(db);
        },
      ),
    );
  }

  static void _initializeDatabaseFactoryIfNeeded() {
    if (_sqfliteFactoryInitialized) return;

    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    _sqfliteFactoryInitialized = true;
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT';
    const boolType = 'BOOLEAN NOT NULL';

    await db.execute('''
CREATE TABLE avatars (
  localId $idType,
  url $textType,
  localPath $textType,
  clientUpdatedAt $textType,
  isDeleted $boolType,
  isSync $boolType
)
''');

    await db.execute('''
CREATE TABLE users (
  userId $idType,
  fullName $textType,
  email $textType,
  avatarUrl $textType,
  clientUpdatedAt $textType,
  isSync $boolType
)
''');

    await db.execute('''
CREATE TABLE designs (
  localId $idType,
  title $textType,
  data $textType,
  clientUpdatedAt $textType,
  isDeleted $boolType,
  isSync $boolType
)
''');
  }

  Future<void> _ensureLocalTables(Database db) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT';
    const boolType = 'BOOLEAN NOT NULL';

    await db.execute('''
CREATE TABLE IF NOT EXISTS users (
  userId $idType,
  fullName $textType,
  email $textType,
  avatarUrl $textType,
  clientUpdatedAt $textType,
  isSync $boolType
)
''');
  }

  Future<List<String>> _getTableColumns(Database db, String table) async {
    final result = await db.rawQuery('PRAGMA table_info($table)');
    return result
        .map((row) => (row['name']?.toString() ?? '').trim())
        .where((name) => name.isNotEmpty)
        .toList();
  }

  // --- Avatar Operations ---

  /// Trả về avatar render cục bộ của user hiện tại (ví dụ: record mới nhất chưa xóa)
  Future<Map<String, dynamic>?> getActiveAvatar() async {
    if (kIsWeb) return null;
    final db = await instance.database;
    final result = await db.query(
      'avatars',
      where: 'isDeleted = ?',
      whereArgs: [0],
      orderBy: 'clientUpdatedAt DESC',
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first;
    } else {
      return null;
    }
  }

  Future<void> insertAvatar(Map<String, dynamic> avatar) async {
    if (kIsWeb) return;
    final db = await instance.database;
    await db.insert(
      'avatars',
      avatar,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Lấy danh sách record chưa được sync lên server
  Future<List<Map<String, dynamic>>> getUnsyncedRecords(String table) async {
    if (kIsWeb) return [];
    final db = await instance.database;
    return await db.query(table, where: 'isSync = ?', whereArgs: [0]);
  }

  /// Đánh dấu mảng localId là đã sync
  Future<void> markAsSynced(
    String table,
    String idColumn,
    List<String> ids,
  ) async {
    if (kIsWeb) return;
    final db = await instance.database;
    for (String id in ids) {
      await db.update(
        table,
        {'isSync': 1},
        where: '$idColumn = ?',
        whereArgs: [id],
      );
    }
  }

  // --- Users Operations ---
  Future<Map<String, dynamic>?> getUser(String userId) async {
    if (kIsWeb) return null;
    final db = await instance.database;
    await _ensureLocalTables(db);

    final columns = await _getTableColumns(db, 'users');
    if (columns.isEmpty) return null;

    final hasCamelId = columns.contains('userId');
    final hasSnakeId = columns.contains('user_id');
    final idColumn = hasCamelId
        ? 'userId'
        : (hasSnakeId ? 'user_id' : null);

    if (idColumn == null) return null;

    final result = await db.query(
      'users',
      where: '$idColumn = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (result.isEmpty) return null;

    final row = result.first;

    // Normalize output keys so callers can keep using camelCase fields.
    return {
      'userId': row['userId'] ?? row['user_id'],
      'fullName': row['fullName'] ?? row['full_name'],
      'email': row['email'],
      'avatarUrl': row['avatarUrl'] ?? row['avatar_url'],
      'clientUpdatedAt': row['clientUpdatedAt'] ?? row['client_updated_at'],
      'isSync': row['isSync'] ?? row['is_sync'],
    };
  }

  Future<void> insertUser(Map<String, dynamic> user) async {
    if (kIsWeb) return;
    final db = await instance.database;
    await _ensureLocalTables(db);

    final columns = await _getTableColumns(db, 'users');

    final useSnakeCase = columns.contains('user_id') && !columns.contains('userId');

    final payload = useSnakeCase
        ? <String, dynamic>{
            'user_id': user['userId'],
            'full_name': user['fullName'],
            'email': user['email'],
            'avatar_url': user['avatarUrl'],
            'client_updated_at': user['clientUpdatedAt'],
            'is_sync': user['isSync'],
          }
        : <String, dynamic>{
            'userId': user['userId'],
            'fullName': user['fullName'],
            'email': user['email'],
            'avatarUrl': user['avatarUrl'],
            'clientUpdatedAt': user['clientUpdatedAt'],
            'isSync': user['isSync'],
          };

    await db.insert(
      'users',
      payload,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- Designs Operations ---
  Future<List<Map<String, dynamic>>> getDesigns() async {
    if (kIsWeb) return [];
    final db = await instance.database;
    return await db.query('designs', where: 'isDeleted = ?', whereArgs: [0]);
  }

  Future<void> insertDesign(Map<String, dynamic> design) async {
    if (kIsWeb) return;
    final db = await instance.database;
    await db.insert(
      'designs',
      design,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future close() async {
    if (kIsWeb) return;
    final db = await instance.database;
    db.close();
  }
}
