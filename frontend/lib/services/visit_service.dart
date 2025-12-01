import 'package:geolocator/geolocator.dart';
import 'api_service.dart';
import 'battery_service.dart';

class VisitService {
  final ApiService _api = ApiService();
  final BatteryService _battery = BatteryService();

  Future<Map<String, dynamic>> markVisit({
    required String userId,
    String? sessionId,
    String? address,
    String? notes,
  }) async {
    try {
      // Check if location service is enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable GPS.');
      }

      // Check location permission
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission not granted');
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      // Get battery level
      final batteryLevel = await _battery.getBatteryLevel();

      // Mark visit via API
      final response = await _api.markVisit(
        userId: userId,
        sessionId: sessionId,
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        notes: notes,
        battery: batteryLevel,
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getUserVisits(
    String userId, {
    String? sessionId,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final response = await _api.getUserVisits(
        userId,
        sessionId: sessionId,
        from: from,
        to: to,
      );
      return response['visits'] ?? [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getSessionVisits(String sessionId) async {
    try {
      final response = await _api.getSessionVisits(sessionId);
      return response['visits'] ?? [];
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateVisit(
    String visitId, {
    String? address,
    String? notes,
  }) async {
    try {
      await _api.updateVisit(visitId, address: address, notes: notes);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteVisit(String visitId) async {
    try {
      await _api.deleteVisit(visitId);
    } catch (e) {
      rethrow;
    }
  }
}
