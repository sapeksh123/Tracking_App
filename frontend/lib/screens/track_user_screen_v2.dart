import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
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
  Timer? _refreshTimer;
  List<dynamic> _visits = [];
  Map<String, dynamic>? _liveTracking;

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
    _refreshTimer?.cancel();
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
      // Load session route
      final route = await api.getSessionRoute(_selectedUserId!, sessionId);

      // Load visits for this session
      final visitsResponse = await api.getSessionVisits(sessionId);
      final visits = visitsResponse['visits'] ?? [];

      // Load live tracking data
      final liveData = await api.getLiveTracking(_selectedUserId!);

      if (mounted) {
        setState(() {
          _routeData = route;
          _visits = visits;
          _liveTracking = liveData;
        });
        _updateMapWithRoute(route);
        showToast('✓ $label loaded');

        // Start auto-refresh if session is active
        final session = route['session'];
        if (session != null && session['isActive'] == true) {
          _startAutoRefresh();
        } else {
          _stopAutoRefresh();
        }
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

  void _startAutoRefresh() {
    _stopAutoRefresh();
    _refreshTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (_selectedSessionId != null) {
        _refreshLiveData();
      }
    });
  }

  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> _refreshLiveData() async {
    if (_selectedUserId == null || _selectedSessionId == null) return;

    try {
      // Silently refresh live tracking data
      final liveData = await api.getLiveTracking(_selectedUserId!);
      final route = await api.getSessionRoute(
        _selectedUserId!,
        _selectedSessionId!,
      );
      final visitsResponse = await api.getSessionVisits(_selectedSessionId!);

      if (mounted) {
        setState(() {
          _liveTracking = liveData;
          _routeData = route;
          _visits = visitsResponse['visits'] ?? [];
        });
        _updateMapWithRoute(route);
      }
    } catch (e) {
      // Silently fail for auto-refresh
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

    // Start marker (Punch In) - Green
    markers.add(
      Marker(
        markerId: MarkerId('start'),
        position: points.first,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: '🟢 Punch In',
          snippet: _formatTime(session['punchInTime']),
        ),
      ),
    );

    // Current location marker (if session is active)
    if (session['isActive'] == true && _liveTracking != null) {
      final currentLoc = _liveTracking!['currentLocation'];
      if (currentLoc != null) {
        markers.add(
          Marker(
            markerId: MarkerId('current'),
            position: LatLng(currentLoc['latitude'], currentLoc['longitude']),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
            infoWindow: InfoWindow(
              title: '👤 Current Location',
              snippet:
                  'Battery: ${currentLoc['battery'] ?? 'N/A'}% • ${_formatTime(currentLoc['timestamp'])}',
            ),
          ),
        );
      }
    }

    // End marker (Punch Out) - Red (only if punched out)
    if (session['punchOutTime'] != null) {
      markers.add(
        Marker(
          markerId: MarkerId('end'),
          position: points.last,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: '🔴 Punch Out',
            snippet: _formatTime(session['punchOutTime']),
          ),
        ),
      );
    }

    // Visit markers - Orange
    for (var i = 0; i < _visits.length; i++) {
      final visit = _visits[i];
      markers.add(
        Marker(
          markerId: MarkerId('visit_${visit['id']}'),
          position: LatLng(visit['latitude'], visit['longitude']),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(
            title: '📍 ${visit['address'] ?? 'Visit ${i + 1}'}',
            snippet: visit['notes'] ?? _formatTime(visit['visitTime']),
          ),
        ),
      );
    }

    // Create polyline (route path)
    final polylines = <Polyline>{
      Polyline(
        polylineId: PolylineId('route'),
        points: points,
        color: Colors.blue,
        width: 5,
        geodesic: true,
      ),
    };

    setState(() {
      _markers = markers;
      _polylines = polylines;
    });

    // Animate camera - Focus on user's current location or punch-in location
    if (_mapController != null) {
      LatLng? focusLocation;
      double zoomLevel = 15.0;

      // Priority 1: Current location (if session is active)
      if (session['isActive'] == true && _liveTracking != null) {
        final currentLoc = _liveTracking!['currentLocation'];
        if (currentLoc != null &&
            currentLoc['latitude'] != null &&
            currentLoc['longitude'] != null) {
          focusLocation = LatLng(
            currentLoc['latitude'].toDouble(),
            currentLoc['longitude'].toDouble(),
          );
        }
      }

      // Priority 2: Punch-in location (if no current location)
      if (focusLocation == null && points.isNotEmpty) {
        focusLocation = points.first;
      }

      // Animate to focus location
      if (focusLocation != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(focusLocation, zoomLevel),
        );
      } else {
        // Fallback: Fit all points
        List<LatLng> allPoints = List.from(points);
        for (var visit in _visits) {
          allPoints.add(LatLng(visit['latitude'], visit['longitude']));
        }

        if (allPoints.length == 1) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(allPoints.first, zoomLevel),
          );
        } else if (allPoints.length > 1) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngBounds(_boundsFromLatLngList(allPoints), 80),
          );
        }
      }
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
                      myLocationButtonEnabled: false,
                      myLocationEnabled: false,
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
                                    _buildStatItem(
                                      Icons.place,
                                      'Visits',
                                      '${_visits.length}',
                                    ),
                                  ],
                                ),
                                if (session['isActive'] == true &&
                                    _liveTracking != null) ...[
                                  SizedBox(height: 8),
                                  Divider(),
                                  SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Live Tracking Active',
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        '• Auto-refresh every 10s',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    // Legend
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Legend',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(height: 4),
                              _buildLegendItem(Colors.green, 'Punch In'),
                              _buildLegendItem(Colors.red, 'Punch Out'),
                              _buildLegendItem(Colors.blue, 'Current'),
                              _buildLegendItem(Colors.orange, 'Visit'),
                              _buildLegendItem(
                                Colors.blue,
                                'Route',
                                isLine: true,
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

  Widget _buildLegendItem(Color color, String label, {bool isLine = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLine)
            Container(width: 20, height: 3, color: color)
          else
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 11)),
        ],
      ),
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
