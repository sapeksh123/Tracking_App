import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/custom_button.dart';
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
  List<dynamic> _users = [];
  String? _selectedUserId;
  Map<String, dynamic>? _routeData;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final users = await api.listUsers();
      setState(() => _users = users);
    } catch (e) {
      showToast('Failed loading users', error: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadRouteForUser(String id) async {
    try {
      final route = await api.getRoute(id);
      setState(() => _routeData = route);
    } catch (e) {
      showToast('Failed to load route', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Track User")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: _loading
              ? const Center(child: CircularProgressIndicator())
              : DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: "Select User"),
                  initialValue: _selectedUserId,
                  isExpanded: true,
              items: _users.map<DropdownMenuItem<String>>((user) {
                return DropdownMenuItem(
                  value: user['id'] as String,
                  child: Text(user['name'] ?? user['id']),
                );
              }).toList(),
                onChanged: (value) {
                  setState(() => _selectedUserId = value);
                  if (value != null) _loadRouteForUser(value);
              },
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(FontAwesomeIcons.mapLocationDot, color: Theme.of(context).colorScheme.primary),
                          SizedBox(width: 12),
                          Text('User Map', style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                      SizedBox(height: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _routeData == null ? Center(child: Text('Map will be shown here')) : Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SingleChildScrollView(child: Text('Route points: ${_routeData!['properties']?['count'] ?? 0}')),
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      RoundedButton(label: 'Refresh Location', icon: Icons.refresh, onPressed: () {}),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
