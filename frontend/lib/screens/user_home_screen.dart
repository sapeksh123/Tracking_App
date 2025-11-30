import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/custom_button.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  bool isTracking = false;

  void toggleTracking() {
    setState(() {
      isTracking = !isTracking;
    });
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
