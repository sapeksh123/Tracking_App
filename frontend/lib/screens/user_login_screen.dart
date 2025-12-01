import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../widgets/custom_button.dart';
import '../services/api_service.dart';
import '../widgets/toast.dart';

class UserLoginScreen extends StatefulWidget {
  const UserLoginScreen({super.key});

  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  Future<void> loginUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);

    try {
      final api = ApiService();
      final result = await api.userLogin(
        phoneController.text.trim(),
        passwordController.text.trim(),
      );

      // Store user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', result['token']);
      await prefs.setString('user', jsonEncode(result['user']));
      await prefs.setString('userRole', 'user');

      if (!mounted) return;

      showToast('✓ Login successful!');
      Navigator.pushReplacementNamed(context, "/user-home");
    } catch (e) {
      if (!mounted) return;

      final errorMessage = (e is ApiException)
          ? e.message
          : 'Login failed. Please check your credentials.';

      showToast(errorMessage, error: true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    FontAwesomeIcons.circleUser,
                    color: Theme.of(context).colorScheme.primary,
                    size: 48,
                  ),
                  SizedBox(height: 12),
                  Text(
                    "User Login",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 24),

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          decoration: InputDecoration(
                            labelText: "Phone",
                            prefixIcon: Icon(Icons.phone),
                            hintText: '9876543210',
                            counterText: '',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Phone number required';
                            }
                            if (value.trim().length != 10) {
                              return 'Phone must be 10 digits';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 12),
                        TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: Icon(Icons.lock_outline),
                            hintText: 'Default: your phone number',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Password required';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),
                  RoundedButton(
                    label: _loading ? "Logging in..." : "Login",
                    icon: Icons.arrow_forward,
                    onPressed: _loading ? null : loginUser,
                    fullWidth: true,
                  ),
                  SizedBox(height: 12),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/admin-login'),
                    child: const Text('Login as admin instead'),
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
