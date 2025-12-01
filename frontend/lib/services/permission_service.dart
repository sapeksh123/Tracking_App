import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionService {
  /// Request basic location permission
  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  /// Request background location permission (Android 10+)
  Future<bool> requestBackgroundLocationPermission() async {
    // First check if location permission is granted
    if (!await Permission.location.isGranted) {
      final locationStatus = await Permission.location.request();
      if (!locationStatus.isGranted) {
        return false;
      }
    }

    // Then request background location
    final status = await Permission.locationAlways.request();
    return status.isGranted;
  }

  /// Request notification permission (Android 13+)
  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted || status.isLimited;
  }

  /// Request all permissions needed for tracking
  Future<Map<String, bool>> requestAllTrackingPermissions() async {
    final results = <String, bool>{};

    // 1. Location permission
    results['location'] = await requestLocationPermission();

    // 2. Background location permission
    if (results['location'] == true) {
      results['backgroundLocation'] =
          await requestBackgroundLocationPermission();
    } else {
      results['backgroundLocation'] = false;
    }

    // 3. Notification permission
    results['notification'] = await requestNotificationPermission();

    return results;
  }

  /// Check if all required permissions are granted
  Future<bool> hasAllTrackingPermissions() async {
    final location = await Permission.location.isGranted;
    final backgroundLocation = await Permission.locationAlways.isGranted;
    final notification =
        await Permission.notification.isGranted ||
        await Permission.notification.isLimited;

    return location && backgroundLocation && notification;
  }

  Future<bool> hasLocationPermission() async {
    return await Permission.location.isGranted;
  }

  Future<bool> hasBackgroundLocationPermission() async {
    return await Permission.locationAlways.isGranted;
  }

  Future<bool> hasNotificationPermission() async {
    return await Permission.notification.isGranted ||
        await Permission.notification.isLimited;
  }

  /// Request to ignore battery optimizations (important for background tracking)
  Future<bool> requestIgnoreBatteryOptimizations() async {
    final status = await Permission.ignoreBatteryOptimizations.request();
    return status.isGranted;
  }

  Future<bool> isIgnoringBatteryOptimizations() async {
    return await Permission.ignoreBatteryOptimizations.isGranted;
  }

  /// Show dialog explaining why permissions are needed
  Future<bool?> showPermissionRationaleDialog(
    BuildContext context,
    String permissionName,
    String reason,
  ) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permissionName Permission Required'),
        content: Text(reason),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
  }

  /// Open app settings
  Future<void> openSettings() async {
    await openAppSettings();
  }
}
