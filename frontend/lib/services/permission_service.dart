import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

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

  Future<bool> hasLocationPermission() async {
    return await Permission.location.isGranted;
  }

  Future<bool> hasBackgroundLocationPermission() async {
    return await Permission.locationAlways.isGranted;
  }

  Future<void> openAppSettings() async {
    await openAppSettings();
  }
}
