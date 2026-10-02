import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/api_config.dart';

class AuthService {
  static String get baseUrl => '${ApiConfig.baseUrl}/auth';

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        if (data['session'] != null) {
          await prefs.setString('token', data['session']['access_token']);
        }
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to login'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> register(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final prefs = await SharedPreferences.getInstance();
        if (data['session'] != null) {
          await prefs.setString('token', data['session']['access_token']);
        }
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to register'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  static Future<bool> getRegistrationStatus() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/registration-status'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['enabled'] ?? true;
      }
      return true;
    } catch (e) {
      return true;
    }
  }

  static Future<void> updateFcmToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('token');
      if (userToken == null) return;

      await http.post(
        Uri.parse('$baseUrl/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
        body: jsonEncode({'fcmToken': token}),
      );
    } catch (e) {
      print('Failed to update FCM token: $e');
    }
  }
}
