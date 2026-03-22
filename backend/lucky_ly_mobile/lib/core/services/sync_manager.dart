import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class SyncManager {
  static String get _syncApiUrl {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux) {
      return 'http://localhost:4000/api/sync';
    }
    return 'http://10.0.2.2:4000/api/sync';
  }

  /// Push những thay đổi offline lên Server (MongoDB)
  static Future<bool> _pushTable(String tableName, String endpoint, String idField) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final unsynced = await dbHelper.getUnsyncedRecords(tableName);

      if (unsynced.isEmpty) return true;

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$_syncApiUrl/push/$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'records': unsynced}),
      );

      if (response.statusCode == 200) {
        final idsToMark = unsynced.map((e) => e[idField].toString()).toList();
        await dbHelper.markAsSynced(tableName, idField, idsToMark);
        return true;
      }
      return false;
    } catch (e) {
      print('Push Data Error for $tableName: $e');
      return false;
    }
  }

  /// Push những thay đổi offline lên Server
  static Future<bool> pushData() async {
    bool avSync = await _pushTable('avatars', 'avatars', 'localId');
    bool usSync = await _pushTable('users', 'users', 'userId');
    bool dsSync = await _pushTable('designs', 'designs', 'localId');
    return avSync && usSync && dsSync;
  }

  /// Pull những thay đổi từ Server về local SQLite
  static Future<bool> pullData() async {
     try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final lastSyncStr = prefs.getString('last_sync_time');
      
      if (token == null) return false;

      String url = '$_syncApiUrl/pull/all';
      if (lastSyncStr != null) {
        url += '?lastSyncTime=$lastSyncStr';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final dbHelper = DatabaseHelper.instance;

        // Xử lý pull avatars
        final avatars = data['data']['avatars'] as List? ?? [];
        for (var record in avatars) {
          record['isSync'] = 1;
          await dbHelper.insertAvatar(record);
        }

        // Xử lý pull users
        final users = data['data']['users'] as List? ?? [];
        for (var record in users) {
          record['isSync'] = 1;
          await dbHelper.insertUser(record);
        }

        // Xử lý pull designs
        final designs = data['data']['designs'] as List? ?? [];
        for (var record in designs) {
          record['isSync'] = 1;
          await dbHelper.insertDesign(record);
        }

        // Cập nhật lastSyncTime
        if (data['timestamp'] != null) {
          await prefs.setString('last_sync_time', data['timestamp']);
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Pull Data Error: $e');
      return false;
    }
  }

  /// Nút bấm đồng bộ thủ công
  static Future<bool> manualSync() async {
    bool pushSuccess = await pushData();
    bool pullSuccess = await pullData();
    return pushSuccess && pullSuccess;
  }
}
