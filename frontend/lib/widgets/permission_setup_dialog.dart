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
  bool _isChecking = true;
  Map<String, bool> _permissionStatus = {};

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    if (mounted) {
      setState(() => _isChecking = true);
    }

    try {
      final location = await _permissionService.hasLocationPermission();
      final background = await _permissionService
          .hasBackgroundLocationPermission();
      final notification = await _permissionService.hasNotificationPermission();
      final battery = await _permissionService.isIgnoringBatteryOptimizations();

      if (mounted) {
        setState(() {
          _permissionStatus = {
            'location': location,
            'background': background,
            'notification': notification,
            'battery': battery,
          };
          _isChecking = false;
        });
      }
    } catch (e) {
      // Handle error silently
      if (mounted) {
        setState(() {
          _permissionStatus = {
            'location': false,
            'background': false,
            'notification': false,
            'battery': false,
          };
          _isChecking = false;
        });
      }
    }
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
      title: Row(
        children: [
          const Expanded(child: Text('Setup Tracking Permissions')),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkPermissions,
            tooltip: 'Refresh permission status',
          ),
        ],
      ),
      content: _isChecking
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'For reliable location tracking, this app needs the following permissions:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  if (allGranted)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '✓ All permissions granted! You\'re ready to track.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
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
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange.shade700,
                          ),
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
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: granted ? Colors.green.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: granted ? Colors.green.shade200 : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: granted ? Colors.green.shade700 : Colors.grey.shade600,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: granted ? Colors.green.shade900 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: granted
                          ? Colors.green.shade700
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: granted ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(
                granted ? Icons.check : Icons.close,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
