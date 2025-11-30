import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/custom_button.dart';

class UserLoginScreen extends StatefulWidget {
  const UserLoginScreen({super.key});

  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  void loginUser() {
    Navigator.pushReplacementNamed(context, "/user-home");
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
                  Icon(FontAwesomeIcons.circleUser, color: Theme.of(context).colorScheme.primary, size: 48),
                  SizedBox(height: 12),
                  Text("User Login",
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  SizedBox(height: 24),

                  TextField(
                    controller: phoneController,
                    decoration: InputDecoration(labelText: "Phone", prefixIcon: Icon(Icons.phone)),
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
                    onPressed: loginUser,
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
  