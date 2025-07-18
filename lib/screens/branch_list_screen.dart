import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:umayumcha/controllers/branch_controller.dart';
import 'package:umayumcha/screens/branch_form_screen.dart';

class BranchListScreen extends StatelessWidget {
  final BranchController controller = Get.find();

  BranchListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Cabang'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Get.to(() => const BranchFormScreen()),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.branches.isEmpty) {
          return const Center(child: Text('No branches found.'));
        }
        return ListView.builder(
          itemCount: controller.branches.length,
          itemBuilder: (context, index) {
            final branch = controller.branches[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: Text(branch.name),
                subtitle: Text(branch.address ?? 'No Address'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed:
                          () => Get.to(() => BranchFormScreen(branch: branch)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => controller.deleteBranch(branch.id),
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
