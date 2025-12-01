import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/attendance_service.dart';
import '../widgets/toast.dart';

class SessionRouteScreenEnhanced extends StatefulWidget {
  final String sessionId;
  final String userId;

  const SessionRouteScreenEnhanced({
    super.key,
    required this.sessionId,
    required this.userId,
  });

  @override
  State<SessionRouteScreenEnhanced> createState() =>
      _SessionRouteScreenEnhancedState();
}

class _SessionRouteScreenEnhancedState
    extends State<SessionRouteScreenEnhanced> {
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
        points.add(LatLng(coord[1], coord[0]));
      }
    }

    if (points.isEmpty) return;

    // Create markers
    final markers = <Marker>{};

    // Start marker
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

    // End marker
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

    // Intermediate markers
    if (points.length > 10) {
      final step = points.length ~/ 5;
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

    // Animate camera
    if (_mapController != null && points.isNotEmpty) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(_boundsFromLatLngList(points), 100),
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
          : SingleChildScrollView(
              child: Column(
                children: [
                  if (session != null) ...[
                    // Session Summary Card
                    _buildSummaryCard(session),

                    // Map Card
                    _buildMapCard(),

                    // Location Details Card
                    _buildLocationCard(session),

                    // Battery & Stats Card
                    _buildBatteryStatsCard(session),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> session) {
    return Container(
      margin: EdgeInsets.all(16),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    FontAwesomeIcons.clockFour,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Session Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Divider(height: 24),

              // Time Details
              _buildDetailRow(
                Icons.login,
                'Punch In',
                _formatDateTime(session['punchInTime']),
                Colors.green,
              ),
              SizedBox(height: 8),
              _buildDetailRow(
                Icons.logout,
                'Punch Out',
                session['punchOutTime'] != null
                    ? _formatDateTime(session['punchOutTime'])
                    : 'Active',
                Colors.red,
              ),

              Divider(height: 24),

              // Stats Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    Icons.access_time,
                    'Duration',
                    _attendanceService.formatDuration(session['totalDuration']),
                    Colors.blue,
                  ),
                  _buildStatItem(
                    Icons.route,
                    'Distance',
                    _attendanceService.formatDistance(session['totalDistance']),
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
    );
  }

  Widget _buildMapCard() {
    return Container(
      height: 400,
      margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    );
  }

  Widget _buildLocationCard(Map<String, dynamic> session) {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Location Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 16),
              _buildLocationInfo(
                'Punch In Location',
                session['punchInLocation'],
                session['punchInAddress'],
                Colors.green,
              ),
              if (session['punchOutLocation'] != null) ...[
                SizedBox(height: 12),
                _buildLocationInfo(
                  'Punch Out Location',
                  session['punchOutLocation'],
                  session['punchOutAddress'],
                  Colors.red,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBatteryStatsCard(Map<String, dynamic> session) {
    final punchInBattery = session['punchInBattery'];
    final punchOutBattery = session['punchOutBattery'];
    final batteryDrop = (punchInBattery != null && punchOutBattery != null)
        ? punchInBattery - punchOutBattery
        : null;

    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.battery_charging_full,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Battery & Statistics',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBatteryInfo('Start', punchInBattery, Colors.green),
                  if (punchOutBattery != null)
                    _buildBatteryInfo('End', punchOutBattery, Colors.red),
                  if (batteryDrop != null)
                    _buildBatteryInfo('Used', batteryDrop, Colors.orange),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        SizedBox(width: 8),
        Expanded(child: Text(value, style: TextStyle(fontSize: 14))),
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
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildLocationInfo(
    String title,
    String? location,
    String? address,
    Color color,
  ) {
    if (location == null) return SizedBox.shrink();

    final coords = location.split(',');
    final lat = coords.length > 0 ? coords[0] : 'N/A';
    final lng = coords.length > 1 ? coords[1] : 'N/A';

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.place, size: 16, color: color),
              SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text('Lat: $lat', style: TextStyle(fontSize: 12)),
          Text('Lng: $lng', style: TextStyle(fontSize: 12)),
          if (address != null && address.isNotEmpty) ...[
            SizedBox(height: 4),
            Text(
              address,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBatteryInfo(String label, int? battery, Color color) {
    return Column(
      children: [
        Icon(
          battery != null && battery > 50
              ? Icons.battery_full
              : battery != null && battery > 20
              ? Icons.battery_std
              : Icons.battery_alert,
          color: color,
          size: 32,
        ),
        SizedBox(height: 4),
        Text(
          battery != null ? '$battery%' : 'N/A',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  String _formatDateTime(String? dateStr) {
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

  @override
  void dispose() {
    _mapController?.dispose();
    _attendanceService.dispose();
    super.dispose();
  }
}
