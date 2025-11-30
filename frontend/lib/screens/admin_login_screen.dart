import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/custom_button.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import '../widgets/toast.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  Future<void> loginAdmin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    try {
      await auth.login(emailController.text.trim(), passwordController.text.trim());
      if (!mounted) return;
      setState(() => _loading = false);
      showToast('Login successful');
      Navigator.pushReplacementNamed(context, '/admin-dashboard');
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showToast((e is ApiException) ? e.message : 'Login failed', error: true);
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(FontAwesomeIcons.shieldHalved, color: Theme.of(context).colorScheme.primary, size: 48),
                    SizedBox(height: 12),
                    Text('Admin Login', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    SizedBox(height: 24),
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                      validator: (s) => (s == null || s.trim().isEmpty) ? 'Email required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                      validator: (s) => (s == null || s.trim().isEmpty) ? 'Password required' : null,
                    ),
                    const SizedBox(height: 20),
                    RoundedButton(
                      label: _loading ? 'Signing in...' : 'Login',
                      icon: Icons.arrow_forward,
                      onPressed: _loading ? null : loginAdmin,
                      fullWidth: true,
                    ),
                    const SizedBox(height: 12),
                    TextButton(onPressed: () => Navigator.pushNamed(context, '/user-login'), child: const Text('Login as user instead'))
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
