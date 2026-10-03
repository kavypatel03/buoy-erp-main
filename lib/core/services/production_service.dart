import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ProductionService {
  static String get baseUrl => '${ApiConfig.baseUrl}/production';

  static Future<Map<String, dynamic>> getOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return {'success': false, 'error': 'Not authenticated'};

      final response = await http.get(
        Uri.parse('$baseUrl/orders'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createOrder(String productName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return {'success': false, 'error': 'Not authenticated'};

      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'product_name': productName}),
      );
      return _handleResponse(response, isSuccessCode: (code) => code == 200 || code == 201);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> addProcessLog(String orderId, Map<String, dynamic> logData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return {'success': false, 'error': 'Not authenticated'};

      final response = await http.post(
        Uri.parse('$baseUrl/orders/$orderId/log'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode(logData),
      );
      return _handleResponse(response, isSuccessCode: (code) => code == 200 || code == 201);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateProcessLog(String logId, double outputQty) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return {'success': false, 'error': 'Not authenticated'};

      final response = await http.put(
        Uri.parse('$baseUrl/logs/$logId'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'output_qty': outputQty}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getWastageReport() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return {'success': false, 'error': 'Not authenticated'};

      final response = await http.get(
        Uri.parse('$baseUrl/wastage-report'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response, {bool Function(int)? isSuccessCode}) {
    final bool isSuccess = isSuccessCode != null ? isSuccessCode(response.statusCode) : response.statusCode == 200;
    try {
      if (isSuccess) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final errorData = jsonDecode(response.body);
        return {'success': false, 'error': errorData['error'] ?? 'Request failed with status ${response.statusCode}'};
      }
    } catch (e) {
      if (isSuccess) {
        return {'success': true, 'data': null};
      } else {
        return {'success': false, 'error': 'Server Error (${response.statusCode}): ${response.body.length > 100 ? response.body.substring(0, 100) + '...' : response.body}'};
      }
    }
  }
}
