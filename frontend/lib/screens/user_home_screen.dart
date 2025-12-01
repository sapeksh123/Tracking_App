import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/attendance_service.dart';
import '../services/permission_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/toast.dart';
import '../widgets/tracking_consent_dialog.dart';
import '../widgets/punch_in_out_widget.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final PermissionService _permissionService = PermissionService();

  bool _isPunchedIn = false;
  bool _isLoading = false;
  Map<String, dynamic>? _currentSession;
  String? _userId;
  List<dynamic> _recentSessions = [];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');

    if (userStr != null && userStr.isNotEmpty) {
      try {
        // Parse user JSON to get ID
        final userMap = jsonDecode(userStr) as Map<String, dynamic>;
        _userId = userMap['id'];
        print('DEBUG: User ID loaded: $_userId');
      } catch (e) {
        print('ERROR: Failed to parse user data: $e');
        print('User string: $userStr');
      }
    } else {
      print('WARNING: No user data found in SharedPreferences');
    }

    if (_userId != null) {
      // Initialize attendance service
      await _attendanceService.initialize(_userId!);

      // Load current state
      _isPunchedIn = _attendanceService.isPunchedIn;
      _currentSession = _attendanceService.currentSession;

      // Load recent sessions
      await _loadRecentSessions();
    }

    if (mounted) {
      setState(() {});

      // Show consent dialog if not consented and not punched in
      if (!_isPunchedIn && _userId != null) {
        _showConsentDialog();
      }
    }
  }

  Future<void> _loadRecentSessions() async {
    try {
      final sessions = await _attendanceService.getAttendanceHistory();
      if (mounted) {
        setState(() {
          _recentSessions = sessions.take(5).toList();
        });
      }
    } catch (e) {
      print('Error loading recent sessions: $e');
    }
  }

  void _showConsentDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TrackingConsentDialog(
        onAgree: () async {
          Navigator.pop(context);
          await _requestPermissions();
        },
        onCancel: () {
          Navigator.pop(context);
          showToast('Location consent denied', error: true);
        },
      ),
    );
  }

  Future<void> _requestPermissions() async {
    try {
      // Request location permission
      final hasPermission = await _permissionService
          .requestLocationPermission();

      if (!hasPermission) {
        showToast('Location permission required for attendance', error: true);
        return;
      }

      showToast('✓ Permissions granted. You can now punch in.');
    } catch (e) {
      showToast('Failed to get permissions: $e', error: true);
    }
  }

  Future<void> _punchIn() async {
    if (_userId == null) {
      showToast('User ID not found. Please login again.', error: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check location permission
      final hasPermission = await _permissionService.hasLocationPermission();
      if (!hasPermission) {
        await _requestPermissions();
        setState(() => _isLoading = false);
        return;
      }

      await _attendanceService.punchIn();

      setState(() {
        _isPunchedIn = true;
        _currentSession = _attendanceService.currentSession;
      });

      showToast('✓ Punched in successfully!');

      // Refresh recent sessions
      await _loadRecentSessions();
    } catch (e) {
      showToast('Failed to punch in: ${e.toString()}', error: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _punchOut() async {
    setState(() => _isLoading = true);

    try {
      final response = await _attendanceService.punchOut();

      setState(() {
        _isPunchedIn = false;
        _currentSession = null;
      });

      final session = response['session'];
      final duration = _attendanceService.formatDuration(
        session['totalDuration'],
      );
      final distance = _attendanceService.formatDistance(
        session['totalDistance'],
      );

      showToast('✓ Punched out! Duration: $duration, Distance: $distance');

      // Refresh recent sessions
      await _loadRecentSessions();
    } catch (e) {
      showToast('Failed to punch out: ${e.toString()}', error: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _attendanceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Attendance Tracker"),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Navigator.pushNamed(context, '/attendance-history');
            },
            tooltip: 'Attendance History',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Punch In/Out Card
            PunchInOutWidget(
              isPunchedIn: _isPunchedIn,
              currentSession: _currentSession,
              onPunchIn: _punchIn,
              onPunchOut: _punchOut,
              isLoading: _isLoading,
            ),

            SizedBox(height: 16),

            // Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'How Attendance Works',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    _buildInfoItem('�', 'Punch in to start your work day'),
                    _buildInfoItem(
                      '📍',
                      'Location is tracked during work hours',
                    ),
                    _buildInfoItem('🔋', 'Battery level is monitored'),
                    _buildInfoItem('🕕', 'Punch out to end your work day'),
                    _buildInfoItem(
                      '📊',
                      'View your attendance history anytime',
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Recent Sessions
            if (_recentSessions.isNotEmpty) ...[
              Text(
                'Recent Sessions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _recentSessions.length,
                itemBuilder: (context, index) {
                  final session = _recentSessions[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: session['isActive']
                            ? Colors.green.shade100
                            : Colors.grey.shade200,
                        child: Icon(
                          session['isActive'] ? Icons.play_arrow : Icons.check,
                          color: session['isActive']
                              ? Colors.green.shade700
                              : Colors.grey.shade600,
                        ),
                      ),
                      title: Text(
                        _formatDate(session['punchInTime']),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        session['isActive']
                            ? 'Active session'
                            : 'Duration: ${_attendanceService.formatDuration(session['totalDuration'])} • '
                                  'Distance: ${_attendanceService.formatDistance(session['totalDistance'])}',
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // Navigate to session details
                        Navigator.pushNamed(
                          context,
                          '/session-route',
                          arguments: {
                            'sessionId': session['id'],
                            'userId': _userId,
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: 16)),
          SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final sessionDate = DateTime(date.year, date.month, date.day);

      if (sessionDate == today) {
        return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } else if (sessionDate == today.subtract(Duration(days: 1))) {
        return 'Yesterday ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'N/A';
    }
  }
}
