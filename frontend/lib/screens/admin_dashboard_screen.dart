import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Dashboard"),
        centerTitle: false,
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary]),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FontAwesomeIcons.userShield, color: Colors.white, size: 28),
                  SizedBox(height: 8),
                  Text("Admin Menu", style: TextStyle(fontSize: 22, color: Colors.white)),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.person_add),
              title: Text("Create User"),
              onTap: () => Navigator.pushNamed(context, "/create-user"),
            ),
            ListTile(
              leading: Icon(Icons.location_on),
              title: Text("Track User"),
              onTap: () => Navigator.pushNamed(context, "/track-user"),
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text("Logout"),
              onTap: () =>
                  Navigator.pushReplacementNamed(context, "/admin-login"),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 12),
            Text('Overview', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 12),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  _buildCard(context, "Create User", FontAwesomeIcons.userPlus, () => Navigator.pushNamed(context, "/create-user")),
                  _buildCard(context, "Track User", FontAwesomeIcons.locationDot, () => Navigator.pushNamed(context, "/track-user")),
                  _buildCard(context, "Users", FontAwesomeIcons.users, () {}),
                  _buildCard(context, "Settings", FontAwesomeIcons.gear, () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
              SizedBox(height: 12),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [Icon(Icons.arrow_forward, color: Colors.grey),],
              )
            ],
          ),
        ),
      ),
    );
  }
}
