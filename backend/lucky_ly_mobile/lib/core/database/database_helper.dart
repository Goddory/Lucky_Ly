import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('luckyly_local.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
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

  // --- Avatar Operations ---

  /// Trả về avatar render cục bộ của user hiện tại (ví dụ: record mới nhất chưa xóa)
  Future<Map<String, dynamic>?> getActiveAvatar() async {
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
    final db = await instance.database;
    await db.insert(
      'avatars',
      avatar,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Lấy danh sách record chưa được sync lên server
  Future<List<Map<String, dynamic>>> getUnsyncedRecords(String table) async {
    final db = await instance.database;
    return await db.query(table, where: 'isSync = ?', whereArgs: [0]);
  }

  /// Đánh dấu mảng localId là đã sync
  Future<void> markAsSynced(
    String table,
    String idColumn,
    List<String> ids,
  ) async {
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
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'userId = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (result.isNotEmpty) return result.first;
    return null;
  }

  Future<void> insertUser(Map<String, dynamic> user) async {
    final db = await instance.database;
    await db.insert(
      'users',
      user,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- Designs Operations ---
  Future<List<Map<String, dynamic>>> getDesigns() async {
    final db = await instance.database;
    return await db.query('designs', where: 'isDeleted = ?', whereArgs: [0]);
  }

  Future<void> insertDesign(Map<String, dynamic> design) async {
    final db = await instance.database;
    await db.insert(
      'designs',
      design,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
