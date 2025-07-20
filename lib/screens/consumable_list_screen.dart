import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:umayumcha/controllers/consumable_controller.dart';
import 'package:umayumcha/models/consumable_model.dart';
import 'package:umayumcha/screens/consumable_form_screen.dart';
import 'package:umayumcha/widgets/delete_confirmation_dialog.dart';

void _showConsumableTransactionDialog(
  BuildContext context,
  Consumable consumable,
  String type,
) {
  final ConsumableController controller = Get.find();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;

  void showDialogWithState() {
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
              '${type == 'in' ? 'Add' : 'Remove'} Stock for ${consumable.name}',
            ),
            content: Form(
              key: formKey,
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
              TextButton(
                onPressed: isLoading ? null : () => Get.back(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed:
                    isLoading
                        ? null
                        : () async {
                          if (formKey.currentState!.validate()) {
                            setState(() => isLoading = true);
                            final int quantity = int.parse(
                              quantityController.text,
                            );
                            if (type == 'in') {
                              await controller.addStock(
                                consumable.id!,
                                quantity,
                                reasonController.text.trim(),
                              );
                            } else {
                              await controller.removeStock(
                                consumable.id!,
                                quantity,
                                reasonController.text.trim(),
                              );
                            }
                            setState(() => isLoading = false);
                            if (!context.mounted) return;
                            Navigator.of(context, rootNavigator: true).pop();
                          }
                        },
                child:
                    isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Text(type == 'in' ? 'Add' : 'Remove'),
              ),
            ],
          );
        },
      ),
    );
  }

  showDialogWithState();
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
        backgroundColor:
            _isSearching
                ? Colors.white
                : Theme.of(context).primaryColor, // Dynamic background color
        iconTheme: IconThemeData(
          color: _isSearching ? Colors.black : Colors.white,
        ), // Dynamic icon color
        title:
            _isSearching
                ? Container(
                  height: 40, // Adjust height as needed
                  decoration: BoxDecoration(
                    color:
                        Colors
                            .white, // Solid white background for clear visibility
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search consumables...',
                      hintStyle: TextStyle(
                        color: Colors.grey,
                      ), // Grey hint text
                      border: InputBorder.none, // Remove default border
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey,
                      ), // Grey search icon
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 10.0,
                      ), // Adjust padding
                    ),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                    ), // Black text for contrast
                    cursorColor: Colors.black,
                  ),
                )
                : const Text(
                  'Consumables',
                  style: TextStyle(color: Colors.white),
                ), // Ensure title is white when not searching
        elevation: 4,
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: _isSearching ? Colors.black : Colors.white,
            ), // Dynamic icon color
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
                              onPressed: () {
                                showDeleteConfirmationDialog(
                                  title: "Delete Consumable",
                                  content:
                                      "Are you sure you want to delete ${consumable.name}? This action cannot be undone.",
                                  onConfirm: () {
                                    controller.deleteConsumable(consumable.id!);
                                  },
                                );
                              },
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
