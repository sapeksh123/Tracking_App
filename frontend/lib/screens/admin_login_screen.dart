import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/custom_button.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void loginAdmin() {
    // Simple direct navigation (we will add API later)
    Navigator.pushReplacementNamed(context, "/admin-dashboard");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FontAwesomeIcons.shieldHalved, color: Theme.of(context).colorScheme.primary, size: 48),
                  SizedBox(height: 12),
                  Text("Admin Login",
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  SizedBox(height: 24),

                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email_outlined)),
                  ),

                  SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(labelText: "Password", prefixIcon: Icon(Icons.lock_outline)),
                  ),

                  SizedBox(height: 20),
                  RoundedButton(
                    label: "Login",
                    icon: Icons.arrow_forward,
                    onPressed: loginAdmin,
                  ),

                  SizedBox(height: 12),
                  TextButton(
                      onPressed: () => Navigator.pushNamed(context, "/user-login"),
                      child: Text("Login as user instead")),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
