import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'device_info_service.dart';
import 'battery_service.dart';

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

      await _api.registerDevice(userId, _androidId!, deviceModel);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('android_id', _androidId!);
    } catch (e) {
      print('Error registering device: $e');
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

      // Start periodic tracking (every 60 seconds)
      _trackingTimer = Timer.periodic(Duration(seconds: 60), (timer) {
        _sendLocationUpdate();
      });

      // Send initial location
      await _sendLocationUpdate();

      print('Tracking started for user: $userId');
    } catch (e) {
      print('Error starting tracking: $e');
      _isTracking = false;
      rethrow;
    }
  }

  Future<void> _sendLocationUpdate() async {
    if (!_isTracking || _userId == null) return;

    try {
      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
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

      print(
        'Location update sent: ${position.latitude}, ${position.longitude}, Battery: $batteryLevel%',
      );
    } catch (e) {
      print('Error sending location update: $e');
    }
  }

  Future<void> stopTracking() async {
    _trackingTimer?.cancel();
    _positionSubscription?.cancel();
    _isTracking = false;
    _userId = null;
    print('Tracking stopped');
  }

  void dispose() {
    stopTracking();
  }
}
