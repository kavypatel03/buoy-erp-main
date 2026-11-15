import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ProductionService {
  static String get baseUrl => '${ApiConfig.baseUrl}/production';

  static String get exportExcelUrl => '$baseUrl/wastage-report/export/excel';
  static String get exportPdfUrl => '$baseUrl/wastage-report/export/pdf';

  static Future<String> getExportExcelUrlWithAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return '$exportExcelUrl?token=$token';
  }

  static Future<String> getExportPdfUrlWithAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return '$exportPdfUrl?token=$token';
  }

  static List<dynamic>? _cachedProductTypes;

  static Future<Map<String, dynamic>> getProductTypes({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedProductTypes != null && _cachedProductTypes!.isNotEmpty) {
      // Trigger a silent background update
      _refreshProductTypesInBackground();
      return {'success': true, 'data': _cachedProductTypes};
    }
    return _fetchProductTypesFromNetwork();
  }

  static Future<void> _refreshProductTypesInBackground() async {
    try {
      final res = await _fetchProductTypesFromNetwork();
      if (res['success'] && res['data'] is List) {
        _cachedProductTypes = res['data'];
      }
    } catch (_) {}
  }

  static Future<Map<String, dynamic>> _fetchProductTypesFromNetwork() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return {'success': false, 'error': 'Not authenticated'};

      final response = await http.get(
        Uri.parse('$baseUrl/product-types'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      );
      final handled = _handleResponse(response);
      if (handled['success'] && handled['data'] is List) {
        _cachedProductTypes = handled['data'];
      }
      return handled;
    } catch (e) {
      if (_cachedProductTypes != null) {
        return {'success': true, 'data': _cachedProductTypes};
      }
      return {'success': false, 'error': e.toString()};
    }
  }

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

  static Future<Map<String, dynamic>> createOrder(String productName, {String? productId, String? batchCode}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return {'success': false, 'error': 'Not authenticated'};

      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({
          'product_name': productName,
          if (productId != null) 'product_id': productId,
          if (batchCode != null) 'batch_code': batchCode
        }),
      );
      return _handleResponse(response, isSuccessCode: (code) => code == 200 || code == 201);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> completeOrder(String orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return {'success': false, 'error': 'Not authenticated'};

      final response = await http.post(
        Uri.parse('$baseUrl/orders/$orderId/complete'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      );
      return _handleResponse(response);
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

  static Future<Map<String, dynamic>> getWastageReport({String? startDate, String? endDate, String? horizon}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return {'success': false, 'error': 'Not authenticated'};

      final queryParams = <String, String>{};
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      if (horizon != null) queryParams['horizon'] = horizon;

      final uri = Uri.parse('$baseUrl/wastage-report').replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await http.get(
        uri,
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
