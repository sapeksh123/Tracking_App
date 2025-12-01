import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'battery_service.dart';
import 'tracking_service.dart';

class AttendanceService {
  final ApiService _api = ApiService();
  final BatteryService _battery = BatteryService();
  final TrackingService _tracking = TrackingService();

  bool _isPunchedIn = false;
  Map<String, dynamic>? _currentSession;
  String? _userId;

  bool get isPunchedIn => _isPunchedIn;
  Map<String, dynamic>? get currentSession => _currentSession;

  Future<void> initialize(String userId) async {
    _userId = userId;
    await _loadCurrentSession();
  }

  Future<void> _loadCurrentSession() async {
    if (_userId == null) return;

    try {
      final response = await _api.getCurrentSession(_userId!);
      _isPunchedIn = response['isPunchedIn'] ?? false;
      _currentSession = response['session'];

      // If punched in, start tracking
      if (_isPunchedIn && _currentSession != null) {
        await _tracking.startTracking(_userId!);
      }
    } catch (e) {
      // Silently handle errors
    }
  }

  Future<Map<String, dynamic>> punchIn() async {
    if (_userId == null) {
      throw Exception('User ID not set');
    }

    if (_isPunchedIn) {
      throw Exception('Already punched in');
    }

    try {
      // Get current location
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      // Get battery level
      final batteryLevel = await _battery.getBatteryLevel();

      // Call punch in API
      final response = await _api.punchIn(
        userId: _userId!,
        latitude: position.latitude,
        longitude: position.longitude,
        battery: batteryLevel,
      );

      // Update local state
      _isPunchedIn = true;
      _currentSession = response['session'];

      // Store session ID for background service
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_session_id', _currentSession!['id']);

      // Start location tracking
      await _tracking.startTracking(_userId!);

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> punchOut() async {
    if (_userId == null) {
      throw Exception('User ID not set');
    }

    if (!_isPunchedIn) {
      throw Exception('Not punched in');
    }

    try {
      // Stop tracking first
      await _tracking.stopTracking();

      // Get current location
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      // Get battery level
      final batteryLevel = await _battery.getBatteryLevel();

      // Call punch out API
      final response = await _api.punchOut(
        userId: _userId!,
        latitude: position.latitude,
        longitude: position.longitude,
        battery: batteryLevel,
      );

      // Update local state
      _isPunchedIn = false;
      _currentSession = null;

      // Clear session ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_session_id');

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getAttendanceHistory() async {
    if (_userId == null) {
      throw Exception('User ID not set');
    }

    try {
      final response = await _api.getAttendanceHistory(_userId!);
      return response['sessions'] ?? [];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSessionRoute(String sessionId) async {
    if (_userId == null) {
      throw Exception('User ID not set');
    }

    try {
      final response = await _api.getSessionRoute(_userId!, sessionId);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refreshCurrentSession() async {
    await _loadCurrentSession();
  }

  String formatDuration(int? minutes) {
    if (minutes == null) return '0m';
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }

  String formatDistance(int? meters) {
    if (meters == null) return '0m';
    if (meters < 1000) return '${meters}m';
    return '${(meters / 1000).toStringAsFixed(2)}km';
  }

  void dispose() {
    _tracking.dispose();
  }
}
