import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class BackgroundLocationService {
  static const String notificationChannelId = 'attendance_tracking_channel';
  static const String notificationChannelName = 'Attendance Tracking';
  static const int notificationId = 888;

  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    // Create notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId,
      notificationChannelName,
      description: 'This channel is used for attendance location tracking',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        autoStartOnBoot: true,
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'Attendance Tracking',
        initialNotificationContent: 'Tracking your location...',
        foregroundServiceNotificationId: notificationId,
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    if (service is AndroidServiceInstance) {
      service.on('stopService').listen((event) {
        service.stopSelf();
      });

      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    // Load user data
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    final token = prefs.getString('token');
    final isTracking = prefs.getBool('is_tracking') ?? false;

    // Only run service if user is actively tracking (punched in)
    if (userStr == null || token == null || !isTracking) {
      service.stopSelf();
      return;
    }

    String userId;
    try {
      final userMap = jsonDecode(userStr) as Map<String, dynamic>;
      final id = userMap['id'];
      if (id == null) {
        service.stopSelf();
        return;
      }
      userId = id.toString();
    } catch (e) {
      // Error parsing user data
      service.stopSelf();
      return;
    }

    // Initialize services
    final Battery battery = Battery();
    int locationUpdateCount = 0;

    // Periodic location tracking (every 60 seconds)
    Timer.periodic(const Duration(seconds: 60), (timer) async {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          try {
            // Check if location service is enabled
            final serviceEnabled = await Geolocator.isLocationServiceEnabled();
            if (!serviceEnabled) {
              // Update notification to show GPS is off
              service.setForegroundNotificationInfo(
                title: 'Attendance Tracking - GPS Off',
                content: 'Please enable location services',
              );
              return;
            }

            // Get current location
            final position = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
                distanceFilter: 10,
              ),
            );

            // Get battery level
            final batteryLevel = await battery.batteryLevel;

            locationUpdateCount++;

            // Update notification
            service.setForegroundNotificationInfo(
              title: 'Attendance Tracking Active',
              content:
                  'Location updates: $locationUpdateCount | Battery: $batteryLevel%',
            );

            // Send location to server
            await _sendLocationToServer(
              userId,
              token,
              position.latitude,
              position.longitude,
              batteryLevel,
            );
          } catch (e) {
            // Silently handle errors
          }
        }
      }
    });
  }

  static Future<void> _sendLocationToServer(
    String userId,
    String token,
    double latitude,
    double longitude,
    int battery,
  ) async {
    try {
      // Get API base URL from environment or use default
      const String baseUrl = String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://10.0.2.2:5000',
      );

      await http
          .post(
            Uri.parse('$baseUrl/api/tracking/location'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'userId': userId,
              'latitude': latitude,
              'longitude': longitude,
              'battery': battery,
              'timestamp': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      // Silently handle errors
    }
  }

  static Future<void> startService() async {
    // Set tracking flag in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_tracking', true);

    final service = FlutterBackgroundService();
    await service.startService();
  }

  static Future<void> stopService() async {
    // Clear tracking flag in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_tracking', false);

    final service = FlutterBackgroundService();
    service.invoke('stopService');
  }

  static Future<bool> isServiceRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }
}
