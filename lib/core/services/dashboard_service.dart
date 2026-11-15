import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class DashboardService {
  static String get baseUrl => '${ApiConfig.baseUrl}/dashboard';

  // ─── In-Memory Cache (Instant Replay, Zero Waiting) ───
  static Map<String, dynamic>? _cachedSummary;
  static Map<String, dynamic>? get cachedSummary => _cachedSummary;

  static Future<Map<String, dynamic>> getSummary({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedSummary != null) {
      _refreshInBackground();
      return {'success': true, 'data': _cachedSummary};
    }
    return _fetchFromNetwork();
  }

  static Future<void> _refreshInBackground() async {
    try {
      final res = await _fetchFromNetwork();
      if (res['success'] && res['data'] is Map<String, dynamic>) {
        _cachedSummary = res['data'];
      }
    } catch (_) {}
  }

  static Future<Map<String, dynamic>> _fetchFromNetwork() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return {'success': false, 'error': 'Not authenticated'};

      final response = await http
          .get(
            Uri.parse('$baseUrl/summary'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          _cachedSummary = data;
        }
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['error'] ?? 'Failed to load summary'};
      }
    } catch (e) {
      if (_cachedSummary != null) {
        return {'success': true, 'data': _cachedSummary};
      }
      return {'success': false, 'error': e.toString()};
    }
  }
}
