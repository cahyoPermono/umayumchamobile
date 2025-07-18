
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:umayumcha/controllers/user_controller.dart';
import 'package:umayumcha/models/profile_model.dart';

class UserFormScreen extends StatefulWidget {
  final Profile? user;

  const UserFormScreen({super.key, this.user});

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final UserController userController = Get.find();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _passwordController = TextEditingController(); // Password is not pre-filled for security
    _selectedRole = widget.user?.role;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user == null ? 'Add User' : 'Edit User'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                enabled: widget.user == null, // Email cannot be changed for existing users
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  if (!GetUtils.isEmail(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              if (widget.user == null) // Password only for new users
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) {
                    if (widget.user == null && (value == null || value.isEmpty)) {
                      return 'Please enter a password';
                    }
                    if (widget.user == null && value!.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Super User (Admin)')),
                  DropdownMenuItem(value: 'authenticated', child: Text('User (Authenticated)')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a role';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    if (widget.user == null) {
                      userController.createUser(
                        email: _emailController.text,
                        password: _passwordController.text,
                        role: _selectedRole!,
                      );
                    } else {
                      userController.updateUserRole(
                        userId: widget.user!.id,
                        newRole: _selectedRole!,
                      );
                    }
                  }
                },
                child: Text(widget.user == null ? 'Add User' : 'Update User'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
