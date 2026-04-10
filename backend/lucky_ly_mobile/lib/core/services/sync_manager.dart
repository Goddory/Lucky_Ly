import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import './api_client.dart';

/// SyncManager - Quản lý đồng bộ dữ liệu giữa local SQLite và backend MongoDB
/// 
/// Kiến trúc Offline-First Sync:
/// - Client: SQLite local database (có thể offline)
/// - Server: MongoDB backend (source of truth)
/// 
/// Các tình huống đồng bộ:
/// 1. PUSH: Tải local changes lên server (user create/edit data offline)
/// 2. PULL: Tải updates từ server về local (other users' changes, sync from server)
/// 3. Manual Sync: User bấm "Sync Now" để sync both directions
/// 4. Conflict Resolution: Server là source of truth - overwrite local nếu conflict
/// 
/// Quy trình:
/// 1. User create/edit data offline → save to local SQLite (isSync = 0)
/// 2. When online → PUSH unsynced records to server
/// 3. Server validate & save → return success
/// 4. Mark records as synced (isSync = 1)
/// 5. PULL updates từ server → update local records
/// 6. Save lastSyncTime để pull incremental updates lần sau
/// 
/// Tính năng:
/// - Incremental sync (lastSyncTime để chỉ pull changes)
/// - Batch operations (push/pull nhiều records một lần)
/// - Error handling (graceful degradation)
/// - Token-based authentication
/// - Support 3 tables: avatars, users, designs
class SyncManager {
  /// URL endpoint cho sync operations
  /// 
  /// Tạo thành:
  /// - API Base URL (http://localhost:4000 hoặc production URL)
  /// - /api/sync path
  /// 
  /// Endpoints con:
  /// - POST /api/sync/push/{endpoint} - Push changes từ client
  /// - GET /api/sync/pull/all?lastSyncTime=... - Pull updates
  static String get _syncApiUrl => '${ApiClient.getBaseUrl()}/api/sync';

  /// PUSH: Tải changes từ local lên backend (generic method cho mọi table)
  /// 
  /// Tham số:
  /// - tableName (String): Tên bảng local SQLite (avatars, users, designs)
  /// - endpoint (String): API endpoint (avatars, users, designs)
  /// - idField (String): Tên cột ID (localId hoặc userId) - dùng để mark as synced
  /// 
  /// Quy trình:
  /// 1. Lấy unsynced records từ local database (isSync = 0)
  /// 2. Nếu không có → skip, return true
  /// 3. Lấy auth token từ SharedPreferences
  /// 4. Send POST request: /api/sync/push/{endpoint} với payload {records: [...]}
  /// 5. Nếu success (200):
  ///    - Extract IDs từ unsynced records
  ///    - Call markAsSynced() để update isSync = 1
  ///    - Return true
  /// 6. Nếu error → return false (sẽ retry lần sau)
  /// 
  /// Error Handling: Catch exception, log, return false
  /// 
  /// Performance: Batch operation - 1 request tất cả unsynced records
  static Future<bool> _pushTable(String tableName, String endpoint, String idField) async {
    try {
      /// Lấy instance database
      final dbHelper = DatabaseHelper.instance;
      /// Query unsynced records từ table (WHERE isSync = 0)
      final unsynced = await dbHelper.getUnsyncedRecords(tableName);

      /// Nếu không có changes → nothing to sync
      if (unsynced.isEmpty) return true;

      /// Lấy auth token từ SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      /// Nếu user không logged in → không thể sync
      if (token == null) return false;

      /// Send POST request với tất cả unsynced records
      /// - URL: /api/sync/push/{endpoint}
      /// - Body: {records: [{...}, {...}, ...]}
      /// - Headers: Authorization Bearer token, Content-Type JSON
      final response = await http.post(
        Uri.parse('$_syncApiUrl/push/$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'records': unsynced}),
      );

      /// Success: Backend nhận và save records
      if (response.statusCode == 200) {
        /// Extract IDs từ unsynced records
        /// - e[idField] = giá trị của cột ID (localId hoặc userId)
        /// - toString() = convert to String
        final idsToMark = unsynced.map((e) => e[idField].toString()).toList();
        /// Update isSync = 1 cho các records đã push
        await dbHelper.markAsSynced(tableName, idField, idsToMark);
        return true;
      }
      /// Error: Server trả về error code
      return false;
    } catch (e) {
      /// Network error, timeout, parse error, etc.
      print('Push Data Error for $tableName: $e');
      /// Graceful degradation - retry lần sau
      return false;
    }
  }

  /// PUSH: Tải tất cả local changes lên server
  /// 
  /// Hoạt động:
  /// 1. Push avatars: _pushTable('avatars', 'avatars', 'localId')
  /// 2. Push users: _pushTable('users', 'users', 'userId')
  /// 3. Push designs: _pushTable('designs', 'designs', 'localId')
  /// 4. Return true nếu tất cả push success
  /// 
  /// Workflow:
  /// - Thường gọi khi user click "Sync Now" hoặc app nhận connection
  /// - Kết hợp với pullData() để full sync
  /// 
  /// Return:
  /// - true: Tất cả tables push thành công (hoặc không có changes)
  /// - false: Ít nhất 1 table push thất bại
  static Future<bool> pushData() async {
    /// Push mỗi table (có thể fails độc lập)
    bool avSync = await _pushTable('avatars', 'avatars', 'localId');
    bool usSync = await _pushTable('users', 'users', 'userId');
    bool dsSync = await _pushTable('designs', 'designs', 'localId');
    /// Return true nếu tất cả success
    return avSync && usSync && dsSync;
  }

  /// PULL: Tải updates từ server về local database
  /// 
  /// Tính năng Incremental Sync:
  /// - Lần đầu: lastSyncTime = null → pull ALL records
  /// - Lần sau: lastSyncTime = previous_sync_timestamp → pull only NEW/UPDATED
  /// - Query string: ?lastSyncTime=2024-04-08T10:30:00Z
  /// 
  /// Quy trình:
  /// 1. Lấy lastSyncTime từ SharedPreferences (lần sync cuối cùng)
  /// 2. Send GET request: /api/sync/pull/all?lastSyncTime={time}
  /// 3. Backend trả về: {data: {avatars: [...], users: [...], designs: [...]}}
  /// 4. Iterate mỗi table:
  ///    - Set isSync = 1 (marks received from server)
  ///    - insertAvatar/insertUser/insertDesign (upsert)
  /// 5. Update lastSyncTime trong SharedPreferences
  /// 6. Return true nếu success
  /// 
  /// Conflict Resolution:
  /// - Server là source of truth
  /// - Khi pull → overwrite local copy
  /// - Local changes phải push dulu mới merge
  /// 
  /// Performance: Single request - all tables in 1 response
  static Future<bool> pullData() async {
     try {
      /// Retrieve preferences
      final prefs = await SharedPreferences.getInstance();
      /// Auth token
      final token = prefs.getString('access_token');
      /// Last sync timestamp (nullable) - dùng cho incremental sync
      final lastSyncStr = prefs.getString('last_sync_time');
      
      /// Not authenticated
      if (token == null) return false;

      /// Build URL với incremental sync parameter
      String url = '$_syncApiUrl/pull/all';
      /// Nếu đã sync trước → chỉ pull changes sau lastSyncTime
      if (lastSyncStr != null) {
        url += '?lastSyncTime=$lastSyncStr';
      }

      /// Send GET request
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      /// Success handling
      if (response.statusCode == 200) {
        /// Parse response JSON
        /// Expected format: {data: {avatars: [...], users: [...], designs: [...]}}
        final data = jsonDecode(response.body);
        final dbHelper = DatabaseHelper.instance;

        /// Process avatars
        /// - Get list từ response (default empty list nếu null)
        /// - Iterate và upsert vào local database
        /// - Mark isSync = 1 (from server)
        final avatars = data['data']['avatars'] as List? ?? [];
        for (var record in avatars) {
          record['isSync'] = 1;  /// Mark as synced từ server
          await dbHelper.insertAvatar(record);
        }

        /// Process users
        final users = data['data']['users'] as List? ?? [];
        for (var record in users) {
          record['isSync'] = 1;
          await dbHelper.insertUser(record);
        }

        /// Process designs
        final designs = data['data']['designs'] as List? ?? [];
        for (var record in designs) {
          record['isSync'] = 1;
          await dbHelper.insertDesign(record);
        }

        /// Update lastSyncTime để next pull chỉ lấy incremental changes
        /// Backend return current server timestamp để client tracking
        if (data['timestamp'] != null) {
          await prefs.setString('last_sync_time', data['timestamp']);
        }
        return true;
      }
      /// Error response
      return false;
    } catch (e) {
      /// Network error, timeout, JSON parse error, etc.
      print('Pull Data Error: $e');
      /// Graceful degradation
      return false;
    }
  }

  /// FULL SYNC: Đồng bộ cả 2 chiều (Push + Pull)
  /// 
  /// Timing:
  /// - User bấm "Sync Now" button
  /// - App lifecycle events (app resume from background)
  /// - Network become available (connectivity listener)
  /// 
  /// Workflow:
  /// 1. PUSH: Client changes → Server
  /// 2. PULL: Server updates → Client
  /// 3. Order matters: Push dulus để server có latest data, rồi pull updates
  /// 
  /// Return:
  /// - true: Cả push & pull success
  /// - false: Push OR pull fail (partial sync)
  /// 
  /// UI Feedback:
  /// - Show progress dialog khi syncing
  /// - Notify user khi sync complete hoặc fail
  /// - Trigger UI refresh sau khi pull thành công
  static Future<bool> manualSync() async {
    /// Phase 1: Push local changes lên server
    bool pushSuccess = await pushData();
    /// Phase 2: Pull server updates về local
    bool pullSuccess = await pullData();
    /// Return success chỉ khi cả hai thành công
    return pushSuccess && pullSuccess;
  }
}
