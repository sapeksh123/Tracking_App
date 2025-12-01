import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/api_service.dart';
import '../widgets/toast.dart';

class TrackUserScreen extends StatefulWidget {
  const TrackUserScreen({super.key});

  @override
  State<TrackUserScreen> createState() => _TrackUserScreenState();
}

class _TrackUserScreenState extends State<TrackUserScreen> {
  final api = ApiService();
  bool _loading = true;
  bool _loadingRoute = false;
  List<dynamic> _users = [];
  String? _selectedUserId;
  String? _selectedUserName;
  Map<String, dynamic>? _routeData;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  // Default location (India center)
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

  Future<void> _loadRouteForUser(String id, String name) async {
    setState(() => _loadingRoute = true);
    try {
      final route = await api.getRoute(id);
      if (mounted) {
        setState(() {
          _routeData = route;
          _selectedUserName = name;
        });
        _updateMapWithRoute(route);
        showToast('Route loaded for $name');
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

  void _updateMapWithRoute(Map<String, dynamic> route) {
    final geometry = route['geometry'];
    if (geometry == null || geometry['coordinates'] == null) {
      showToast('No location data available', error: true);
      return;
    }

    final coordinates = geometry['coordinates'] as List;
    if (coordinates.isEmpty) {
      showToast('No location points found', error: true);
      return;
    }

    // Convert coordinates to LatLng
    List<LatLng> points = [];
    for (var coord in coordinates) {
      if (coord is List && coord.length >= 2) {
        // GeoJSON format is [longitude, latitude]
        points.add(LatLng(coord[1], coord[0]));
      }
    }

    if (points.isEmpty) return;

    // Create markers for start and end
    final markers = <Marker>{};
    markers.add(
      Marker(
        markerId: MarkerId('start'),
        position: points.first,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: 'Start', snippet: 'Journey begins here'),
      ),
    );

    if (points.length > 1) {
      markers.add(
        Marker(
          markerId: MarkerId('end'),
          position: points.last,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: 'End', snippet: 'Current location'),
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

    // Animate camera to show the route
    if (_mapController != null && points.isNotEmpty) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          _boundsFromLatLngList(points),
          50, // padding
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
    return Scaffold(
      appBar: AppBar(
        title: Text("Track User"),
        actions: [
          if (_selectedUserId != null)
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                final user = _users.firstWhere(
                  (u) => u['id'] == _selectedUserId,
                  orElse: () => null,
                );
                if (user != null) {
                  _loadRouteForUser(_selectedUserId!, user['name'] ?? 'User');
                }
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
                                setState(() => _selectedUserId = value);
                                final user = _users.firstWhere(
                                  (u) => u['id'] == value,
                                );
                                _loadRouteForUser(
                                  value,
                                  user['name'] ?? 'User',
                                );
                              }
                            },
                          ),
                    if (_selectedUserName != null) ...[
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.grey,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Tracking: $_selectedUserName',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
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
                    if (_routeData != null && !_loadingRoute)
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem(
                                  Icons.location_on,
                                  'Points',
                                  '${_routeData!['properties']?['count'] ?? 0}',
                                ),
                                _buildStatItem(
                                  Icons.person,
                                  'User',
                                  _selectedUserName ?? 'Unknown',
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
}
