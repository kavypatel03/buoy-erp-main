import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/api_config.dart';

class AuthService {
  static String get baseUrl => '${ApiConfig.baseUrl}/auth';

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        if (data['session'] != null) {
          final accessToken = data['session']['access_token'];
          await prefs.setString('token', accessToken);
          
          // Auto-sync cached FCM token immediately upon login
          final cachedFcm = prefs.getString('fcm_token') ?? prefs.getString('pending_fcm_token');
          if (cachedFcm != null && cachedFcm.isNotEmpty) {
            http.post(
              Uri.parse('$baseUrl/fcm-token'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $accessToken',
              },
              body: jsonEncode({'fcmToken': cachedFcm, 'deviceType': 'android'}),
            ).catchError((_) => http.Response('', 500));
          }
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
      final response = await http
          .post(
            Uri.parse('$baseUrl/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

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
      final response = await http
          .get(Uri.parse('$baseUrl/registration-status'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['enabled'] ?? true;
      }
      return true;
    } catch (e) {
      // On timeout or any network error, default to enabled so the page isn't stuck
      return true;
    }
  }

  static Future<void> updateFcmToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
      final userToken = prefs.getString('token');

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (userToken != null && userToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $userToken';
      }

      await http.post(
        Uri.parse('$baseUrl/fcm-token'),
        headers: headers,
        body: jsonEncode({'fcmToken': token, 'deviceType': 'android'}),
      );
    } catch (e) {
      // Non-blocking log
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('saved_email');
    await prefs.remove('saved_password');
    await prefs.setBool('rememberMe', false);
  }
}
