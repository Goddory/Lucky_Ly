import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event_model.dart';
import 'api_client.dart';

class CalendarApiService {
  static String get _baseUrl => '${ApiClient.getBaseUrl()}/api/events';

  static Future<String?> _getToken({String? overrideToken}) async {
    if (overrideToken != null && overrideToken.isNotEmpty) return overrideToken;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    print('[Calendar] Token from SharedPreferences: ${token != null ? "${token.substring(0, 15)}..." : "NULL"}');
    return token;
  }

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

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      print('[Calendar] GET status: ${response.statusCode}');
      print('[Calendar] GET body preview: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List rawList = [];

        if (data is List) {
          rawList = data;
        } else if (data is Map<String, dynamic>) {
          rawList = data['data'] ?? data['events'] ?? [];
        }

        return rawList
            .where((e) => e is Map)
            .map((e) => EventModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }

      print('[Calendar] GET error: ${response.statusCode} - ${response.body}');
      return [];
    } catch (e) {
      print('[Calendar] fetchEvents exception: $e');
      return [];
    }
  }

  /// Create a new event/note
  static Future<Map<String, dynamic>> createEvent({
    required String title,
    required DateTime date,
    String? note,
    String type = 'personal_note',
    String? accessToken,
  }) async {
    try {
      final token = await _getToken(overrideToken: accessToken);
      if (token == null) {
        return {'success': false, 'error': 'Chưa đăng nhập. Vui lòng đăng nhập lại.'};
      }

      final url = Uri.parse(_baseUrl);
      final body = {
        'title': title.length > 200 ? '${title.substring(0, 200)}...' : title,
        'note': note ?? '',
        'date': date.toIso8601String(),
        'type': type,
      };

      print('[Calendar] POST $url');
      print('[Calendar] POST body: $body');

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

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic>) {
            final rawEvent = data['event'] ?? data['data'];
            if (rawEvent != null && rawEvent is Map<String, dynamic>) {
              return {'success': true, 'event': EventModel.fromJson(rawEvent)};
            }
          }
          return {'success': true, 'event': null};
        } catch (_) {
          return {'success': true, 'event': null};
        }
      }

      String errorMsg = 'Lỗi server (HTTP ${response.statusCode})';
      try {
        final errData = jsonDecode(response.body);
        if (errData is Map) {
          errorMsg = errData['message'] ?? errData['error'] ?? errorMsg;
        }
      } catch (_) {}

      return {'success': false, 'error': errorMsg};
    } on http.ClientException catch (e) {
      return {'success': false, 'error': 'Không thể kết nối server: $e'};
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('TimeoutException')) {
        return {'success': false, 'error': 'Server không phản hồi (timeout). Kiểm tra kết nối mạng.'};
      }
      if (msg.contains('SocketException') || msg.contains('Connection refused')) {
        return {'success': false, 'error': 'Không thể kết nối đến server. Backend có đang chạy không?'};
      }
      return {'success': false, 'error': 'Lỗi: $msg'};
    }
  }
}
