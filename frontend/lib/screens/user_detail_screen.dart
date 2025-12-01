import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/api_service.dart';
import '../widgets/toast.dart';

class UserDetailScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const UserDetailScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final api = ApiService();
  bool _loading = true;
  Map<String, dynamic>? _user;
  List<dynamic> _trips = [];

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    setState(() => _loading = true);
    try {
      final user = await api.getUser(widget.userId);
      final trips = await api.getTrips(widget.userId);

      if (mounted) {
        setState(() {
          _user = user is Map && user.containsKey('user') ? user['user'] : user;
          _trips = trips;
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
          : SingleChildScrollView(
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                  color: (_user?['isActive'] ?? false)
                                      ? Colors.green
                                      : Colors.red,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  (_user?['isActive'] ?? false)
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
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Trips Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Trips (${_trips.length})',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
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
                        label: Text('View on Map'),
                      ),
                    ],
                  ),

                  SizedBox(height: 8),

                  _trips.isEmpty
                      ? Card(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    FontAwesomeIcons.route,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No trips yet',
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
                          itemCount: _trips.length,
                          itemBuilder: (context, index) {
                            final trip = _trips[index];
                            return Card(
                              margin: EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  child: Icon(
                                    FontAwesomeIcons.route,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  '${_formatDistance(trip['distanceMeters'])}',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  '${_formatDate(trip['startedAt'])} - ${_formatTime(trip['endedAt'])}',
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                ),
                              ),
                            );
                          },
                        ),
                ],
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

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatDistance(dynamic meters) {
    if (meters == null) return '0 m';
    final m = meters is int ? meters.toDouble() : meters as double;
    if (m < 1000) {
      return '${m.toStringAsFixed(0)} m';
    }
    return '${(m / 1000).toStringAsFixed(2)} km';
  }
}
