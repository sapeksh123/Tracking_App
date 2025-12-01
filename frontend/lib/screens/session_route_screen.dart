import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/attendance_service.dart';
import '../widgets/toast.dart';

class SessionRouteScreen extends StatefulWidget {
  final String sessionId;
  final String userId;

  const SessionRouteScreen({
    super.key,
    required this.sessionId,
    required this.userId,
  });

  @override
  State<SessionRouteScreen> createState() => _SessionRouteScreenState();
}

class _SessionRouteScreenState extends State<SessionRouteScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  GoogleMapController? _mapController;
  bool _loading = true;
  Map<String, dynamic>? _sessionData;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(20.5937, 78.9629),
    zoom: 5,
  );

  @override
  void initState() {
    super.initState();
    _loadSessionRoute();
  }

  Future<void> _loadSessionRoute() async {
    setState(() => _loading = true);

    try {
      await _attendanceService.initialize(widget.userId);
      final response = await _attendanceService.getSessionRoute(
        widget.sessionId,
      );

      if (mounted) {
        setState(() {
          _sessionData = response;
        });
        _updateMapWithRoute(response);
      }
    } catch (e) {
      if (mounted) {
        showToast('Failed to load session route: $e', error: true);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
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
        // GeoJSON format is [longitude, latitude, timestamp, battery]
        points.add(LatLng(coord[1], coord[0]));
      }
    }

    if (points.isEmpty) return;

    // Create markers
    final markers = <Marker>{};

    // Start marker (Punch In)
    markers.add(
      Marker(
        markerId: MarkerId('punch_in'),
        position: points.first,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Punch In',
          snippet: 'Started at ${_formatTime(session['punchInTime'])}',
        ),
      ),
    );

    // End marker (Punch Out) - only if session is completed
    if (points.length > 1 && session['punchOutTime'] != null) {
      markers.add(
        Marker(
          markerId: MarkerId('punch_out'),
          position: points.last,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Punch Out',
            snippet: 'Ended at ${_formatTime(session['punchOutTime'])}',
          ),
        ),
      );
    }

    // Add intermediate markers for significant points
    if (points.length > 10) {
      final step = points.length ~/ 5; // Show 5 intermediate points
      for (int i = step; i < points.length - step; i += step) {
        markers.add(
          Marker(
            markerId: MarkerId('point_$i'),
            position: points[i],
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
            infoWindow: InfoWindow(
              title: 'Checkpoint',
              snippet: 'Point ${i + 1} of ${points.length}',
            ),
          ),
        );
      }
    }

    // Create polyline
    final polylines = <Polyline>{
      Polyline(
        polylineId: PolylineId('session_route'),
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

    // Animate camera to show the route
    if (_mapController != null && points.isNotEmpty) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          _boundsFromLatLngList(points),
          100, // padding
        ),
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
    final session = _sessionData?['session'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Session Route'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadSessionRoute,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Session Info Card
                if (session != null)
                  Container(
                    margin: EdgeInsets.all(16),
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  FontAwesomeIcons.route,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Session Details',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem(
                                  Icons.access_time,
                                  'Duration',
                                  _attendanceService.formatDuration(
                                    session['totalDuration'],
                                  ),
                                  Colors.blue,
                                ),
                                _buildStatItem(
                                  Icons.route,
                                  'Distance',
                                  _attendanceService.formatDistance(
                                    session['totalDistance'],
                                  ),
                                  Colors.orange,
                                ),
                                _buildStatItem(
                                  Icons.location_on,
                                  'Points',
                                  '${_sessionData?['route']?['properties']?['pointCount'] ?? 0}',
                                  Colors.purple,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Map
                Expanded(
                  child: Container(
                    margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: GoogleMap(
                        initialCameraPosition: _initialPosition,
                        markers: _markers,
                        polylines: _polylines,
                        onMapCreated: (controller) {
                          _mapController = controller;
                        },
                        myLocationButtonEnabled: true,
                        zoomControlsEnabled: true,
                        mapToolbarEnabled: true,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
        Icon(icon, color: color, size: 24),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
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

  @override
  void dispose() {
    _mapController?.dispose();
    _attendanceService.dispose();
    super.dispose();
  }
}
