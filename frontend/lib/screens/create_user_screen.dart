import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/custom_button.dart';
import '../services/api_service.dart';
import '../widgets/toast.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  Future<void> createUser() async {
    if (!_formKey.currentState!.validate()) {
      showToast('Please fill in all required fields', error: true);
      return;
    }

    setState(() => _loading = true);
    final api = ApiService();

    try {
      final response = await api.createUser(
        nameController.text.trim(),
        email: emailController.text.trim().isEmpty
            ? null
            : emailController.text.trim(),
        phone: phoneController.text.trim().isEmpty
            ? null
            : phoneController.text.trim(),
      );

      if (!mounted) return;

      // Extract user info from response
      final userName = response['user']?['name'] ?? response['name'] ?? 'User';

      // Clear form first
      nameController.clear();
      emailController.clear();
      phoneController.clear();

      setState(() => _loading = false);

      // Show success message
      showToast('✓ User "$userName" created successfully');

      // Optional: Navigate back or show dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User created successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);

      final errorMessage = (e is ApiException)
          ? e.message
          : 'Failed to create user';
      showToast(errorMessage, error: true);

      // Show detailed error in snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create User')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  ListTile(
                    leading: Icon(
                      FontAwesomeIcons.userPlus,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      'Create user',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (s) => (s == null || s.trim().isEmpty)
                        ? 'Name required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (s) {
                      if (s == null || s.trim().isEmpty) {
                        return null; // optional
                      }
                      final emailRegex = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$");
                      return emailRegex.hasMatch(s.trim())
                          ? null
                          : 'Invalid email format';
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    decoration: const InputDecoration(
                      labelText: 'Phone (10 digits)',
                      prefixIcon: Icon(Icons.phone_android),
                      hintText: '9876543210',
                      counterText: '',
                    ),
                    validator: (s) {
                      if (s == null || s.trim().isEmpty) {
                        return null; // optional
                      }
                      final cleaned = s.trim().replaceAll(
                        RegExp(r'[^0-9]'),
                        '',
                      );
                      if (cleaned.length != 10) {
                        return 'Phone must be exactly 10 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  RoundedButton(
                    label: _loading ? 'Creating...' : 'Create User',
                    icon: FontAwesomeIcons.plus,
                    onPressed: _loading ? null : createUser,
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
