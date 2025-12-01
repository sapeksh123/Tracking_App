import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/api_service.dart';
import '../widgets/toast.dart';

class TrackUserScreenV2 extends StatefulWidget {
  const TrackUserScreenV2({super.key});

  @override
  State<TrackUserScreenV2> createState() => _TrackUserScreenV2State();
}

class _TrackUserScreenV2State extends State<TrackUserScreenV2> {
  final api = ApiService();
  bool _loading = true;
  bool _loadingRoute = false;
  List<dynamic> _users = [];
  String? _selectedUserId;
  Map<String, dynamic>? _currentSession;
  List<dynamic> _sessions = [];
  String? _selectedSessionId;
  Map<String, dynamic>? _routeData;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(20.5937, 78.9629),
    zoom: 5,
  );

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final users = await api.listUsers();
      setState(() => _users = users is List ? users : []);
    } catch (e) {
      if (mounted) {
        showToast(
          (e is ApiException) ? e.message : 'Failed loading users',
          error: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadUserSessions(String userId, String userName) async {
    setState(() {
      _loadingRoute = true;
      _selectedUserId = userId;
      _sessions = [];
      _currentSession = null;
      _selectedSessionId = null;
    });

    try {
      // Load current session
      final currentResponse = await api.getCurrentSession(userId);
      final isPunchedIn = currentResponse['isPunchedIn'] ?? false;

      // Load all sessions
      final sessionsResponse = await api.getAttendanceHistory(userId);
      final sessions = sessionsResponse['sessions'] ?? [];

      if (mounted) {
        setState(() {
          _currentSession = isPunchedIn ? currentResponse['session'] : null;
          _sessions = sessions;
        });

        // Auto-load current session if punched in
        if (isPunchedIn && _currentSession != null) {
          await _loadSessionRoute(_currentSession!['id'], 'Current Session');
        } else if (sessions.isNotEmpty) {
          // Load most recent completed session
          final recentSession = sessions.firstWhere(
            (s) => !s['isActive'],
            orElse: () => sessions.first,
          );
          await _loadSessionRoute(recentSession['id'], 'Recent Session');
        }
      }
    } catch (e) {
      if (mounted) {
        showToast(
          (e is ApiException) ? e.message : 'Failed to load sessions',
          error: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingRoute = false);
      }
    }
  }

  Future<void> _loadSessionRoute(String sessionId, String label) async {
    if (_selectedUserId == null) return;

    setState(() {
      _loadingRoute = true;
      _selectedSessionId = sessionId;
    });

    try {
      final route = await api.getSessionRoute(_selectedUserId!, sessionId);
      if (mounted) {
        setState(() {
          _routeData = route;
        });
        _updateMapWithRoute(route);
        showToast('✓ $label loaded');
      }
    } catch (e) {
      if (mounted) {
        showToast(
          (e is ApiException) ? e.message : 'Failed to load route',
          error: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingRoute = false);
      }
    }
  }

  void _updateMapWithRoute(Map<String, dynamic> data) {
    final route = data['route'];
    final session = data['session'];

    if (route == null || route['geometry'] == null) {
      showToast('No route data available', error: true);
      return;
    }

    final coordinates = route['geometry']['coordinates'] as List;
    if (coordinates.isEmpty) {
      showToast('No location points found', error: true);
      return;
    }

    // Convert coordinates to LatLng
    List<LatLng> points = [];
    for (var coord in coordinates) {
      if (coord is List && coord.length >= 2) {
        points.add(LatLng(coord[1], coord[0]));
      }
    }

    if (points.isEmpty) return;

    // Create markers
    final markers = <Marker>{};
    markers.add(
      Marker(
        markerId: MarkerId('start'),
        position: points.first,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Punch In',
          snippet: _formatTime(session['punchInTime']),
        ),
      ),
    );

    if (points.length > 1 && session['punchOutTime'] != null) {
      markers.add(
        Marker(
          markerId: MarkerId('end'),
          position: points.last,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Punch Out',
            snippet: _formatTime(session['punchOutTime']),
          ),
        ),
      );
    }

    // Create polyline
    final polylines = <Polyline>{
      Polyline(
        polylineId: PolylineId('route'),
        points: points,
        color: Colors.blue,
        width: 4,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ),
    };

    setState(() {
      _markers = markers;
      _polylines = polylines;
    });

    // Animate camera
    if (_mapController != null && points.isNotEmpty) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(_boundsFromLatLngList(points), 50),
      );
    }
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(
      northeast: LatLng(x1!, y1!),
      southwest: LatLng(x0!, y0!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = _routeData?['session'];
    final pointCount = _routeData?['route']?['properties']?['pointCount'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text("Track User"),
        actions: [
          if (_selectedUserId != null && _selectedSessionId != null)
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                _loadSessionRoute(_selectedSessionId!, 'Session');
              },
              tooltip: 'Refresh route',
            ),
        ],
      ),
      body: Column(
        children: [
          // User Selection Card
          Container(
            margin: const EdgeInsets.all(16),
            child: Card(
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
                        Icon(
                          FontAwesomeIcons.userCheck,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Select User to Track',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    _loading
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: "Select User",
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            value: _selectedUserId,
                            isExpanded: true,
                            items: _users.map<DropdownMenuItem<String>>((user) {
                              return DropdownMenuItem(
                                value: user['id'] as String,
                                child: Text(
                                  user['name'] ?? user['id'],
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                final user = _users.firstWhere(
                                  (u) => u['id'] == value,
                                );
                                _loadUserSessions(
                                  value,
                                  user['name'] ?? 'User',
                                );
                              }
                            },
                          ),

                    // Session Selection
                    if (_sessions.isNotEmpty) ...[
                      SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: "Select Session",
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        value: _selectedSessionId,
                        isExpanded: true,
                        items: _sessions.map<DropdownMenuItem<String>>((
                          session,
                        ) {
                          final isActive = session['isActive'] ?? false;
                          final label = isActive
                              ? 'Current Session (Active)'
                              : _formatDate(session['punchInTime']);
                          return DropdownMenuItem(
                            value: session['id'] as String,
                            child: Text(label, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            final session = _sessions.firstWhere(
                              (s) => s['id'] == value,
                            );
                            final label = session['isActive']
                                ? 'Current Session'
                                : 'Session';
                            _loadSessionRoute(value, label);
                          }
                        },
                      ),
                    ],

                    if (_currentSession != null) ...[
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.play_circle,
                              size: 16,
                              color: Colors.green.shade700,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'User is currently punched in',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Map Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: _initialPosition,
                      markers: _markers,
                      polylines: _polylines,
                      onMapCreated: (controller) {
                        _mapController = controller;
                      },
                      myLocationButtonEnabled: true,
                      myLocationEnabled: true,
                      zoomControlsEnabled: true,
                      mapToolbarEnabled: true,
                    ),
                    if (_loadingRoute)
                      Container(
                        color: Colors.black26,
                        child: Center(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 12),
                                  Text('Loading route...'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (session != null && !_loadingRoute)
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatItem(
                                      Icons.access_time,
                                      'Duration',
                                      _formatDuration(session['totalDuration']),
                                    ),
                                    _buildStatItem(
                                      Icons.route,
                                      'Distance',
                                      _formatDistance(session['totalDistance']),
                                    ),
                                    _buildStatItem(
                                      Icons.location_on,
                                      'Points',
                                      '$pointCount',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Text(
          value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null) return 'N/A';
    try {
      final time = DateTime.parse(timeStr);
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
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
}
