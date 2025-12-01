import 'package:flutter/material.dart';
import '../services/visit_service.dart';
import '../widgets/toast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class VisitsScreen extends StatefulWidget {
  const VisitsScreen({super.key});

  @override
  State<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends State<VisitsScreen> {
  final VisitService _visitService = VisitService();
  List<dynamic> _visits = [];
  bool _isLoading = true;
  String? _userId;
  String? _sessionId;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    _userId = args?['userId'];
    _sessionId = args?['sessionId'];
    _loadVisits();
  }

  Future<void> _loadVisits() async {
    if (_userId == null) return;

    setState(() => _isLoading = true);

    try {
      final visits = await _visitService.getUserVisits(
        _userId!,
        sessionId: _sessionId,
      );

      if (mounted) {
        setState(() {
          _visits = visits;
          _updateMarkers();
        });
      }
    } catch (e) {
      showToast('Failed to load visits: $e', error: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _updateMarkers() {
    _markers.clear();
    for (var i = 0; i < _visits.length; i++) {
      final visit = _visits[i];
      _markers.add(
        Marker(
          markerId: MarkerId(visit['id']),
          position: LatLng(visit['latitude'], visit['longitude']),
          infoWindow: InfoWindow(
            title: visit['address'] ?? 'Visit ${i + 1}',
            snippet: visit['notes'] ?? _formatTime(visit['visitTime']),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_sessionId != null ? 'Session Visits' : 'All Visits'),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadVisits),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _visits.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No visits marked yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Mark visits during your work day',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Map View
                Container(
                  height: 250,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        _visits[0]['latitude'],
                        _visits[0]['longitude'],
                      ),
                      zoom: 12,
                    ),
                    markers: _markers,
                    onMapCreated: (controller) {
                      _mapController = controller;
                      _fitMapToMarkers();
                    },
                  ),
                ),
                // List View
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(8),
                    itemCount: _visits.length,
                    itemBuilder: (context, index) {
                      final visit = _visits[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: Colors.blue.shade900,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            visit['address'] ?? 'Visit ${index + 1}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.access_time, size: 14),
                                  SizedBox(width: 4),
                                  Text(_formatTime(visit['visitTime'])),
                                ],
                              ),
                              if (visit['notes'] != null) ...[
                                SizedBox(height: 4),
                                Text(
                                  visit['notes'],
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey.shade700,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              SizedBox(height: 4),
                              Text(
                                'Lat: ${visit['latitude'].toStringAsFixed(6)}, '
                                'Lng: ${visit['longitude'].toStringAsFixed(6)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'view',
                                child: Row(
                                  children: [
                                    Icon(Icons.map, size: 20),
                                    SizedBox(width: 8),
                                    Text('View on Map'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'view') {
                                _viewOnMap(visit);
                              } else if (value == 'edit') {
                                _editVisit(visit);
                              } else if (value == 'delete') {
                                _deleteVisit(visit['id']);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  void _fitMapToMarkers() {
    if (_mapController == null || _visits.isEmpty) return;

    double minLat = _visits[0]['latitude'];
    double maxLat = _visits[0]['latitude'];
    double minLng = _visits[0]['longitude'];
    double maxLng = _visits[0]['longitude'];

    for (var visit in _visits) {
      if (visit['latitude'] < minLat) minLat = visit['latitude'];
      if (visit['latitude'] > maxLat) maxLat = visit['latitude'];
      if (visit['longitude'] < minLng) minLng = visit['longitude'];
      if (visit['longitude'] > maxLng) maxLng = visit['longitude'];
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50, // padding
      ),
    );
  }

  void _viewOnMap(dynamic visit) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(visit['latitude'], visit['longitude']),
        16,
      ),
    );
  }

  void _editVisit(dynamic visit) {
    final addressController = TextEditingController(
      text: visit['address'] ?? '',
    );
    final notesController = TextEditingController(text: visit['notes'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Visit'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: 'Location Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _updateVisit(
                visit['id'],
                address: addressController.text.trim(),
                notes: notesController.text.trim(),
              );
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateVisit(
    String visitId, {
    String? address,
    String? notes,
  }) async {
    try {
      await _visitService.updateVisit(
        visitId,
        address: address?.isNotEmpty == true ? address : null,
        notes: notes?.isNotEmpty == true ? notes : null,
      );
      showToast('✓ Visit updated');
      _loadVisits();
    } catch (e) {
      showToast('Failed to update visit: $e', error: true);
    }
  }

  Future<void> _deleteVisit(String visitId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Visit'),
        content: Text('Are you sure you want to delete this visit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _visitService.deleteVisit(visitId);
        showToast('✓ Visit deleted');
        _loadVisits();
      } catch (e) {
        showToast('Failed to delete visit: $e', error: true);
      }
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }
}
