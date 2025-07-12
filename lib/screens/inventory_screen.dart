
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:umayumcha/controllers/auth_controller.dart';
import 'package:umayumcha/controllers/inventory_controller.dart';
import 'package:umayumcha/models/product_model.dart';
import 'package:umayumcha/screens/product_form_screen.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  void _showTransactionDialog(
      BuildContext context, Product product, String type) {
    final InventoryController controller = Get.find();
    final TextEditingController quantityController = TextEditingController();
    final TextEditingController reasonController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text('${type == 'in' ? 'Add' : 'Remove'} Stock for ${product.name}'),
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
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final int? quantity = int.tryParse(quantityController.text);
              if (quantity != null && quantity > 0) {
                controller.addTransaction(
                  productId: product.id,
                  type: type,
                  quantityChange: quantity,
                  reason: reasonController.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    final InventoryController controller = Get.put(InventoryController());
    final AuthController authController = Get.find();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Inventory'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.products.isEmpty) {
          return const Center(child: Text('No products found. Add one!'));
        }
        return ListView.builder(
          itemCount: controller.products.length,
          itemBuilder: (context, index) {
            final product = controller.products[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Text(product.name),
                      subtitle: Text(
                          '${product.sku ?? 'No SKU'} | Price: ${product.price?.toStringAsFixed(2) ?? 'N/A'}'),
                      trailing: Text(
                        'Stock: ${product.quantity}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () =>
                              _showTransactionDialog(context, product, 'in'),
                          icon: const Icon(Icons.add),
                          label: const Text('In'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () =>
                              _showTransactionDialog(context, product, 'out'),
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
      floatingActionButton: Obx(() {
        // Only show the add button to admins
        if (authController.userRole.value == 'admin') {
          return FloatingActionButton(
            onPressed: () {
              Get.to(() => const ProductFormScreen());
            },
            tooltip: 'Add Product',
            child: const Icon(Icons.add),
          );
        }
        return const SizedBox.shrink(); // Return empty space if not admin
      }),
    );
  }
}
