import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'device_info_service.dart';
import 'battery_service.dart';
import 'background_location_service.dart';

class TrackingService {
  final ApiService _api = ApiService();
  final DeviceInfoService _deviceInfo = DeviceInfoService();
  final BatteryService _battery = BatteryService();

  Timer? _trackingTimer;
  StreamSubscription<Position>? _positionSubscription;
  bool _isTracking = false;
  String? _userId;
  String? _androidId;

  bool get isTracking => _isTracking;

  Future<bool> hasTrackingConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('tracking_consent') ?? false;
  }

  Future<void> saveTrackingConsent(bool consented) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tracking_consent', consented);
    await prefs.setString('consent_date', DateTime.now().toIso8601String());
  }

  Future<void> registerDevice(String userId) async {
    try {
      _androidId = await _deviceInfo.getAndroidId();
      final deviceModel = await _deviceInfo.getDeviceModel();

      if (_androidId != null) {
        await _api.registerDevice(userId, _androidId!, deviceModel);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('android_id', _androidId!);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> startTracking(String userId) async {
    if (_isTracking) return;

    try {
      _userId = userId;

      // Get or register device
      final prefs = await SharedPreferences.getInstance();
      _androidId = prefs.getString('android_id');

      if (_androidId == null) {
        await registerDevice(userId);
      }

      // Check location permission
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission not granted');
      }

      _isTracking = true;

      // Start background service for persistent tracking
      await BackgroundLocationService.startService();

      // Start periodic tracking (every 60 seconds) as fallback
      _trackingTimer = Timer.periodic(Duration(seconds: 60), (timer) {
        _sendLocationUpdate();
      });

      // Send initial location
      await _sendLocationUpdate();
    } catch (e) {
      _isTracking = false;
      rethrow;
    }
  }

  Future<void> _sendLocationUpdate() async {
    if (!_isTracking || _userId == null) return;

    try {
      // Check if location service is enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are disabled, skip this update
        return;
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

      // Send to API
      await _api.trackLocation(
        userId: _userId!,
        androidId: _androidId,
        latitude: position.latitude,
        longitude: position.longitude,
        battery: batteryLevel,
        accuracy: position.accuracy,
        speed: position.speed,
        timestamp: DateTime.now().toUtc().toIso8601String(),
      );
    } catch (e) {
      // Silently handle errors
    }
  }

  Future<void> stopTracking() async {
    // Stop background service
    await BackgroundLocationService.stopService();

    _trackingTimer?.cancel();
    _positionSubscription?.cancel();
    _isTracking = false;
    _userId = null;
  }

  void dispose() {
    stopTracking();
  }
}
