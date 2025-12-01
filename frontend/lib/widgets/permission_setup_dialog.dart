import 'package:flutter/material.dart';
import '../services/permission_service.dart';

class PermissionSetupDialog extends StatefulWidget {
  const PermissionSetupDialog({super.key});

  @override
  State<PermissionSetupDialog> createState() => _PermissionSetupDialogState();
}

class _PermissionSetupDialogState extends State<PermissionSetupDialog> {
  final PermissionService _permissionService = PermissionService();
  bool _isLoading = false;
  Map<String, bool> _permissionStatus = {};

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final location = await _permissionService.hasLocationPermission();
    final background = await _permissionService
        .hasBackgroundLocationPermission();
    final notification = await _permissionService.hasNotificationPermission();
    final battery = await _permissionService.isIgnoringBatteryOptimizations();

    setState(() {
      _permissionStatus = {
        'location': location,
        'background': background,
        'notification': notification,
        'battery': battery,
      };
    });
  }

  Future<void> _requestAllPermissions() async {
    setState(() => _isLoading = true);

    try {
      // Request tracking permissions
      await _permissionService.requestAllTrackingPermissions();

      // Request battery optimization
      await _permissionService.requestIgnoreBatteryOptimizations();

      // Refresh status
      await _checkPermissions();

      if (mounted) {
        final allGranted = _permissionStatus.values.every((v) => v);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              allGranted
                  ? '✓ All permissions granted!'
                  : 'Some permissions were not granted. Tracking may not work reliably.',
            ),
            backgroundColor: allGranted ? Colors.green : Colors.orange,
          ),
        );

        if (allGranted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allGranted =
        _permissionStatus.isNotEmpty &&
        _permissionStatus.values.every((v) => v);

    return AlertDialog(
      title: const Text('Setup Tracking Permissions'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'For reliable location tracking, this app needs the following permissions:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildPermissionItem(
              'Location',
              'Required to track your location',
              _permissionStatus['location'] ?? false,
              Icons.location_on,
            ),
            _buildPermissionItem(
              'Background Location',
              'Track location even when app is closed',
              _permissionStatus['background'] ?? false,
              Icons.my_location,
            ),
            _buildPermissionItem(
              'Notifications',
              'Show tracking status in notification',
              _permissionStatus['notification'] ?? false,
              Icons.notifications,
            ),
            _buildPermissionItem(
              'Battery Optimization',
              'Prevent Android from stopping tracking',
              _permissionStatus['battery'] ?? false,
              Icons.battery_charging_full,
            ),
            if (!allGranted) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Without these permissions, tracking may stop when the app is closed or device is idle.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!allGranted)
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Skip'),
          ),
        if (allGranted)
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Done'),
          ),
        if (!allGranted)
          ElevatedButton(
            onPressed: _isLoading ? null : _requestAllPermissions,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Grant Permissions'),
          ),
        if (allGranted)
          ElevatedButton(
            onPressed: () => _permissionService.openSettings(),
            child: const Text('Open Settings'),
          ),
      ],
    );
  }

  Widget _buildPermissionItem(
    String title,
    String description,
    bool granted,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: granted ? Colors.green : Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Icon(
            granted ? Icons.check_circle : Icons.cancel,
            color: granted ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }
}
