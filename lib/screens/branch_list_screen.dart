import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:umayumcha/controllers/auth_controller.dart';
import 'package:umayumcha/controllers/branch_controller.dart';
import 'package:umayumcha/screens/branch_form_screen.dart';
import 'package:umayumcha/widgets/delete_confirmation_dialog.dart'; // Import the new dialog

class BranchListScreen extends StatelessWidget {
  final BranchController controller = Get.find();
  final AuthController authController = Get.find();

  BranchListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Cabang'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      floatingActionButton: Obx(() {
        return authController.userRole.value == 'admin'
            ? FloatingActionButton(
                onPressed: () => Get.to(() => const BranchFormScreen()),
                child: const Icon(Icons.add),
              )
            : const SizedBox.shrink();
      }),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.branches.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.store_mall_directory, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('Belum ada cabang', style: TextStyle(fontSize: 18, color: Colors.grey)),
                Text('Silakan tambahkan cabang baru', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: controller.branches.length,
          itemBuilder: (context, index) {
            final branch = controller.branches[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: InkWell(
                onTap: () => Get.to(() => BranchFormScreen(branch: branch)),
                borderRadius: BorderRadius.circular(15),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.store, color: Theme.of(context).colorScheme.primary, size: 40),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              branch.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              branch.address ?? 'No Address',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      Obx(() {
                        return authController.userRole.value == 'admin'
                            ? (branch.name == 'UmayumchaHQ'
                                ? IconButton(
                                    icon: Icon(Icons.delete, color: Colors.grey[400]), // Grey out icon
                                    onPressed: null, // Disable button
                                  )
                                : IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red[400]),
                                    onPressed: () {
                                      if (branch.id != null) {
                                        showDeleteConfirmationDialog(
                                          title: "Hapus Cabang",
                                          content: "Apakah Anda yakin ingin menghapus cabang '${branch.name}'?",
                                          onConfirm: () {
                                            controller.deleteBranch(branch.id!); 
                                          },
                                        );
                                      } else {
                                        Get.snackbar('Error', 'ID Cabang tidak ditemukan.');
                                      }
                                    },
                                  ))
                            : const SizedBox.shrink();
                      }),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
