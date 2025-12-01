import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PunchInOutWidget extends StatelessWidget {
  final bool isPunchedIn;
  final Map<String, dynamic>? currentSession;
  final VoidCallback onPunchIn;
  final VoidCallback onPunchOut;
  final bool isLoading;

  const PunchInOutWidget({
    super.key,
    required this.isPunchedIn,
    this.currentSession,
    required this.onPunchIn,
    required this.onPunchOut,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Status Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isPunchedIn
                        ? Colors.green.shade100
                        : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPunchedIn
                        ? FontAwesomeIcons.clock
                        : FontAwesomeIcons.clockFour,
                    color: isPunchedIn
                        ? Colors.green.shade700
                        : Colors.grey.shade600,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPunchedIn ? 'Punched In' : 'Not Punched In',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        isPunchedIn
                            ? 'Your attendance is being tracked'
                            : 'Punch in to start your work day',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Session Details (if punched in)
            if (isPunchedIn && currentSession != null) ...[
              Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    context,
                    Icons.access_time,
                    _formatDuration(currentSession!['currentDuration']),
                    'Duration',
                    Colors.blue,
                  ),
                  _buildStatItem(
                    context,
                    Icons.route,
                    _formatDistance(currentSession!['currentDistance']),
                    'Distance',
                    Colors.orange,
                  ),
                  _buildStatItem(
                    context,
                    Icons.battery_charging_full,
                    '${currentSession!['currentBattery'] ?? currentSession!['punchInBattery'] ?? 0}%',
                    'Battery',
                    Colors.green,
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    context,
                    Icons.location_on,
                    '${currentSession!['trackingPoints'] ?? 0}',
                    'Points',
                    Colors.purple,
                  ),
                  _buildStatItem(
                    context,
                    Icons.place,
                    '${currentSession!['visitCount'] ?? 0}',
                    'Visits',
                    Colors.teal,
                  ),
                  _buildStatItem(
                    context,
                    Icons.speed,
                    _formatSpeed(currentSession!['avgSpeed']),
                    'Avg Speed',
                    Colors.indigo,
                  ),
                ],
              ),
            ],

            SizedBox(height: 20),

            // Punch In/Out Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading
                    ? null
                    : (isPunchedIn ? onPunchOut : onPunchIn),
                icon: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Icon(isPunchedIn ? Icons.logout : Icons.login),
                label: Text(
                  isLoading
                      ? (isPunchedIn ? 'Punching Out...' : 'Punching In...')
                      : (isPunchedIn ? 'Punch Out' : 'Punch In'),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: isPunchedIn ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            // Punch In Time (if punched in)
            if (isPunchedIn && currentSession != null) ...[
              SizedBox(height: 12),
              Text(
                'Punched in at ${_formatTime(currentSession!['punchInTime'])}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
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

  String _formatTime(String? timeStr) {
    if (timeStr == null) return 'N/A';
    try {
      final time = DateTime.parse(
        timeStr,
      ).toLocal(); // Convert UTC to local time
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatSpeed(double? speed) {
    if (speed == null) return '0 km/h';
    return '${speed.toStringAsFixed(1)} km/h';
  }
}
