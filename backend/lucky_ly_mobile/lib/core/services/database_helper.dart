/// Re-export DatabaseHelper từ database layer
/// 
/// Mục đích: Cung cấp single entry point để import DatabaseHelper
/// - Import từ services: `import 'services/database_helper.dart'`
/// - Thay vì: `import 'database/database_helper.dart'`
/// 
/// Lợi ích:
/// 1. Centralized imports - không cần nhớ folder structure
/// 2. Dễ refactor - chỉ cần thay đổi import ở đây nếu di chuyển file
/// 3. Architecture clarity - services exposed qua services layer
export '../database/database_helper.dart';

/// DatabaseHelper - Stub/Wrapper class cho local database management
/// 
/// LƯU Ý: Đây là implementation stub. Class thực tế nằm ở:
/// `database/database_helper.dart`
/// 
/// Mục đích file này:
/// - Cung cấp interface/contract cho các methods database
/// - Ngôn ngữ từ services layer (architecture clarity)
/// - Placeholder nếu muốn extend hoặc customize behavior
/// 
/// Các tính năng (delegate sang real implementation):
/// 1. Insert operations - Lưu data local (avatars, users, designs)
/// 2. Sync tracking - Check/mark records đã sync lên server
/// 3. Singleton pattern - Access qua DatabaseHelper.instance
class DatabaseHelper {
  /// Singleton instance của DatabaseHelper
  /// 
  /// Usage: DatabaseHelper.instance để access database operations
  /// - Khởi tạo lần đầu: DatabaseHelper instance = DatabaseHelper._init()
  /// - Lần sau: Sử dụng instance đã cached, không khởi tạo lại
  static final DatabaseHelper instance = DatabaseHelper._init();

  /// Private constructor cho Singleton Pattern
  /// 
  /// Tại sao private?
  /// - Ngăn chặn tạo instance mới DatabaseHelper()
  /// - Bắt buộc sử dụng DatabaseHelper.instance
  /// - Đảm bảo chỉ 1 database connection duy nhất
  DatabaseHelper._init();

  /// Lấy danh sách records chưa được sync lên server
  /// 
  /// Tham số:
  /// - table (String): Tên bảng (ví dụ: 'avatars', 'users', 'designs')
  /// 
  /// Returns: List<Map<String, dynamic>> chứa các records với isSync = 0
  /// 
  /// Mục đích:
  /// - Tìm các thay đổi cục bộ cần upload lên backend
  /// - Dùng trong sync service để upload batches
  /// - Check điều kiện trước khi quyết định upload
  /// 
  /// Implementation: Delegate sang database/database_helper.dart
  Future<List<Map<String, dynamic>>> getUnsyncedRecords(String table) async {
    return [];
  }

  /// Đánh dấu danh sách records là đã được sync lên server
  /// 
  /// Tham số:
  /// - table (String): Tên bảng
  /// - idField (String): Tên cột ID (ví dụ: 'localId' hoặc 'userId')
  /// - ids (List<String>): Danh sách IDs cần mark as synced
  /// 
  /// Mục đích:
  /// - Sau khi upload thành công, cập nhật isSync = 1
  /// - Tránh re-upload same records lần sau
  /// - Giữ local database state sync với server
  /// 
  /// Implementation: Delegate sang database/database_helper.dart
  Future<void> markAsSynced(String table, String idField, List<String> ids) async {}

  /// Chèn hoặc cập nhật avatar vào local database
  /// 
  /// Tham số:
  /// - data (Map): Avatar object chứa các fields:
  ///   - localId: UUID unique
  ///   - url: URL avatar trên server
  ///   - localPath: Đường dẫn file local (nếu downloaded)
  ///   - clientUpdatedAt: Timestamp
  ///   - isDeleted: Soft delete flag
  ///   - isSync: Sync status
  /// 
  /// Mục đích:
  /// - Lưu avatar vào local cache (SQLite)
  /// - Render avatar offline
  /// - Sync với server qua sync service
  /// 
  /// Implementation: Delegate sang database/database_helper.dart
  Future<void> insertAvatar(Map<String, dynamic> data) async {}

  /// Chèn hoặc cập nhật user info vào local database
  /// 
  /// Tham số:
  /// - data (Map): User object chứa:
  ///   - userId: ID từ backend
  ///   - fullName: Tên đầy đủ
  ///   - email: Email address
  ///   - avatarUrl: URL avatar
  ///   - clientUpdatedAt: Timestamp
  ///   - isSync: Sync status
  /// 
  /// Mục đích:
  /// - Cache user profile locally
  /// - Cho phép offline access thông tin user
  /// - Update khi user refresh profile
  /// 
  /// Implementation: Delegate sang database/database_helper.dart
  Future<void> insertUser(Map<String, dynamic> data) async {}

  /// Chèn hoặc cập nhật design vào local database
  /// 
  /// Tham số:
  /// - data (Map): Design object chứa:
  ///   - localId: UUID unique
  ///   - title: Tiêu đề design
  ///   - data: JSON content của design
  ///   - clientUpdatedAt: Timestamp
  ///   - isDeleted: Soft delete flag
  ///   - isSync: Sync status
  /// 
  /// Mục đích:
  /// - Lưu design tạo cục bộ
  /// - Offline persistence - không mất khi close app
  /// - Sync lên server sau khi có connection
  /// 
  /// Implementation: Delegate sang database/database_helper.dart
  Future<void> insertDesign(Map<String, dynamic> data) async {}
}
