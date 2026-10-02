import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/api_config.dart';

class ProfileService {
  static String get baseUrl => '${ApiConfig.baseUrl}/profile';

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(baseUrl), headers: headers);
      
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'error': data['error'] ?? 'Failed to load profile'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse(baseUrl),
        headers: headers,
        body: jsonEncode(profileData),
      );
      
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'error': data['error'] ?? 'Failed to update profile'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }
}
