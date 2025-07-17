
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:umayumcha/controllers/consumable_controller.dart';
import 'package:umayumcha/models/consumable_model.dart';
import 'package:umayumcha/screens/consumable_form_screen.dart';

void _showConsumableTransactionDialog(
  BuildContext context,
  Consumable consumable,
  String type,
) {
  final ConsumableController controller = Get.find();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();

  Get.dialog(
    AlertDialog(
      title: Text(
        '${type == 'in' ? 'Add' : 'Remove'} Stock for ${consumable.name}',
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
              if (type == 'in') {
                controller.addConsumableQuantity(
                  consumable.id!,
                  quantity,
                  reasonController.text.trim(),
                );
              } else {
                controller.removeConsumableQuantity(
                  consumable.id!,
                  quantity,
                  reasonController.text.trim(),
                );
              }
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

class ConsumableListScreen extends StatelessWidget {
  final ConsumableController controller = Get.put(ConsumableController());

  ConsumableListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consumables'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Get.to(() => const ConsumableFormScreen()),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.consumables.isEmpty) {
          return const Center(child: Text('No consumables found.'));
        }
        return ListView.builder(
          itemCount: controller.consumables.length,
          itemBuilder: (context, index) {
            final consumable = controller.consumables[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Text(consumable.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Code: ${consumable.code}'),
                          if (consumable.expiredDate != null)
                            Text(
                                'Expired: ${DateFormat.yMd().format(consumable.expiredDate!)}'),
                        ],
                      ),
                      trailing: Text(
                        'Qty: ${consumable.quantity}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      onTap: () => Get.to(
                          () => ConsumableFormScreen(consumable: consumable)),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => Get.to(
                              () => ConsumableFormScreen(consumable: consumable)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () =>
                              controller.deleteConsumable(consumable.id!),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _showConsumableTransactionDialog(
                            context,
                            consumable,
                            'out',
                          ),
                          icon: const Icon(Icons.remove),
                          label: const Text('Out'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _showConsumableTransactionDialog(
                            context,
                            consumable,
                            'in',
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('In'),
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
    );
  }
}
