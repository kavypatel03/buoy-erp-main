import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class NotificationService {
  static String get baseUrl => '${ApiConfig.baseUrl}/notifications';

  static Future<Map<String, dynamic>> getNotifications() async {
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
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['notifications']};
      } else {
        final errorData = jsonDecode(response.body);
        return {'success': false, 'error': errorData['error'] ?? 'Failed to load notifications'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> markAsRead(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) return {'success': false, 'error': 'Not authenticated'};

      final response = await http.post(
        Uri.parse('$baseUrl/$notificationId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        final errorData = jsonDecode(response.body);
        return {'success': false, 'error': errorData['error'] ?? 'Failed to mark as read'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
