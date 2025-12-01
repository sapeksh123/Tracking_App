import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/api_service.dart';
import '../widgets/toast.dart';

class UserDetailScreenV2 extends StatefulWidget {
  final String userId;
  final String userName;

  const UserDetailScreenV2({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<UserDetailScreenV2> createState() => _UserDetailScreenV2State();
}

class _UserDetailScreenV2State extends State<UserDetailScreenV2> {
  final api = ApiService();
  bool _loading = true;
  Map<String, dynamic>? _user;
  List<dynamic> _sessions = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (mounted) {
        _loadUserDetails();
      }
    });
  }

  Future<void> _loadUserDetails() async {
    setState(() => _loading = true);
    try {
      // Load user info
      final userResponse = await api.getUser(widget.userId);

      // Load attendance sessions
      final sessionsResponse = await api.getAttendanceHistory(widget.userId);

      if (mounted) {
        setState(() {
          _user = userResponse.containsKey('user')
              ? userResponse['user']
              : userResponse;
          _sessions = sessionsResponse['sessions'] ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        showToast(
          (e is ApiException) ? e.message : 'Failed to load user details',
          error: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userName),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadUserDetails,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserDetails,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Info Card
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  child: Icon(
                                    Icons.person,
                                    size: 35,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _user?['name'] ?? 'Unknown',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.headlineSmall,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        _user?['role']?.toUpperCase() ?? 'USER',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (_user?['isPunchedIn'] ?? false)
                                        ? Colors.green
                                        : (_user?['isActive'] ?? false)
                                        ? Colors.blue
                                        : Colors.red,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    (_user?['isPunchedIn'] ?? false)
                                        ? 'Punched In'
                                        : (_user?['isActive'] ?? false)
                                        ? 'Active'
                                        : 'Inactive',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Divider(height: 32),
                            _buildInfoRow(
                              Icons.email_outlined,
                              'Email',
                              _user?['email'] ?? 'Not provided',
                            ),
                            SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.phone_android,
                              'Phone',
                              _user?['phone'] ?? 'Not provided',
                            ),
                            SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.calendar_today,
                              'Created',
                              _formatDate(_user?['createdAt']),
                            ),
                            if (_user?['lastSeen'] != null) ...[
                              SizedBox(height: 12),
                              _buildInfoRow(
                                Icons.access_time,
                                'Last Seen',
                                _formatDateTime(_user?['lastSeen']),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Statistics Card
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Statistics',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem(
                                  Icons.calendar_month,
                                  'Total Sessions',
                                  '${_sessions.length}',
                                  Colors.blue,
                                ),
                                _buildStatItem(
                                  Icons.check_circle,
                                  'Completed',
                                  '${_sessions.where((s) => !s['isActive']).length}',
                                  Colors.green,
                                ),
                                _buildStatItem(
                                  Icons.play_circle,
                                  'Active',
                                  '${_sessions.where((s) => s['isActive']).length}',
                                  Colors.orange,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Attendance Sessions Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Attendance Sessions (${_sessions.length})',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (_sessions.isNotEmpty)
                          TextButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/track-user',
                                arguments: {
                                  'userId': widget.userId,
                                  'userName': widget.userName,
                                },
                              );
                            },
                            icon: Icon(Icons.map),
                            label: Text('Track'),
                          ),
                      ],
                    ),

                    SizedBox(height: 8),

                    _sessions.isEmpty
                        ? Card(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      FontAwesomeIcons.clockFour,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No attendance sessions yet',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: _sessions.length,
                            itemBuilder: (context, index) {
                              final session = _sessions[index];
                              final isActive = session['isActive'] ?? false;
                              return Card(
                                margin: EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isActive
                                        ? Colors.green.shade100
                                        : Colors.blue.shade100,
                                    child: Icon(
                                      isActive
                                          ? Icons.play_arrow
                                          : Icons.check_circle,
                                      color: isActive
                                          ? Colors.green.shade700
                                          : Colors.blue.shade700,
                                    ),
                                  ),
                                  title: Text(
                                    _formatDate(session['punchInTime']),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isActive
                                            ? 'Duration: ${_formatDuration(session['currentDuration'] ?? 0)} • '
                                                  'Distance: ${_formatDistance(session['currentDistance'] ?? 0)}'
                                            : 'Duration: ${_formatDuration(session['totalDuration'])} • '
                                                  'Distance: ${_formatDistance(session['totalDistance'])}',
                                      ),
                                      if (session['currentBattery'] != null ||
                                          session['punchInBattery'] != null)
                                        Text(
                                          'Battery: ${session['currentBattery'] ?? session['punchInBattery'] ?? 0}%',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: isActive
                                      ? Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            'ACTIVE',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        )
                                      : Icon(Icons.arrow_forward_ios, size: 16),
                                  onTap: () {
                                    _showSessionDetails(session, isActive);
                                  },
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr).toLocal(); // Convert to local time
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

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr).toLocal(); // Convert to local time
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatDuration(int? minutes) {
    if (minutes == null) return '0m';
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }

  String _formatDistance(int? meters) {
    if (meters == null) return '0m';
    if (meters < 1000) return '${meters}m';
    return '${(meters / 1000).toStringAsFixed(2)}km';
  }

  void _showSessionDetails(Map<String, dynamic> session, bool isActive) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isActive ? Icons.play_circle : Icons.check_circle,
              color: isActive ? Colors.green : Colors.blue,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                isActive ? 'Active Session' : 'Session Details',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                'Punch In',
                _formatDateTime(session['punchInTime']),
              ),
              if (!isActive && session['punchOutTime'] != null)
                _buildDetailRow(
                  'Punch Out',
                  _formatDateTime(session['punchOutTime']),
                ),
              Divider(),
              _buildDetailRow(
                'Duration',
                _formatDuration(
                  isActive
                      ? session['currentDuration']
                      : session['totalDuration'],
                ),
              ),
              _buildDetailRow(
                'Distance',
                _formatDistance(
                  isActive
                      ? session['currentDistance']
                      : session['totalDistance'],
                ),
              ),
              _buildDetailRow(
                'Tracking Points',
                '${session['trackingPoints'] ?? 0}',
              ),
              _buildDetailRow('Visits', '${session['visitCount'] ?? 0}'),
              Divider(),
              _buildDetailRow(
                'Punch In Battery',
                '${session['punchInBattery'] ?? 0}%',
              ),
              if (session['currentBattery'] != null)
                _buildDetailRow(
                  'Current Battery',
                  '${session['currentBattery']}%',
                ),
              if (!isActive && session['punchOutBattery'] != null)
                _buildDetailRow(
                  'Punch Out Battery',
                  '${session['punchOutBattery']}%',
                ),
              if (session['avgSpeed'] != null)
                _buildDetailRow(
                  'Average Speed',
                  '${session['avgSpeed'].toStringAsFixed(1)} km/h',
                ),
            ],
          ),
        ),
        actions: [
          if (!isActive)
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/session-route',
                  arguments: {
                    'sessionId': session['id'],
                    'userId': widget.userId,
                  },
                );
              },
              icon: Icon(Icons.map),
              label: Text('View Route'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
