import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  // For Android emulator (device to host) use 10.0.2.2
  static const String baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:5000');
  static String api(String path) => '$baseUrl/api$path';
}

class ApiService {
  ApiService();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse(ApiConfig.api('/auth/login')),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw ApiException(res.statusCode, body['error'] ?? 'Unknown error');
  }

  Future<Map<String, dynamic>> createUser(String name, {String? email, String? phone, String? role}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final res = await http.post(Uri.parse(ApiConfig.api('/users')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token != null ? 'Bearer $token' : ''
        },
        body: jsonEncode({'name': name, 'email': email, 'phone': phone, 'role': role ?? 'user'}));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw ApiException(res.statusCode, body['error'] ?? 'Unknown error');
  }

  Future<List<dynamic>> listUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final res = await http.get(Uri.parse(ApiConfig.api('/users')), headers: {
      'Authorization': token != null ? 'Bearer $token' : '',
    });
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw ApiException(res.statusCode, body['error'] ?? 'Unknown error');
  }

  Future<Map<String, dynamic>> postPing(String userId, double lat, double lng, {double? accuracy}) async {
    final res = await http.post(Uri.parse(ApiConfig.api('/tracking/ping')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'lat': lat, 'lng': lng, 'accuracy': accuracy, 'recordedAt': DateTime.now().toIso8601String()}));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw ApiException(res.statusCode, body['error'] ?? 'Unknown error');
  }

  Future<Map<String, dynamic>> getRoute(String userId, {DateTime? from, DateTime? to}) async {
    final params = <String>[];
    if (from != null) params.add('from=${Uri.encodeComponent(from.toIso8601String())}');
    if (to != null) params.add('to=${Uri.encodeComponent(to.toIso8601String())}');
    final q = params.isNotEmpty ? '?${params.join('&')}' : '';
    final res = await http.get(Uri.parse(ApiConfig.api('/tracking/user/$userId/route$q')));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw ApiException(res.statusCode, body['error'] ?? 'Unknown error');
  }

  Future<List<dynamic>> getTrips(String userId) async {
    final res = await http.get(Uri.parse(ApiConfig.api('/tracking/user/$userId/trips')));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw ApiException(res.statusCode, body['error'] ?? 'Unknown error');
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException($statusCode): $message';
}
