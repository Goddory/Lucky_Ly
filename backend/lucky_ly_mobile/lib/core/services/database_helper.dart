export '../database/database_helper.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  DatabaseHelper._init();

  Future<List<Map<String, dynamic>>> getUnsyncedRecords(String table) async {
    return [];
  }

  Future<void> markAsSynced(String table, String idField, List<String> ids) async {}

  Future<void> insertAvatar(Map<String, dynamic> data) async {}

  Future<void> insertUser(Map<String, dynamic> data) async {}

  Future<void> insertDesign(Map<String, dynamic> data) async {}
}
