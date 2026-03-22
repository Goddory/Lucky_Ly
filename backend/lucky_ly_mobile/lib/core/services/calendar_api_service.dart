import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event_model.dart';

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class CalendarApiService {
  static String get _baseUrl {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux) {
      return 'http://localhost:4000/api/events';
    }
    return 'http://10.0.2.2:4000/api/events';
  }

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
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((e) => EventModel.fromJson(e))
              .toList();
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
      
      if (token == null) return null;

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'title': title,
          'date': date.toIso8601String(),
          'type': type,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return EventModel.fromJson(data['data']);
        }
      }
      print('Create Event Error: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('Create Event Exception: $e');
      return null;
    }
  }
}
