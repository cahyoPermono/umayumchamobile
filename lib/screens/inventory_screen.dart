import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:umayumcha/controllers/auth_controller.dart';
import 'package:umayumcha/controllers/inventory_controller.dart';
import 'package:umayumcha/controllers/branch_controller.dart';
import 'package:umayumcha/models/branch_model.dart'; // Import Branch model
import 'package:umayumcha/models/branch_product_model.dart';
import 'package:umayumcha/screens/product_form_screen.dart';

void _showTransactionDialog(
  BuildContext context,
  BranchProduct branchProduct,
  String type,
) {
  final InventoryController controller = Get.find();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();

  Get.dialog(
    AlertDialog(
      title: Text(
        '${type == 'in' ? 'Add' : 'Remove'} Stock for ${branchProduct.product?.name ?? 'N/A'}',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: quantityController,
            decoration: const InputDecoration(labelText: 'Quantity'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: reasonController,
            decoration: const InputDecoration(labelText: 'Reason (Optional)'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final int? quantity = int.tryParse(quantityController.text);
            if (quantity != null && quantity > 0) {
              controller.addTransaction(
                productId: branchProduct.productId,
                type: type,
                quantityChange: quantity,
                reason: reasonController.text.trim(),
                fromBranchId: type == 'out' ? branchProduct.branchId : null,
                toBranchId: type == 'in' ? branchProduct.branchId : null,
              );
              Get.back(); // Close dialog
            } else {
              Get.snackbar('Error', 'Please enter a valid quantity.');
            }
          },
          child: Text(type == 'in' ? 'Add' : 'Remove'),
        ),
      ],
    ),
  );
}

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final InventoryController inventoryController = Get.find();
    final BranchController branchController = Get.find();
    final AuthController authController = Get.find();

    return Scaffold(
      appBar: AppBar(title: const Text('Master Inventory')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Obx(() {
              if (branchController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (branchController.branches.isEmpty) {
                return const Center(
                  child: Text(
                    'No branches available. Please add a branch first.',
                  ),
                );
              }
              return DropdownButtonFormField<Branch>(
                decoration: const InputDecoration(labelText: 'Select Branch'),
                value: inventoryController.selectedBranch.value,
                onChanged: (Branch? newValue) {
                  inventoryController.selectedBranch.value = newValue;
                },
                items:
                    branchController.branches.map((branch) {
                      return DropdownMenuItem<Branch>(
                        value: branch,
                        child: Text(branch.name),
                      );
                    }).toList(),
              );
            }),
          ),
          Expanded(
            child: Obx(() {
              if (inventoryController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (inventoryController.selectedBranch.value == null) {
                return const Center(
                  child: Text('Please select a branch to view inventory.'),
                );
              }
              if (inventoryController.branchProducts.isEmpty) {
                return const Center(child: Text('No products in this branch.'));
              }
              return ListView.builder(
                itemCount: inventoryController.branchProducts.length,
                itemBuilder: (context, index) {
                  final branchProduct =
                      inventoryController.branchProducts[index];
                  final product =
                      branchProduct.product; // Get the nested product details
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: Text(product?.name ?? 'N/A'),
                            subtitle: Text(
                              "${product?.sku ?? 'No SKU'} | Price: ${product?.price?.toStringAsFixed(2) ?? 'N/A'}",
                            ),
                            trailing: Text(
                              'Stock: ${branchProduct.quantity}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                onPressed:
                                    () => _showTransactionDialog(
                                      context,
                                      branchProduct,
                                      'in',
                                    ),
                                icon: const Icon(Icons.add),
                                label: const Text('In'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed:
                                    () => _showTransactionDialog(
                                      context,
                                      branchProduct,
                                      'out',
                                    ),
                                icon: const Icon(Icons.remove),
                                label: const Text('Out'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: Obx(() {
        // Only show the add product button to admins
        if (authController.userRole.value == 'admin') {
          return FloatingActionButton(
            onPressed: () {
              Get.to(() => const ProductFormScreen());
            },
            tooltip: 'Add New Master Product',
            child: const Icon(Icons.add),
          );
        }
        return const SizedBox.shrink(); // Return empty space if not admin
      }),
    );
  }
}
