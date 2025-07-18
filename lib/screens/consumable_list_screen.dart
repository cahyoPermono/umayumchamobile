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
  final formKey = GlobalKey<FormState>(); // Declare GlobalKey here

  Get.dialog(
    AlertDialog(
      title: Text(
        '${type == 'in' ? 'Add' : 'Remove'} Stock for ${consumable.name}',
      ),
      content: Form(
        key: formKey, // Assign the key to the Form
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null ||
                    int.tryParse(value) == null ||
                    int.parse(value) <= 0) {
                  return 'Please enter a valid quantity.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText:
                    'Reason ${type == 'out' ? '(Required)' : '(Optional)'}',
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (type == 'out' && (value == null || value.isEmpty)) {
                  return 'Reason is required for OUT transactions.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              // Use the key to validate
              final int quantity = int.parse(quantityController.text);
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
            }
          },
          child: Text(type == 'in' ? 'Add' : 'Remove'),
        ),
      ],
    ),
  );
}

class ConsumableListScreen extends StatefulWidget {
  const ConsumableListScreen({super.key});

  @override
  State<ConsumableListScreen> createState() => _ConsumableListScreenState();
}

class _ConsumableListScreenState extends State<ConsumableListScreen> {
  final ConsumableController controller = Get.put(ConsumableController());
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      controller.searchQuery.value = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            _isSearching
                ? TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search consumables...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  cursorColor: Colors.white,
                )
                : const Text('Consumables'),
        elevation: 4,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  controller.searchQuery.value = '';
                }
              });
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const ConsumableFormScreen()),
        child: const Icon(Icons.add),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.filteredConsumables.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 80, color: Colors.grey),
                SizedBox(height: 20),
                Text(
                  controller.searchQuery.isEmpty
                      ? 'No consumables found.'
                      : 'No matching consumables found.',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => controller.fetchConsumables(),
          child: ListView.builder(
            itemCount: controller.filteredConsumables.length,
            itemBuilder: (context, index) {
              final consumable = controller.filteredConsumables[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap:
                      () => Get.to(
                        () => ConsumableFormScreen(consumable: consumable),
                      ),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                consumable.name,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              'Qty: ${consumable.quantity}',
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Code: ${consumable.code}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (consumable.description != null &&
                            consumable.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Description: ${consumable.description}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        if (consumable.expiredDate != null)
                          Text(
                            'Expired: ${DateFormat.yMd().format(consumable.expiredDate!)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.blueGrey,
                              ),
                              onPressed:
                                  () => Get.to(
                                    () => ConsumableFormScreen(
                                      consumable: consumable,
                                    ),
                                  ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.redAccent,
                              ),
                              onPressed:
                                  () => controller.deleteConsumable(
                                    consumable.id!,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed:
                                  () => _showConsumableTransactionDialog(
                                    context,
                                    consumable,
                                    'out',
                                  ),
                              icon: const Icon(Icons.remove),
                              label: const Text('Out'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed:
                                  () => _showConsumableTransactionDialog(
                                    context,
                                    consumable,
                                    'in',
                                  ),
                              icon: const Icon(Icons.add),
                              label: const Text('In'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
