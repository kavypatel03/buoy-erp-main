import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class EmployeeService {
  static String get baseUrl => '${ApiConfig.baseUrl}/employees';

  static Future<Map<String, dynamic>> getEmployees() async {
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

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createEmployee(Map<String, dynamic> employeeData) async {
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
        body: jsonEncode(employeeData),
      );

      return _handleResponse(response, isSuccessCode: (code) => code == 200 || code == 201);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> editEmployee(String employeeId, Map<String, dynamic> employeeData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) return {'success': false, 'error': 'Not authenticated'};

      final response = await http.put(
        Uri.parse('$baseUrl/$employeeId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(employeeData),
      );

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> paySalary(String employeeId, double amount, String method) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) return {'success': false, 'error': 'Not authenticated'};

      final response = await http.post(
        Uri.parse('$baseUrl/$employeeId/pay-salary'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': amount,
          'payment_method': method
        }),
      );

      return _handleResponse(response, isSuccessCode: (code) => code == 200 || code == 201);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> clockIn(String employeeId, {DateTime? time}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) return {'success': false, 'error': 'Not authenticated'};

      final body = time != null ? jsonEncode({'time': time.toIso8601String()}) : null;

      final response = await http.post(
        Uri.parse('$baseUrl/$employeeId/clock-in'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      return _handleResponse(response, isSuccessCode: (code) => code == 200 || code == 201);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> clockOut(String employeeId, {DateTime? time}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) return {'success': false, 'error': 'Not authenticated'};

      final body = time != null ? jsonEncode({'time': time.toIso8601String()}) : null;

      final response = await http.post(
        Uri.parse('$baseUrl/$employeeId/clock-out'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      return _handleResponse(response, isSuccessCode: (code) => code == 200 || code == 201);
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
      // If response body is not JSON (e.g. HTML error page or empty)
      if (isSuccess) {
        return {'success': true, 'data': null};
      } else {
        return {'success': false, 'error': 'Server Error (${response.statusCode}): ${response.body.length > 100 ? response.body.substring(0, 100) + '...' : response.body}'};
      }
    }
  }
}
