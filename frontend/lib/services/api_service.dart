import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  // For Android emulator (device to host) use 10.0.2.2
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000',
  );
  static String api(String path) => '$baseUrl$path';
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

  Future<Map<String, dynamic>> userLogin(String phone, String password) async {
    final res = await http.post(
      Uri.parse(ApiConfig.api('/auth/user-login')),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'password': password}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw ApiException(res.statusCode, body['error'] ?? 'Unknown error');
  }

  Future<Map<String, dynamic>> createUser(
    String name, {
    String? email,
    String? phone,
    String? role,
    String? password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    print(
      'DEBUG API: Creating user - name: $name, email: $email, phone: $phone',
    );

    final requestBody = {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role ?? 'user',
    };

    // Only add password if provided
    if (password != null && password.isNotEmpty) {
      requestBody['password'] = password;
    }

    final res = await http.post(
      Uri.parse(ApiConfig.api('/users')),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token != null ? 'Bearer $token' : '',
      },
      body: jsonEncode(requestBody),
    );

    print('DEBUG API: Create user response status: ${res.statusCode}');
    print('DEBUG API: Create user response body: ${res.body}');

    final responseBody = jsonDecode(res.body);
    if (res.statusCode == 200) {
      print('DEBUG API: User created successfully');
      return responseBody;
    }
    throw ApiException(
      res.statusCode,
      responseBody['error'] ?? 'Unknown error',
    );
  }

  Future<dynamic> listUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    print('DEBUG API: Calling ${ApiConfig.api('/users')}');
    print('DEBUG API: Token exists: ${token != null}');

    final res = await http.get(
      Uri.parse(ApiConfig.api('/users')),
      headers: {'Authorization': token != null ? 'Bearer $token' : ''},
    );

    print('DEBUG API: Response status: ${res.statusCode}');
    print('DEBUG API: Response body: ${res.body}');

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      print('DEBUG API: Decoded body type: ${body.runtimeType}');

      // Return users array if new format, otherwise return body as is
      if (body is Map && body.containsKey('users')) {
        print(
          'DEBUG API: Returning users array with ${body['users'].length} items',
        );
        return body['users'];
      }
      print('DEBUG API: Returning body as is');
      return body;
    }
    final body = jsonDecode(res.body);
    throw ApiException(res.statusCode, body['error'] ?? 'Unknown error');
  }

  Future<Map<String, dynamic>> postPing(
    String userId,
    double lat,
    double lng, {
    double? accuracy,
  }) async {
    final res = await http.post(
      Uri.parse(ApiConfig.api('/tracking/ping')),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'lat': lat,
        'lng': lng,
        'accuracy': accuracy,
        'recordedAt': DateTime.now().toIso8601String(),
      }),
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return body;
    }
    final body = jsonDecode(res.body);
    throw ApiException(res.statusCode, body['error'] ?? 'Unknown error');
  }

  Future<Map<String, dynamic>> getRoute(
    String userId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final params = <String>[];
    if (from != null) {
      params.add('from=${Uri.encodeComponent(from.toIso8601String())}');
    }
    if (to != null) {
      params.add('to=${Uri.encodeComponent(to.toIso8601String())}');
    }
    final q = params.isNotEmpty ? '?${params.join('&')}' : '';
    final res = await http.get(
      Uri.parse(ApiConfig.api('/tracking/user/$userId/route$q')),
      headers: {'Authorization': token != null ? 'Bearer $token' : ''},
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return body;
    }
    final body = jsonDecode(res.body);
    throw ApiException(res.statusCode, body['error'] ?? 'Unknown error');
  }

  Future<List<dynamic>> getTrips(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final res = await http.get(
      Uri.parse(ApiConfig.api('/tracking/user/$userId/trips')),
      headers: {'Authorization': token != null ? 'Bearer $token' : ''},
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      // Return trips array if new format, otherwise return body as is
      if (body is Map && body.containsKey('trips')) {
        return body['trips'] as List;
      }
      return body as List;
    }
    final body = jsonDecode(res.body);
    throw ApiException(res.statusCode, body['error'] ?? 'Unknown error');
  }

  Future<Map<String, dynamic>> generateTrips(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final res = await http.post(
      Uri.parse(ApiConfig.api('/tracking/user/$userId/generate-trips')),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token != null ? 'Bearer $token' : '',
      },
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return body;
    }
    final body = jsonDecode(res.body);
    throw ApiException(res.statusCode, body['error'] ?? 'Unknown error');
  }

  Future<List<dynamic>> getPings(
    String userId, {
    DateTime? from,
    DateTime? to,
    int? limit,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final params = <String>[];
    if (from != null) {
      params.add('from=${Uri.encodeComponent(from.toIso8601String())}');
    }
    if (to != null) {
      params.add('to=${Uri.encodeComponent(to.toIso8601String())}');
    }
    if (limit != null) {
      params.add('limit=$limit');
    }
    final q = params.isNotEmpty ? '?${params.join('&')}' : '';
    final res = await http.get(
      Uri.parse(ApiConfig.api('/tracking/user/$userId/pings$q')),
      headers: {'Authorization': token != null ? 'Bearer $token' : ''},
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      // Return pings array if new format, otherwise return body as is
      if (body is Map && body.containsKey('pings')) {
        return body['pings'] as List;
      }
      return body as List;
    }
    final body = jsonDecode(res.body);
    throw ApiException(res.statusCode, body['error'] ?? 'Unknown error');
  }

  Future<Map<String, dynamic>> getUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final res = await http.get(
      Uri.parse(ApiConfig.api('/users/$userId')),
      headers: {'Authorization': token != null ? 'Bearer $token' : ''},
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return body;
    }
    final body = jsonDecode(res.body);
    throw ApiException(res.statusCode, body['error'] ?? 'Unknown error');
  }

  Future<Map<String, dynamic>> updateUser(
    String userId, {
    String? name,
    String? email,
    String? phone,
    String? role,
    bool? isActive,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final res = await http.put(
      Uri.parse(ApiConfig.api('/users/$userId')),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token != null ? 'Bearer $token' : '',
      },
      body: jsonEncode({
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (role != null) 'role': role,
        if (isActive != null) 'isActive': isActive,
      }),
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return body;
    }
    final body = jsonDecode(res.body);
    throw ApiException(res.statusCode, body['error'] ?? 'Unknown error');
  }

  Future<Map<String, dynamic>> deleteUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final res = await http.delete(
      Uri.parse(ApiConfig.api('/users/$userId')),
      headers: {'Authorization': token != null ? 'Bearer $token' : ''},
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return body;
    }
    final body = jsonDecode(res.body);
    throw ApiException(res.statusCode, body['error'] ?? 'Unknown error');
  }

  // Real-time tracking APIs
  Future<Map<String, dynamic>> registerDevice(
    String userId,
    String androidId,
    String deviceModel,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final res = await http.post(
      Uri.parse(ApiConfig.api('/realtime/device-register')),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token != null ? 'Bearer $token' : '',
      },
      body: jsonEncode({
        'userId': userId,
        'androidId': androidId,
        'deviceModel': deviceModel,
      }),
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return body;
    }
    final body = jsonDecode(res.body);
    throw ApiException(res.statusCode, body['error'] ?? 'Unknown error');
  }

  Future<Map<String, dynamic>> saveTrackingConsent(
    String userId,
    bool consented,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final res = await http.post(
      Uri.parse(ApiConfig.api('/realtime/consent')),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token != null ? 'Bearer $token' : '',
      },
      body: jsonEncode({'userId': userId, 'consented': consented}),
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return body;
    }
    final body = jsonDecode(res.body);
    throw ApiException(res.statusCode, body['error'] ?? 'Unknown error');
  }

  Future<Map<String, dynamic>> trackLocation({
    required String userId,
    String? androidId,
    required double latitude,
    required double longitude,
    int? battery,
    double? accuracy,
    double? speed,
    required String timestamp,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final res = await http.post(
      Uri.parse(ApiConfig.api('/realtime/track')),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token != null ? 'Bearer $token' : '',
      },
      body: jsonEncode({
        'userId': userId,
        'androidId': androidId,
        'latitude': latitude,
        'longitude': longitude,
        'battery': battery,
        'accuracy': accuracy,
        'speed': speed,
        'timestamp': timestamp,
      }),
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return body;
    }
    final body = jsonDecode(res.body);
    throw ApiException(res.statusCode, body['error'] ?? 'Unknown error');
  }

  Future<Map<String, dynamic>> getLiveTracking(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final res = await http.get(
      Uri.parse(ApiConfig.api('/realtime/user/$userId/live')),
      headers: {'Authorization': token != null ? 'Bearer $token' : ''},
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return body;
    }
    final body = jsonDecode(res.body);
    throw ApiException(res.statusCode, body['error'] ?? 'Unknown error');
  }

  Future<Map<String, dynamic>> getTrackingHistory(
    String userId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final params = <String>[];
    if (from != null) {
      params.add('from=${Uri.encodeComponent(from.toIso8601String())}');
    }
    if (to != null) {
      params.add('to=${Uri.encodeComponent(to.toIso8601String())}');
    }
    final q = params.isNotEmpty ? '?${params.join('&')}' : '';
    final res = await http.get(
      Uri.parse(ApiConfig.api('/realtime/user/$userId/history$q')),
      headers: {'Authorization': token != null ? 'Bearer $token' : ''},
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return body;
    }
    final body = jsonDecode(res.body);
    throw ApiException(res.statusCode, body['error'] ?? 'Unknown error');
  }

  // Attendance APIs
  Future<Map<String, dynamic>> punchIn({
    required String userId,
    required double latitude,
    required double longitude,
    int? battery,
    String? address,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final res = await http.post(
      Uri.parse(ApiConfig.api('/attendance/punch-in')),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token != null ? 'Bearer $token' : '',
      },
      body: jsonEncode({
        'userId': userId,
        'latitude': latitude,
        'longitude': longitude,
        'battery': battery,
        'address': address,
      }),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    final body = jsonDecode(res.body);
    throw ApiException(res.statusCode, body['error'] ?? 'Unknown error');
  }

  Future<Map<String, dynamic>> punchOut({
    required String userId,
    required double latitude,
    required double longitude,
    int? battery,
    String? address,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final res = await http.post(
      Uri.parse(ApiConfig.api('/attendance/punch-out')),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token != null ? 'Bearer $token' : '',
      },
      body: jsonEncode({
        'userId': userId,
        'latitude': latitude,
        'longitude': longitude,
        'battery': battery,
        'address': address,
      }),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    final body = jsonDecode(res.body);
    throw ApiException(res.statusCode, body['error'] ?? 'Unknown error');
  }

  Future<Map<String, dynamic>> getCurrentSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final res = await http.get(
      Uri.parse(ApiConfig.api('/attendance/user/$userId/current')),
      headers: {'Authorization': token != null ? 'Bearer $token' : ''},
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    final body = jsonDecode(res.body);
    throw ApiException(res.statusCode, body['error'] ?? 'Unknown error');
  }

  Future<Map<String, dynamic>> getAttendanceHistory(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final res = await http.get(
      Uri.parse(ApiConfig.api('/attendance/user/$userId/history')),
      headers: {'Authorization': token != null ? 'Bearer $token' : ''},
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    final body = jsonDecode(res.body);
    throw ApiException(res.statusCode, body['error'] ?? 'Unknown error');
  }

  Future<Map<String, dynamic>> getSessionRoute(
    String userId,
    String sessionId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final res = await http.get(
      Uri.parse(
        ApiConfig.api('/attendance/user/$userId/session/$sessionId/route'),
      ),
      headers: {'Authorization': token != null ? 'Bearer $token' : ''},
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    final body = jsonDecode(res.body);
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
