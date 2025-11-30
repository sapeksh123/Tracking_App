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
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final api = ApiService();
    try {
      await api.createUser(nameController.text.trim(), email: emailController.text.trim(), phone: phoneController.text.trim());
      if (!mounted) return;
      setState(() => _loading = false);
      showToast('User created successfully');
      nameController.clear();
      emailController.clear();
      phoneController.clear();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showToast((e is ApiException) ? e.message : 'Create user failed', error: true);
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  ListTile(
                    leading: Icon(FontAwesomeIcons.userPlus, color: Theme.of(context).colorScheme.primary),
                    title: Text('Create user', style: Theme.of(context).textTheme.titleLarge),
                  ),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person)),
                    validator: (s) => (s == null || s.trim().isEmpty) ? 'Name required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                    validator: (s) {
                      if (s == null || s.trim().isEmpty) return null; // optional
                      final emailRegex = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$");
                      return emailRegex.hasMatch(s.trim()) ? null : 'Invalid email';
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_android)),
                    validator: (s) => (s == null || s.trim().isEmpty) ? null : ((s.trim().length < 7) ? 'Invalid phone' : null),
                  ),
                  const SizedBox(height: 20),
                  RoundedButton(label: _loading ? 'Creating...' : 'Create User', icon: FontAwesomeIcons.plus, onPressed: _loading ? null : createUser),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
