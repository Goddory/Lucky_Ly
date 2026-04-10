import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

/// DatabaseHelper - Quản lý database SQLite cục bộ cho Lucky Ly Mobile
/// 
/// Kiến trúc Singleton Pattern:
/// - Cung cấp một instance duy nhất để truy cập database
/// - Hỗ trợ cả web (không lưu trữ), mobile (Android/iOS), và desktop (Windows/Linux/macOS)
/// - Tự động khởi tạo FFI Factory cho các platform desktop
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  /// Lưu trữ instance database SQLite sau khi được khởi tạo
  static Database? _database;
  
  /// Flag để tránh khởi tạo FFI Factory nhiều lần
  static bool _sqfliteFactoryInitialized = false;

  /// Private constructor cho Singleton Pattern
  DatabaseHelper._init() {
    _initializeDatabaseFactoryIfNeeded();
  }

  /// Getter để lấy instance database - Lazy initialization
  /// 
  /// Kiểm tra nếu database đã được tạo trước đó, nếu không sẽ khởi tạo mới
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('luckyly_local.db');
    return _database!;
  }

  /// Khởi tạo database SQLite
  /// 
  /// - Chọn DatabaseFactory phù hợp (FFI cho desktop, sqflite cho mobile)
  /// - Tạo database tại đường dẫn thích hợp
  /// - Thiết lập version schema và callbacks onCreate, onOpen
  Future<Database> _initDB(String filePath) async {
    _initializeDatabaseFactoryIfNeeded();

    /// Chọn DatabaseFactory: FFI cho desktop (Windows/Linux/macOS), sqflite cho mobile
    DatabaseFactory df = databaseFactory;
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      df = databaseFactoryFfi;
    }

    /// Lấy đường dẫn databases của hệ thống:
    final dbPath = await df.getDatabasesPath();
    final path = join(dbPath, filePath);

    /// Mở database với các tùy chọn:
    /// - version: Quản lý schema migration
    /// - onCreate: Tạo các bảng khi database mới
    /// - onOpen: Đảm bảo các bảng cục bộ tồn tại (cho legacy databases)
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

  /// Khởi tạo FFI Factory cho desktop platforms (Windows/Linux/macOS)
  /// 
  /// FFI (Foreign Function Interface) được yêu cầu để truy cập SQLite
  /// trên desktop vì không có native SQLite support trực tiếp.
  /// - Chỉ khởi tạo một lần duy nhất (flag _sqfliteFactoryInitialized)
  /// - Web platforms không cần khởi tạo FFI
  static void _initializeDatabaseFactoryIfNeeded() {
    if (_sqfliteFactoryInitialized) return;

    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    _sqfliteFactoryInitialized = true;
  }

  /// Tạo schema database khi database mới được tạo
  /// 
  /// Các bảng chính:
  /// 1. avatars - Lưu trữ avatar cục bộ của user
  /// 2. users - Thông tin user cached cục bộ
  /// 3. designs - Các design đã tạo cục bộ
  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT';
    const boolType = 'BOOLEAN NOT NULL';

    /// Bảng avatars:
    /// - localId: ID cục bộ (UUID)
    /// - url: URL avatar trên server
    /// - localPath: Đường dẫn file avatar đã download
    /// - clientUpdatedAt: Timestamp cập nhật cuối cùng trên client
    /// - isDeleted: Đánh dấu xóa (soft delete)
    /// - isSync: Flag đã được đồng bộ lên server
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

    /// Bảng users:
    /// - userId: ID của user (từ server)
    /// - fullName: Tên đầy đủ
    /// - email: Email address
    /// - avatarUrl: URL avatar
    /// - clientUpdatedAt: Timestamp cập nhật trên client
    /// - isSync: Đã đồng bộ lên server
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

    /// Bảng designs:
    /// - localId: ID cục bộ (UUID)
    /// - title: Tiêu đề design
    /// - data: JSON data chứa nội dung design
    /// - clientUpdatedAt: Timestamp cập nhật
    /// - isDeleted: Soft delete flag
    /// - isSync: Đã sync lên server
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

  /// Đảm bảo các bảng cục bộ tồn tại (phòng legacy databases)
  /// 
  /// Thường chạy khi onOpen database để cập nhật schema nếu cần
  Future<void> _ensureLocalTables(Database db) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT';
    const boolType = 'BOOLEAN NOT NULL';

    /// Tạo bảng users nếu chưa tồn tại
    /// (dùng CREATE TABLE IF NOT EXISTS để tránh lỗi)
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

  /// Lấy danh sách tên cột của bảng từ PRAGMA table_info
  /// 
  /// Dùng để kiểm tra schema hiện tại khi bảng có thể có
  /// các format naming khác nhau (camelCase vs snake_case)
  Future<List<String>> _getTableColumns(Database db, String table) async {
    final result = await db.rawQuery('PRAGMA table_info($table)');
    return result
        .map((row) => (row['name']?.toString() ?? '').trim())
        .where((name) => name.isNotEmpty)
        .toList();
  }

  // ========== Avatar Operations ==========

  /// Lấy avatar cục bộ được active (record mới nhất chưa xóa)
  /// 
  /// Dùng để render avatar user hiện tại từ cached local data
  /// Returns: Map với avatarUrl và localPath (nullable)
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

  /// Chèn hoặc cập nhật avatar vào database cục bộ
  /// 
  /// ConflictAlgorithm.replace: Nếu localId exists thì update, không thì insert
  Future<void> insertAvatar(Map<String, dynamic> avatar) async {
    if (kIsWeb) return;
    final db = await instance.database;
    await db.insert(
      'avatars',
      avatar,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Lấy danh sách record chưa được sync lên server (isSync = false)
  /// 
  /// Dùng để tìm các thay đổi cục bộ cần được upload
  /// Returns: List các record với isSync = 0
  Future<List<Map<String, dynamic>>> getUnsyncedRecords(String table) async {
    if (kIsWeb) return [];
    final db = await instance.database;
    return await db.query(table, where: 'isSync = ?', whereArgs: [0]);
  }

  /// Đánh dấu danh sách record là đã được sync lên server
  /// 
  /// Sau khi upload thành công lên backend, set isSync = 1
  /// để tránh re-upload lần sau
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

  // ========== Users Operations ==========

  /// Lấy thông tin user từ database cục bộ
  /// 
  /// - Xử lý cả naming convention camelCase và snake_case
  /// - Normalize output keys về camelCase cho consistency
  /// Returns: User data hoặc null nếu không tìm thấy
  Future<Map<String, dynamic>?> getUser(String userId) async {
    if (kIsWeb) return null;
    final db = await instance.database;
    await _ensureLocalTables(db);

    /// Lấy danh sách cột hiện tại để kiểm tra naming convention
    final columns = await _getTableColumns(db, 'users');
    if (columns.isEmpty) return null;

    /// Xác định ID column: userId (camelCase) hoặc user_id (snake_case)
    final hasCamelId = columns.contains('userId');
    final hasSnakeId = columns.contains('user_id');
    final idColumn = hasCamelId
        ? 'userId'
        : (hasSnakeId ? 'user_id' : null);

    if (idColumn == null) return null;

    /// Query user data
    final result = await db.query(
      'users',
      where: '$idColumn = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (result.isEmpty) return null;

    final row = result.first;

    /// Normalize output keys về camelCase để consistent với caller
    /// (hỗ trợ cả database dùng camelCase hoặc snake_case)
    return {
      'userId': row['userId'] ?? row['user_id'],
      'fullName': row['fullName'] ?? row['full_name'],
      'email': row['email'],
      'avatarUrl': row['avatarUrl'] ?? row['avatar_url'],
      'clientUpdatedAt': row['clientUpdatedAt'] ?? row['client_updated_at'],
      'isSync': row['isSync'] ?? row['is_sync'],
    };
  }

  /// Chèn hoặc cập nhật user vào database cục bộ
  /// 
  /// - Auto-detect naming convention (camelCase vs snake_case)
  /// - Convert input data sang formato phù hợp với schema hiện tại
  /// - ConflictAlgorithm.replace: update nếu exists, insert nếu mới
  Future<void> insertUser(Map<String, dynamic> user) async {
    if (kIsWeb) return;
    final db = await instance.database;
    await _ensureLocalTables(db);

    /// Lấy danh sách cột hiện tại
    final columns = await _getTableColumns(db, 'users');

    /// Kiểm tra nếu database dùng convention snake_case
    final useSnakeCase = columns.contains('user_id') && !columns.contains('userId');

    /// Chuẩn bị payload data theo naming convention tương ứng
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

  // ========== Designs Operations ==========

  /// Lấy danh sách designs chưa xóa từ database cục bộ
  /// 
  /// Dùng để load tất cả designs của user khi khởi động app
  /// Returns: List các design record (isDeleted = 0)
  Future<List<Map<String, dynamic>>> getDesigns() async {
    if (kIsWeb) return [];
    final db = await instance.database;
    return await db.query('designs', where: 'isDeleted = ?', whereArgs: [0]);
  }

  /// Chèn hoặc cập nhật design vào database cục bộ
  /// 
  /// ConflictAlgorithm.replace: update nếu localId exists
  Future<void> insertDesign(Map<String, dynamic> design) async {
    if (kIsWeb) return;
    final db = await instance.database;
    await db.insert(
      'designs',
      design,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Đóng database connection
  /// 
  /// Gọi khi app shutdown hoặc khi muốn reset database
  Future close() async {
    if (kIsWeb) return;
    final db = await instance.database;
    db.close();
  }
}
