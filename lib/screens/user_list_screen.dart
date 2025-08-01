
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:umayumcha_ims/controllers/user_controller.dart';
import 'package:umayumcha_ims/controllers/auth_controller.dart';
import 'package:umayumcha_ims/screens/user_form_screen.dart';
import 'package:umayumcha_ims/widgets/delete_confirmation_dialog.dart'; // Import the new dialog

class UserListScreen extends StatelessWidget {

  final UserController userController = Get.find();
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
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Text(user.email,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      subtitle: Text('Role: ${user.role}',
                          style: Theme.of(context).textTheme.bodyMedium),
                      onTap: () => Get.to(() => UserFormScreen(user: user)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            tooltip: 'Edit User',
                            onPressed: () => Get.to(() => UserFormScreen(user: user)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            tooltip: 'Delete User',
                            onPressed: () => showDeleteConfirmationDialog(
                                  title: "Delete User",
                                  content: "Are you sure you want to delete user '${user.email}'?",
                                  onConfirm: () {
                                    userController.deleteUser(user.id);
                                  },
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
      floatingActionButton: Obx(() {
        if (authController.userRole.value == 'admin') {
          return FloatingActionButton(
            onPressed: () => Get.to(() => const UserFormScreen()),
            tooltip: 'Add New User',
            child: const Icon(Icons.person_add),
          );
        }
        return const SizedBox.shrink();
      }),
    );
  }
}
