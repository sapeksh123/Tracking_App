import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;
  final SharedPreferences? _prefs;

  AuthService._(this._prefs) {
    _token = _prefs?.getString('token');
    final u = _prefs?.getString('user');
    if (u != null) _user = jsonDecode(u);
  }

  /// Create a lightweight AuthService instance (no shared preferences) - useful for tests.
  AuthService() : _prefs = null, _token = null, _user = null;

  static Future<AuthService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return AuthService._(prefs);
  }

  String? get token => _token;
  Map<String, dynamic>? get user => _user;

  Future<void> setToken(String? token) async {
    _token = token;
    if (_prefs != null) {
      if (token == null) {
        await _prefs.remove('token');
      } else {
        await _prefs.setString('token', token);
      }
    }
    notifyListeners();
  }

  Future<void> setUser(Map<String, dynamic>? user) async {
    _user = user;
    if (_prefs != null) {
      if (user == null) {
        await _prefs.remove('user');
      } else {
        await _prefs.setString('user', jsonEncode(user));
      }
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await setToken(null);
    await setUser(null);
  }

  // Delegate to ApiService
  Future<void> login(String email, String password) async {
    final api = ApiService();
    final result = await api.login(email, password);
    final token = result['token'];
    final user = result['user'];
    await setToken(token);
    await setUser(user != null ? Map<String, dynamic>.from(user) : null);
  }
}
