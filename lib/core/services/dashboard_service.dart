import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class DashboardService {
  static String get baseUrl => '${ApiConfig.baseUrl}/dashboard';

  static Future<Map<String, dynamic>> getSummary() async {
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
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['error'] ?? 'Failed to load summary'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
