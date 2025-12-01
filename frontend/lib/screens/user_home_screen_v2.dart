import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import '../services/attendance_service.dart';
import '../services/permission_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/toast.dart';
import '../widgets/tracking_consent_dialog.dart';
import '../widgets/punch_in_out_widget.dart';

class UserHomeScreenV2 extends StatefulWidget {
  const UserHomeScreenV2({super.key});

  @override
  State<UserHomeScreenV2> createState() => _UserHomeScreenV2State();
}

class _UserHomeScreenV2State extends State<UserHomeScreenV2>
    with WidgetsBindingObserver {
  final AttendanceService _attendanceService = AttendanceService();
  final PermissionService _permissionService = PermissionService();

  bool _isPunchedIn = false;
  bool _isLoading = false;
  bool _isInitializing = true;
  Map<String, dynamic>? _currentSession;
  String? _userId;
  List<dynamic> _recentSessions = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _attendanceService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh session when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _refreshSession();
    }
  }

  Future<void> _initialize() async {
    setState(() => _isInitializing = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('user');

      if (userStr != null && userStr.isNotEmpty) {
        try {
          final userMap = jsonDecode(userStr) as Map<String, dynamic>;
          _userId = userMap['id'];
          debugPrint('✓ User ID loaded: $_userId');
        } catch (e) {
          debugPrint('✗ Failed to parse user data: $e');
        }
      } else {
        debugPrint('⚠ No user data found in SharedPreferences');
      }

      if (_userId != null) {
        // Initialize attendance service
        await _attendanceService.initialize(_userId!);

        // Load current session state from server
        await _refreshSession();

        // Load recent sessions
        await _loadRecentSessions();

        // Start periodic refresh (every 30 seconds)
        _startPeriodicRefresh();

        // Show consent dialog if not punched in
        if (!_isPunchedIn) {
          _showConsentDialog();
        }
      } else {
        // No user ID, redirect to login
        if (mounted) {
          showToast('Please login again', error: true);
          Navigator.pushReplacementNamed(context, '/user-login');
        }
      }
    } catch (e) {
      debugPrint('✗ Initialization error: $e');
      if (mounted) {
        showToast('Failed to initialize: $e', error: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (_isPunchedIn && mounted) {
        _refreshSession();
      }
    });
  }

  Future<void> _refreshSession() async {
    if (_userId == null) return;

    try {
      await _attendanceService.refreshCurrentSession();

      if (mounted) {
        setState(() {
          _isPunchedIn = _attendanceService.isPunchedIn;
          _currentSession = _attendanceService.currentSession;
        });

        debugPrint(
          '✓ Session refreshed: isPunchedIn=$_isPunchedIn, session=${_currentSession != null ? "loaded" : "null"}',
        );
      }
    } catch (e) {
      debugPrint('✗ Failed to refresh session: $e');
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
      debugPrint('✗ Error loading recent sessions: $e');
    }
  }

  void _showConsentDialog() {
    // Delay to ensure screen is built
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
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
    });
  }

  Future<void> _requestPermissions() async {
    try {
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

      // Immediately update UI state
      setState(() {
        _isPunchedIn = true;
        _currentSession = _attendanceService.currentSession;
      });

      showToast('✓ Punched in successfully!');

      // Refresh session from server to get latest data (in background)
      _refreshSession();

      // Refresh recent sessions (in background)
      _loadRecentSessions();
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

      // Immediately update UI state
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

      // Refresh session from server (in background)
      _refreshSession();

      // Refresh recent sessions (in background)
      _loadRecentSessions();
    } catch (e) {
      showToast('Failed to punch out: ${e.toString()}', error: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(title: Text("Attendance Tracker")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading your attendance data...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Attendance Tracker"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshSession,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Navigator.pushNamed(context, '/attendance-history');
            },
            tooltip: 'Attendance History',
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/user-login');
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _refreshSession();
          await _loadRecentSessions();
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
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
                      _buildInfoItem('🕐', 'Punch in to start your work day'),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Sessions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/attendance-history');
                      },
                      child: Text('View All'),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _recentSessions.length,
                  itemBuilder: (context, index) {
                    final session = _recentSessions[index];
                    final isActive = session['isActive'] ?? false;
                    return Card(
                      margin: EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isActive
                              ? Colors.green.shade100
                              : Colors.grey.shade200,
                          child: Icon(
                            isActive ? Icons.play_arrow : Icons.check,
                            color: isActive
                                ? Colors.green.shade700
                                : Colors.grey.shade600,
                          ),
                        ),
                        title: Text(
                          _formatDate(session['punchInTime']),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          isActive
                              ? 'Active session'
                              : 'Duration: ${_attendanceService.formatDuration(session['totalDuration'])} • '
                                    'Distance: ${_attendanceService.formatDistance(session['totalDistance'])}',
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // Can view both active and completed sessions
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
