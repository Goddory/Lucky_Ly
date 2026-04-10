/// EventModel - Model để đại diện cho một event/sự kiện trong ứng dụng
/// 
/// Dùng để lưu trữ thông tin về:
/// - Personal notes - Ghi chú cá nhân của user
/// - Events - Các sự kiện quan trọng
/// - Reminders - Các nhắc nhở
/// 
/// Model này tương thích với cả backend API và local SQLite database
class EventModel {
  /// ID duy nhất của event (_id từ MongoDB hoặc id từ SQLite)
  final String id;

  /// Tiêu đề/tên sự kiện
  final String title;

  /// Ngày và giờ của sự kiện
  final DateTime date;

  /// Loại event (personal_note, birthday, reminder, etc.)
  final String type;

  /// ID của user sở hữu event (optional)
  final String? userId;

  /// Ghi chú chi tiết về event (optional)
  final String? note;

  /// Constructor chính của EventModel
  /// 
  /// Các tham số bắt buộc:
  /// - id: ID duy nhất của event
  /// - title: Tiêu đề sự kiện
  /// - date: Ngày tháng năm giờ của sự kiện
  /// - type: Loại event (personal_note, birthday, reminder)
  /// 
  /// Các tham số optional:
  /// - userId: ID user sở hữu event
  /// - note: Ghi chú chi tiết
  EventModel({
    required this.id,
    required this.title,
    required this.date,
    required this.type,
    this.userId,
    this.note,
  });

  /// Factory constructor để tạo EventModel từ JSON response
  /// 
  /// Xử lý các trường hợp:
  /// 1. JSON từ API backend (MongoDB format với _id)
  /// 2. JSON từ local database (SQLite format với id)
  /// 3. Date parsing linh hoạt (String ISO 8601 hoặc DateTime object)
  /// 4. Error handling - nếu parse date thất bại, dùng thời gian hiện tại
  /// 5. Type safety - convert tất cả string fields
  /// 
  /// Input fields từ JSON:
  /// - _id hoặc id: ID của event
  /// - title: Tiêu đề
  /// - date: Ngày (có thể là String ISO 8601 hoặc DateTime)
  /// - type: Loại event (default: 'personal_note')
  /// - user_id: ID của user (optional)
  /// - note: Ghi chú (optional)
  factory EventModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate = DateTime.now();
    
    try {
      final rawDate = json['date'];
      if (rawDate != null) {
        if (rawDate is String) {
          /// Parse ISO 8601 format từ API (ví dụ: "2024-04-07T10:30:00Z")
          parsedDate = DateTime.parse(rawDate);
        } else if (rawDate is DateTime) {
          /// Nếu đã là DateTime object, dùng trực tiếp
          parsedDate = rawDate;
        } else {
          /// Kiểu dữ liệu không mong đợi - log warning
          print('Warning: Unexpected date type: ${rawDate.runtimeType}');
        }
      }
    } catch (e) {
      /// Nếu parse date thất bại, log error và dùng thời gian hiện tại
      print('Error parsing date: $e');
    }

    return EventModel(
      /// Hỗ trợ cả _id (MongoDB) và id (local DB)
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: json['title'] ?? '',
      date: parsedDate,
      /// Default type là 'personal_note' nếu không được cung cấp
      type: json['type'] ?? 'personal_note',
      /// user_id có thể null - map từ user_id field
      userId: json['user_id']?.toString(),
      /// note là optional field
      note: json['note']?.toString(),
    );
  }

  /// Convert EventModel thành JSON để gửi lên server hoặc lưu xuống database
  /// 
  /// Output format:
  /// - title: Tiêu đề sự kiện
  /// - date: Ngày giờ dalam format ISO 8601 (ví dụ: "2024-04-07T10:30:00.000")
  /// - type: Loại event
  /// - note: Ghi chú (chỉ bao gồm nếu không null, sử dụng conditional spread)
  /// 
  /// Lưu ý:
  /// - id không được gửi (sẽ được tạo bởi backend hoặc database)
  /// - userId không được gửi (sẽ được thêm bởi backend từ auth token)
  /// - Chỉ gửi note nếu có dữ liệu (tránh bao gồm null values)
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      /// Convert DateTime sang ISO 8601 String format
      'date': date.toIso8601String(),
      'type': type,
      /// Conditional spread - chỉ thêm note nếu không null
      if (note != null) 'note': note,
    };
  }
}
