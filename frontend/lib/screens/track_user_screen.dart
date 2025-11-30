import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/custom_button.dart';

class TrackUserScreen extends StatelessWidget {
  const TrackUserScreen({super.key});
  static const users = ["User A", "User B", "User C"]; // TODO: Fetch from API

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Track User")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: DropdownButtonFormField(
              decoration: InputDecoration(labelText: "Select User"),
              items: users.map((user) {
                return DropdownMenuItem(
                  value: user,
                  child: Text(user),
                );
              }).toList(),
              onChanged: (value) {},
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
                          child: Center(child: Text('Map will be shown here')),
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
