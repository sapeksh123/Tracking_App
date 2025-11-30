import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/custom_button.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  void createUser() {
    // TODO: Call backend API
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("User Created Successfully!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Create User")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(FontAwesomeIcons.userPlus, color: Theme.of(context).colorScheme.primary),
                  title: Text('Create user', style: Theme.of(context).textTheme.titleLarge),
                ),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: "Name", prefixIcon: Icon(Icons.person)),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email_outlined)),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(labelText: "Phone", prefixIcon: Icon(Icons.phone_android)),
                ),
                SizedBox(height: 20),
                RoundedButton(label: 'Create User', icon: FontAwesomeIcons.plus, onPressed: createUser),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
