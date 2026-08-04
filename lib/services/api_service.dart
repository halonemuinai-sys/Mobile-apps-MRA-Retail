import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'sales_service.dart';

class ApiService {
  static String get baseUrl => '${SalesService.apiBaseUrl}/api/mobile';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_bearer_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_bearer_token', token);
  }

  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// 1. Mobile Login via Proxmox API
  static Future<Map<String, dynamic>?> login(
    String name,
    String pin, {
    String store = '',
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'advisorName': name, 'pin': pin, 'store': store}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['token'] != null) {
          await saveToken(data['token']);
          return data;
        }
      }
    } catch (e) {
      print('ApiService login error: $e');
    }
    return null;
  }

  /// 2. Dashboard Data Bundle from Proxmox Server
  static Future<Map<String, dynamic>?> getDashboard({
    String store = '',
    String advisor = '',
    int? month,
    int? year,
  }) async {
    try {
      final headers = await getHeaders();
      final uri = Uri.parse('$baseUrl/dashboard').replace(
        queryParameters: {
          if (store.isNotEmpty) 'store': store,
          if (advisor.isNotEmpty) 'advisor': advisor,
          if (month != null) 'month': month.toString(),
          if (year != null) 'year': year.toString(),
        },
      );
      final res = await http.get(uri, headers: headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) return data['data'];
      }
    } catch (e) {
      print('ApiService getDashboard error: $e');
    }
    return null;
  }

  /// 3. Leaderboard & Store Comparison from Proxmox Server
  static Future<Map<String, dynamic>?> getLeaderboard({
    String store = '',
    int? month,
    int? year,
  }) async {
    try {
      final headers = await getHeaders();
      final uri = Uri.parse('$baseUrl/leaderboard').replace(
        queryParameters: {
          if (store.isNotEmpty) 'store': store,
          if (month != null) 'month': month.toString(),
          if (year != null) 'year': year.toString(),
        },
      );
      final res = await http.get(uri, headers: headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) return data['data'];
      }
    } catch (e) {
      print('ApiService getLeaderboard error: $e');
    }
    return null;
  }

  /// 4. Customer Segmentation Data from Proxmox Server
  static Future<Map<String, dynamic>?> getSegmentation({
    String store = '',
    String segment = '',
    String search = '',
    int page = 1,
  }) async {
    try {
      final headers = await getHeaders();
      final uri = Uri.parse('$baseUrl/segmentation').replace(
        queryParameters: {
          if (store.isNotEmpty) 'store': store,
          if (segment.isNotEmpty) 'segment': segment,
          if (search.isNotEmpty) 'search': search,
          'page': page.toString(),
        },
      );
      final res = await http.get(uri, headers: headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) return data['data'];
      }
    } catch (e) {
      print('ApiService getSegmentation error: $e');
    }
    return null;
  }

  /// 5. Reports & Traffic Data from Proxmox Server
  static Future<Map<String, dynamic>?> getReports({
    String store = '',
    int? month,
    int? year,
  }) async {
    try {
      final headers = await getHeaders();
      final uri = Uri.parse('$baseUrl/reports').replace(
        queryParameters: {
          if (store.isNotEmpty) 'store': store,
          if (month != null) 'month': month.toString(),
          if (year != null) 'year': year.toString(),
        },
      );
      final res = await http.get(uri, headers: headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) return data['data'];
      }
    } catch (e) {
      print('ApiService getReports error: $e');
    }
    return null;
  }

}
