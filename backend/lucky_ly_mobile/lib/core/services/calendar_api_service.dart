import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event_model.dart';

class CalendarApiService {
  static final String _baseUrl =
      const String.fromEnvironment('API_BASE_URL', defaultValue: '').isNotEmpty
      ? '${const String.fromEnvironment('API_BASE_URL')}/api/events'
      : (kIsWeb ? 'http://localhost:4000/api/events' : 
        (defaultTargetPlatform == TargetPlatform.android ? 'http://10.0.2.2:4000/api/events' : 'http://localhost:4000/api/events'));

  static Future<List<EventModel>> fetchEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      if (token == null) return [];

      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map(EventModel.fromJson)
              .toList();
        }

        if (data is Map<String, dynamic>) {
          final rawEvents = data['data'] ?? data['events'];
          if (rawEvents is List) {
            return rawEvents
                .whereType<Map<String, dynamic>>()
                .map(EventModel.fromJson)
                .toList();
          }
        }
      }
      print('Fetch Events Error: ${response.statusCode} - ${response.body}');
      return [];
    } catch (e) {
      print('Fetch Events Exception: $e');
      return [];
    }
  }

  static Future<EventModel?> createEvent(String title, DateTime date, {String type = 'personal_note'}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      if (token == null) {
        print('Create Event Error: No access token found');
        return null;
      }

      final url = Uri.parse(_baseUrl);
      print('Create Event URL: $url');
      print('Create Event Token: ${token.substring(0, 20)}...');
      
      final body = {
        'title': title,
        'date': date.toIso8601String(),
        'type': type,
      };
      print('Create Event Body: $body');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      print('Create Event Status: ${response.statusCode}');
      print('Create Event Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = jsonDecode(response.body);
          
          // Backend returns { message: "...", event: {...} }
          if (data is Map<String, dynamic>) {
            final rawEvent = data['event'] ?? data['data'];
            
            if (rawEvent != null && rawEvent is Map<String, dynamic>) {
              print('Parsed event: $rawEvent');
              return EventModel.fromJson(rawEvent);
            } else {
              print('Create Event Error: Could not find event in response. Keys: ${data.keys}');
            }
          }
          return null;
        } catch (parseError) {
          print('Create Event Parse Error: $parseError');
          return null;
        }
      } else {
        print('Create Event Error: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Create Event Exception: $e');
      return null;
    }
  }
}
