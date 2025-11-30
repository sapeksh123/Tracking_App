import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/toast.dart';
import 'package:provider/provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _loading = true;
  List<dynamic> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _loading = true);
    try {
      final api = ApiService();
      final users = await api.listUsers();
      setState(() => _users = users);
    } catch (e) {
      showToast('Failed to load users', error: true);
    } finally {
      setState(() => _loading = false);
    }
  }

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
              onTap: () async {
                final auth = Provider.of<AuthService>(context, listen: false);
                final navigator = Navigator.of(context);
                await auth.logout();
                if (!mounted) return;
                navigator.pushReplacementNamed("/admin-login");
              },
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
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                children: [
                  Expanded(
                    child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  _buildCard(context, "Create User", FontAwesomeIcons.userPlus, () => Navigator.pushNamed(context, "/create-user")),
                  _buildCard(context, "Track User", FontAwesomeIcons.locationDot, () => Navigator.pushNamed(context, "/track-user")),
                  _buildCard(context, "Users (${_users.length})", FontAwesomeIcons.users, () {}),
                  _buildCard(context, "Settings", FontAwesomeIcons.gear, () {}),
                ],
                    ),
                  ),
                  SizedBox(height: 12),
                  Text('Recent users', style: Theme.of(context).textTheme.titleMedium),
                  SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: _users.isEmpty
                        ? Center(child: Text('No users yet'))
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            itemBuilder: (c, i) => Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_users[i]['name'] ?? 'Unknown', style: Theme.of(context).textTheme.titleMedium),
                                    SizedBox(height: 6),
                                    Text(_users[i]['email'] ?? '', style: Theme.of(context).textTheme.bodySmall),
                                    SizedBox(height: 4),
                                    Text(_users[i]['phone'] ?? '', style: Theme.of(context).textTheme.bodySmall),
                                  ],
                                ),
                              ),
                            ),
                            separatorBuilder: (_, __) => SizedBox(width: 8),
                            itemCount: _users.length,
                          ),
                  ),
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
