import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// ApiClient - HTTP client service để giao tiếp với Lucky Ly Backend API
/// 
/// Tính năng chính:
/// 1. HTTP Methods - GET, POST, PUT, PATCH, DELETE với automatic headers
/// 2. Authentication - JWT Bearer token management (add/update token)
/// 3. Platform Detection - Tự động chọn URL base theo platform:
///    - Web (localhost:4000)
///    - Android/iOS (production: https://lucky-ly-api.onrender.com)
///    - Environment Variable override (--dart-define=API_BASE_URL=...)
/// 4. Debug Logging - In ra request URL và method bằng debugPrint
/// 5. Token Normalization - Trim whitespace, xử lý null/empty tokens
class ApiClient {
  /// URL cơ sở của API server (ví dụ: http://localhost:4000 hoặc https://api.lucky-ly.com)
  final String baseUrl;
  
  /// JWT access token được lưu trữ để gửi kèm với token header (Authorization: Bearer token)
  String? _accessToken;

  /// Constructor của ApiClient
  /// 
  /// Tham số:
  /// - baseUrl (bắt buộc): URL cơ sở của API
  /// - accessToken (optional): JWT token ban đầu (thường từ SharedPreferences sau khi login)
  /// 
  /// Token sẽ được normalize (vào trim whitespace, xử lý empty)
  ApiClient({required this.baseUrl, String? accessToken}) : _accessToken = _normalizeToken(accessToken);

  /// Normalize token - xử lý null, whitespace, và empty strings
  /// 
  /// Logic:
  /// 1. Nếu token là null → trả về null
  /// 2. Trim whitespace (\s) đầu và cuối
  /// 3. Nếu sau trim vẫn trống → trả về null
  /// 4. Hợp lệ (valid token) → trả về token đã trim
  /// 
  /// Mục đích: Từ chối token không hợp lệ được lưu từ API hoặc localStorage
  static String? _normalizeToken(String? token) {
    if (token == null) return null;
    final trimmed = token.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Cập nhật token sau khi login thành công
  /// 
  /// Thời điểm gọi:
  /// - Sau khi user login thành công, nhận token từ backend
  /// - Token sẽ được lưu vào SharedPreferences
  /// - Gọi updateToken() để cập nhật instance ApiClient
  /// 
  /// Token sẽ được tự động thêm vào Authorization header của tất cả request sau đó
  void updateToken(String? token) {
    _accessToken = _normalizeToken(token);
  }

  /// Tạo HTTP headers được định kì̀nh cho tất cả API requests
  /// 
  /// Headers bao gồm:
  /// - Content-Type: application/json (có luôn)
  /// - Authorization: Bearer <token> (chỉ thêm nếu user đã login)
  /// 
  /// Mục đích:
  /// - "Content-Type" báo cáo body là JSON
  /// - "Authorization" gửi Bearer token cho auth
  /// - Nằm conditional (if) chỉ thêm Authorization nếu _accessToken không null
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  /// Thực hiện HTTP GET request
  /// 
  /// Tham số:
  /// - path: Endpoint path (ví dụ: "/api/users/profile")
  /// 
  /// Làm việc:
  /// 1. Kết hợp baseUrl + path để tạo full URL
  /// 2. Log request bằng debugPrint (chỉ show khi debug mode)
  /// 3. Gửi GET request với automatic headers
  /// 
  /// Returns: http.Response - response từ server (status code, body, headers)
  Future<http.Response> get(String path) async {
    final url = Uri.parse('$baseUrl$path');
    debugPrint('GET $url');
    return http.get(url, headers: _headers);
  }

  /// Thực hiện HTTP POST request
  /// 
  /// Tham số:
  /// - path: Endpoint path (ví dụ: "/api/events")
  /// - body: Data cần gửi (Map/Object được encode thành JSON)
  /// 
  /// Làm việc:
  /// 1. Kết hợp baseUrl + path
  /// 2. Encode body thành JSON string (jsonEncode)
  /// 3. Log request
  /// 4. Gửi POST với headers và JSON body
  /// 
  /// Use cases: Tạo resource mới (users, events, posts, etc.)
  Future<http.Response> post(String path, dynamic body) async {
    final url = Uri.parse('$baseUrl$path');
    debugPrint('POST $url');
    return http.post(url, headers: _headers, body: jsonEncode(body));
  }

  /// Thực hiện HTTP PUT request (thay thế toàn bộ resource)
  /// 
  /// Tham số:
  /// - path: Endpoint path (ví dụ: "/api/events/:id")
  /// - body: Dữ liệu cập nhật toàn bộ ống
  /// 
  /// PUT vs PATCH:
  /// - PUT: Thay thế toàn bộ resource (send full object)
  /// - PATCH: Chỉ cập nhật một số fields (send partial object)
  /// 
  /// Use cases: Cập nhật toàn bộ event hoặc user profile
  Future<http.Response> put(String path, dynamic body) async {
    final url = Uri.parse('$baseUrl$path');
    debugPrint('PUT $url');
    return http.put(url, headers: _headers, body: jsonEncode(body));
  }

  /// Thực hiện HTTP PATCH request (cập nhật một phần resource)
  /// 
  /// Tham số:
  /// - path: Endpoint path (ví dụ: "/api/events/:id")
  /// - body: Chỉ các fields cần cập nhật (partial object)
  /// 
  /// Thường dùng hơn PUT vì:
  /// - Chỉ gửi dữ liệu thay đổi (tiết băng dữ liệu)
  /// - Nếu backend không nhận data nào, backend giữ giá trị cũ
  /// 
  /// Use cases: Cập nhật chỉ title hoặc note của event
  Future<http.Response> patch(String path, dynamic body) async {
    final url = Uri.parse('$baseUrl$path');
    debugPrint('PATCH $url');
    return http.patch(url, headers: _headers, body: jsonEncode(body));
  }

  /// Thực hiện HTTP DELETE request (xóa resource)
  /// 
  /// Tham số:
  /// - path: Endpoint path (ví dụ: "/api/events/:id")
  /// 
  /// Làm việc:
  /// 1. Kết hợp baseUrl + path
  /// 2. Log request
  /// 3. Gửi DELETE với headers (không có body)
  /// 
  /// Use cases: Xóa event, user, design, etc.
  Future<http.Response> delete(String path) async {
    final url = Uri.parse('$baseUrl$path');
    debugPrint('DELETE $url');
    return http.delete(url, headers: _headers);
  }

  /// Lấy URL cơ sở API tương ứng với platform
  /// 
  /// Quy tắm ưu tiên (thứ tự xử lý):
  /// 1. Environment Variable (--dart-define=API_BASE_URL=...)
  ///    - Dùng khi cần override base URL cho dev/staging
  ///    - Ví dụ: flutter run --dart-define=API_BASE_URL=http://10.0.0.5:4000
  /// 
  /// 2. Web Platform
  ///    - Flutter web chạy trên localhost lúc dev
  ///    - URL: http://localhost:4000
  /// 
  /// 3. Mobile Platforms (Android, iOS)
  ///    - Sản phẩm: https://lucky-ly-api.onrender.com (production API)
  ///    - Development: Có thể override bằng env variable
  /// 
  /// 4. Default fallback
  ///    - Desktop (Windows/Linux/macOS): http://localhost:4000
  /// 
  /// Làm việc:
  /// - String.fromEnvironment() lấy giá trị từ compile-time environment variable
  /// - kIsWeb là Flutter constant kiểm tra web platform
  /// - defaultTargetPlatform lấy current platform (Android, iOS, Windows, etc.)
  static String getBaseUrl() {
    /// Đây là biến compile-time, không có thể override tại runtime
    const fromEnv = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv;

    /// Web platform - dev ngăn trên localhost
    if (kIsWeb) return 'http://localhost:4000';
    
    /// Mobile platforms - sử dụng production API
    if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      return 'https://lucky-ly-api.onrender.com';
    }
    
    /// Desktop (Windows/Linux/macOS) hoặc fallback khác
    return 'http://localhost:4000';
  }
}
