// Dummy DataBase Helper for Web Compilation
class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  Future<List<Map<String, dynamic>>> getUnsyncedRecords(String tableName) async {
    return [];
  }

  Future<void> markAsSynced(String tableName, String idField, List<String> ids) async {}

  Future<void> insertAvatar(Map<String, dynamic> record) async {}
  Future<void> insertUser(Map<String, dynamic> record) async {}
  Future<void> insertDesign(Map<String, dynamic> record) async {}
}
