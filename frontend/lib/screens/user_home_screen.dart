import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/custom_button.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/toast.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  bool isTracking = false;
  String? userId;
  final userController = TextEditingController();
  final api = ApiService();
  late final LocationService locationService;

  void toggleTracking() {
    setState(() {
      isTracking = !isTracking;
    });
    if (isTracking) {
      // start a single ping for demo
      _sendPing();
    }
  }

  @override
  void initState() {
    super.initState();
    locationService = LocationService(api: api);
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('localUserId');
    if (userId != null) userController.text = userId!;
    setState(() {});
  }

  Future<void> _saveUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('localUserId', userController.text.trim());
    setState(() {
      userId = userController.text.trim();
    });
    showToast('User ID saved');
  }

  Future<void> _sendPing() async {
    if (userId == null || userId!.isEmpty) {
      showToast('Please set your user id first', error: true);
      return;
    }
    try {
      final res = await locationService.sendPing(userId!);
      showToast('Location sent (${res['id']})');
    } catch (e) {
      showToast('Ping failed: ${(e is ApiException) ? e.message : e.toString()}', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("User Home")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FontAwesomeIcons.route, color: Theme.of(context).colorScheme.primary, size: 48),
                  SizedBox(height: 12),
                  Text(isTracking ? "Tracking ON" : "Tracking OFF", style: Theme.of(context).textTheme.headlineSmall),
                  SizedBox(height: 12),
                  Text(isTracking ? 'Your live location is being shared' : 'You are not currently tracking', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                  SizedBox(height: 20),
                  RoundedButton(
                    label: isTracking ? 'Stop Tracking' : 'Start Tracking',
                    icon: isTracking ? Icons.stop : Icons.play_arrow,
                    onPressed: toggleTracking,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: userController,
                    decoration: InputDecoration(labelText: 'Your User ID', prefixIcon: Icon(Icons.person_outline)),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: RoundedButton(label: 'Save User ID', icon: Icons.save, onPressed: _saveUserId)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
