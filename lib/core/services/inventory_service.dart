import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class InventoryService {
  static String get baseUrl => '${ApiConfig.baseUrl}/items';

  // ─── In-Memory Cache (Instant Replay, Zero Waiting) ───
  static List<dynamic>? _cachedItems;
  static List<dynamic>? get cachedItems => _cachedItems;

  static Future<Map<String, dynamic>> getItems({bool forceRefresh = false}) async {
    // If cached, return immediately for instant render, and refresh quietly in background
    if (!forceRefresh && _cachedItems != null && _cachedItems!.isNotEmpty) {
      _refreshInBackground();
      return {'success': true, 'data': _cachedItems};
    }
    return _fetchFromNetwork();
  }

  static Future<void> _refreshInBackground() async {
    try {
      final res = await _fetchFromNetwork();
      if (res['success'] && res['data'] is List) {
        _cachedItems = res['data'];
      }
    } catch (_) {}
  }

  static Future<Map<String, dynamic>> _fetchFromNetwork() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) return {'success': false, 'error': 'Not authenticated'};

      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          _cachedItems = data;
        }
        return {'success': true, 'data': data};
      } else {
        final errorData = jsonDecode(response.body);
        return {'success': false, 'error': errorData['error'] ?? 'Failed to load items'};
      }
    } catch (e) {
      // If network fails but cache exists, gracefully fallback to cache
      if (_cachedItems != null) {
        return {'success': true, 'data': _cachedItems};
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createItem(Map<String, dynamic> itemData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) return {'success': false, 'error': 'Not authenticated'};

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(itemData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Prepend to cache
        if (_cachedItems != null && data != null) {
          _cachedItems!.insert(0, data);
        }
        return {'success': true, 'data': data};
      } else {
        final errorData = jsonDecode(response.body);
        return {'success': false, 'error': errorData['error'] ?? 'Failed to create item'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateItem(String id, Map<String, dynamic> itemData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) return {'success': false, 'error': 'Not authenticated'};

      final response = await http.put(
        Uri.parse('$baseUrl/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(itemData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Update item in cache
        if (_cachedItems != null && data != null) {
          final idx = _cachedItems!.indexWhere((it) => it['id'] == id);
          if (idx != -1) {
            _cachedItems![idx] = data;
          }
        }
        return {'success': true, 'data': data};
      } else {
        final errorData = jsonDecode(response.body);
        return {'success': false, 'error': errorData['error'] ?? 'Failed to update item'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
