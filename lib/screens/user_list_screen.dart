
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:umayumcha/controllers/user_controller.dart';
import 'package:umayumcha/controllers/auth_controller.dart';
import 'package:umayumcha/screens/user_form_screen.dart';

class UserListScreen extends StatelessWidget {
  final UserController userController = Get.put(UserController());
  final AuthController authController = Get.find();

  UserListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Only allow admin to access this screen
    if (authController.userRole.value != 'admin') {
      return Scaffold(
        appBar: AppBar(title: const Text('Master User')),
        body: const Center(
          child: Text('Access Denied: Only administrators can view this page.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Master User'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => Get.to(() => const UserFormScreen()),
          ),
        ],
      ),
      body: Obx(() {
        if (userController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (userController.users.isEmpty) {
          return const Center(child: Text('No users found.'));
        }
        return ListView.builder(
          itemCount: userController.users.length,
          itemBuilder: (context, index) {
            final user = userController.users[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(user.email),
                subtitle: Text('Role: ${user.role}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => Get.to(() => UserFormScreen(user: user)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => userController.deleteUser(user.id),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
