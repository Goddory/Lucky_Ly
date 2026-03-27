import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_provider.dart';

class StoreProvider extends ChangeNotifier {
  final AuthProvider _authProvider;
  
  List<dynamic> _inventory = [];
  List<dynamic> _combos = [];
  Map<String, dynamic>? _overview;
  List<dynamic> _revenueData = [];
  bool _isLoading = false;

  StoreProvider(this._authProvider);

  List<dynamic> get inventory => _inventory;
  List<dynamic> get combos => _combos;
  Map<String, dynamic>? get overview => _overview;
  List<dynamic> get revenueData => _revenueData;
  bool get isLoading => _isLoading;

  Future<void> fetchInventory() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _authProvider.apiClient.get('/api/store/inventory');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _inventory = data['items'] ?? [];
      }
    } catch (e) {
      debugPrint('Error fetching inventory: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchOverview() async {
    try {
      final res = await _authProvider.apiClient.get('/api/store/overview');
      if (res.statusCode == 200) {
        _overview = jsonDecode(res.body);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching overview: $e');
    }
  }

  Future<void> fetchRevenue() async {
    try {
      final res = await _authProvider.apiClient.get('/api/store/revenue');
      if (res.statusCode == 200) {
        _revenueData = jsonDecode(res.body);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching revenue: $e');
    }
  }

  Future<void> fetchCombos() async {
    try {
      final res = await _authProvider.apiClient.get('/api/store/combos');
      if (res.statusCode == 200) {
        _combos = jsonDecode(res.body)['combos'] ?? [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching combos: $e');
    }
  }

  Future<bool> addItem({
    required String name,
    required String category,
    required double price,
    String? description,
    String? effectType,
    String? filePath,
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    try {
      final uri = Uri.parse('${_authProvider.apiClient.baseUrl}/api/store/inventory');
      final request = http.MultipartRequest('POST', uri);
      
      request.headers.addAll({
        'Authorization': 'Bearer ${_authProvider.accessToken}',
      });

      request.fields['itemName'] = name;
      request.fields['category'] = category;
      request.fields['price'] = price.toString();
      request.fields['description'] = description ?? '';
      request.fields['effectType'] = effectType ?? 'none';
      request.fields['stock'] = '100';

      if (kIsWeb) {
        if (fileBytes != null && fileName != null) {
          request.files.add(http.MultipartFile.fromBytes(
            'asset',
            fileBytes,
            filename: fileName,
          ));
        }
      } else {
        if (filePath != null) {
          request.files.add(await http.MultipartFile.fromPath('asset', filePath));
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        await fetchInventory();
        return true;
      }
    } catch (e) {
      debugPrint('Error adding item multipart: $e');
    }
    return false;
  }

  Future<bool> updateItem(int id, Map<String, dynamic> data) async {
    try {
      final res = await _authProvider.apiClient.put('/api/store/inventory/$id', data);
      if (res.statusCode == 200) {
        await fetchInventory();
        return true;
      }
    } catch (e) {
      debugPrint('Error updating item: $e');
    }
    return false;
  }

  Future<bool> deleteItem(int id) async {
    try {
      final res = await _authProvider.apiClient.delete('/api/store/inventory/$id');
      if (res.statusCode == 200) {
        _inventory.removeWhere((item) => item['id'] == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting item: $e');
    }
    return false;
  }

  Future<void> runApriori() async {
    try {
      await _authProvider.apiClient.get('/api/store/apriori');
      await fetchCombos();
    } catch (e) {
      debugPrint('Error running apriori: $e');
    }
  }
}
