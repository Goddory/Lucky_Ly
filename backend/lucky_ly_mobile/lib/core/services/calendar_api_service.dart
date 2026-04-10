import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event_model.dart';
import 'api_client.dart';

/// CalendarApiService - Service API để quản lý calendar events/notes
/// 
/// Tính năng chính:
/// 1. Fetch Events - Lấy danh sách tất cả events/notes từ backend
/// 2. Create Event - Tạo event/note mới
/// 3. Token Management - Tự động lấy token từ SharedPreferences hoặc parameter
/// 4. Error Handling - Xử lý các loại lỗi: timeout, connection error, server error
/// 5. Debug Logging - In ra tất cả request/response để debug
/// 
/// URL Endpoint:
/// - Base: ${API_BASE_URL}/api/events (ví dụ: http://localhost:4000/api/events)
class CalendarApiService {
  /// URL endpoint API cho calendar events
  /// 
  /// Tự động xây dựng từ API base URL + "/api/events"
  /// - Web: http://localhost:4000/api/events
  /// - Mobile: https://lucky-ly-api.onrender.com/api/events
  /// 
  /// Static getter để có thể gọi mà không cần instance
  static String get _baseUrl => '${ApiClient.getBaseUrl()}/api/events';

  /// Lấy JWT access token cho authentication
  /// 
  /// Quy tắc ưu tiên:
  /// 1. Nếu overrideToken được cung cấp và không rỗng → sử dụng overrideToken
  ///    (Dùng cho testing, hoặc khi cần force token khác)
  /// 2. Ngược lại, lấy token từ SharedPreferences (key: 'access_token')
  ///    (Token được lưu khi user login thành công)
  /// 
  /// Returns: Token string hoặc null nếu không tìm thấy
  /// 
  /// Debug: In ra token preview (15 ký tự đầu) để debug trong Logcat
  static Future<String?> _getToken({String? overrideToken}) async {
    if (overrideToken != null && overrideToken.isNotEmpty) return overrideToken;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    print('[Calendar] Token from SharedPreferences: ${token != null ? "${token.substring(0, 15)}..." : "NULL"}');
    return token;
  }

  /// Lấy danh sách tất cả events/notes từ backend (GET /api/events)
  /// 
  /// Tham số:
  /// - accessToken (optional): JWT token (nếu không cung cấp, lấy từ SharedPreferences)
  /// 
  /// Quy trình:
  /// 1. Lấy token (từ parameter hoặc SharedPreferences)
  /// 2. Nếu token null → trả về list rỗng (không logged in)
  /// 3. Send GET request với Authorization header
  /// 4. Timeout 15 giây nếu server không phản hồi
  /// 5. Xử lý response:
  ///    - Status 200 → parse JSON thành EventModel list
  ///    - Hỗ trợ 2 format JSON: List trực tiếp hoặc {data: []} / {events: []}
  ///    - Lỗi khác → trả về list rỗng
  /// 
  /// Returns: List<EventModel> (có thể empty nếu có lỗi hoặc không authenticated)
  /// 
  /// Error Handling: In log nhưng không throw exception - graceful degradation
  /// Fetch all events (user notes + holidays from backend)
  static Future<List<EventModel>> fetchEvents({String? accessToken}) async {
    try {
      final token = await _getToken(overrideToken: accessToken);
      if (token == null) {
        print('[Calendar] No token found - skipping fetch');
        return [];
      }

      final url = Uri.parse(_baseUrl);
      print('[Calendar] GET $url');

      /// Send GET request với Authorization header
      /// Timeout 15 giây nếu server không phản hồi
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      print('[Calendar] GET status: ${response.statusCode}');
      print('[Calendar] GET body preview: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');

      /// Parse response nếu thành công (status 200)
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List rawList = [];

        /// Hỗ trợ nhiều format JSON từ backend:
        /// 1. Direct list: [{...}, {...}]
        /// 2. Nested: {data: [{...}]} hoặc {events: [{...}]}
        if (data is List) {
          rawList = data;
        } else if (data is Map<String, dynamic>) {
          rawList = data['data'] ?? data['events'] ?? [];
        }

        /// Convert danh sách JSON thành List<EventModel>
        /// - Lọc chỉ các element là Map (bỏ qua null, primitives)
        /// - Map<String, dynamic>.from() để ensure typed map
        /// - EventModel.fromJson() để parse
        return rawList
            .where((e) => e is Map)
            .map((e) => EventModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }

      /// Nếu status không phải 200, in error log
      print('[Calendar] GET error: ${response.statusCode} - ${response.body}');
      return [];
    } catch (e) {
      /// Catch tất cả exception (timeout, network error, parse error, etc.)
      print('[Calendar] fetchEvents exception: $e');
      return [];
    }
  }

  /// Tạo event/note mới (POST /api/events)
  /// 
  /// Tham số:
  /// - title (bắt buộc): Tiêu đề event (được trim nếu > 200 ký tự)
  /// - date (bắt buộc): Ngày giờ sự kiện (convert sang ISO 8601)
  /// - note (optional): Ghi chú chi tiết về event
  /// - type (optional): Loại event (default: 'personal_note')
  /// - accessToken (optional): JWT token (nếu không cung cấp, lấy từ SharedPreferences)
  /// 
  /// Returns: Map với keys:
  /// - success (bool): true nếu tạo thành công, false nếu thất bại
  /// - event (EventModel): Object event vừa tạo (chỉ khi success=true)
  /// - error (String): Mô tả lỗi (chỉ khi success=false)
  /// 
  /// Quy trình:
  /// 1. Lấy token
  /// 2. Nếu token null → return error (not logged in)
  /// 3. Trim title nếu > 200 ký tự
  /// 4. Tạo JSON body và encode
  /// 5. Send POST request với Content-Type: application/json
  /// 6. Timeout 15 giây
  /// 7. Parse response và return result
  /// 
  /// Error Types:
  /// - No token: "Chưa đăng nhập..."
  /// - Server error (4xx/5xx): Lấy từ response JSON hoặc default message
  /// - Connection error: "Không thể kết nối server"
  /// - Timeout: "Server không phản hồi (timeout)"
  /// - Socket error: "Không thể kết nối đến server. Backend có đang chạy không?"
  /// - Parsing error: "Lỗi: ..."
  /// Create a new event/note
  static Future<Map<String, dynamic>> createEvent({
    required String title,
    required DateTime date,
    String? note,
    String type = 'personal_note',
    String? accessToken,
  }) async {
    try {
      /// Lấy token hoặc throw error
      final token = await _getToken(overrideToken: accessToken);
      if (token == null) {
        return {'success': false, 'error': 'Chưa đăng nhập. Vui lòng đăng nhập lại.'};
      }

      final url = Uri.parse(_baseUrl);
      
      /// Chuẩn bị JSON body
      /// - Trim title nếu > 200 ký tự (backend constraint)
      /// - note default về '' nếu null
      /// - date convert sang ISO 8601 format
      /// - type sử dụng default 'personal_note' nếu không specify
      final body = {
        'title': title.length > 200 ? '${title.substring(0, 200)}...' : title,
        'note': note ?? '',
        'date': date.toIso8601String(),
        'type': type,
      };

      print('[Calendar] POST $url');
      print('[Calendar] POST body: $body');

      /// Send POST request
      /// - Content-Type: application/json để báo body là JSON
      /// - Authorization: Bearer token cho authentication
      /// - Timeout 15 giây nếu server không phản hồi
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      print('[Calendar] POST status: ${response.statusCode}');
      print('[Calendar] POST response: ${response.body}');

      /// Success handling (status 200 hoặc 201)
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic>) {
            /// Tìm event object trong response
            /// Hỗ trợ formats: {event: {...}} hoặc {data: {...}}
            final rawEvent = data['event'] ?? data['data'];
            if (rawEvent != null && rawEvent is Map<String, dynamic>) {
              return {'success': true, 'event': EventModel.fromJson(rawEvent)};
            }
          }
          /// Nếu không tìm thấy event data nhưng response 200 → success mà không có object
          return {'success': true, 'event': null};
        } catch (_) {
          /// Nếu parse response thất bại nhưng status 200 → vẫn consider success
          return {'success': true, 'event': null};
        }
      }

      /// Error handling cho status khác 200/201
      /// Cố extract error message từ response JSON
      String errorMsg = 'Lỗi server (HTTP ${response.statusCode})';
      try {
        final errData = jsonDecode(response.body);
        if (errData is Map) {
          errorMsg = errData['message'] ?? errData['error'] ?? errorMsg;
        }
      } catch (_) {}

      return {'success': false, 'error': errorMsg};
    } on http.ClientException catch (e) {
      /// ClientException = network error hoặc socket error
      return {'success': false, 'error': 'Không thể kết nối server: $e'};
    } catch (e) {
      /// Catch tất cả exception khác và give specific error messages
      final msg = e.toString();
      
      /// Timeout error
      if (msg.contains('TimeoutException')) {
        return {'success': false, 'error': 'Server không phản hồi (timeout). Kiểm tra kết nối mạng.'};
      }
      
      /// Connection error (server offline hoặc incorrect URL)
      if (msg.contains('SocketException') || msg.contains('Connection refused')) {
        return {'success': false, 'error': 'Không thể kết nối đến server. Backend có đang chạy không?'};
      }
      
      /// Lỗi khác
      return {'success': false, 'error': 'Lỗi: $msg'};
    }
  }
}
