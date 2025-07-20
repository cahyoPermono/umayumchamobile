import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:umayumcha/controllers/delivery_note_controller.dart';
import 'package:umayumcha/controllers/inventory_controller.dart';
import 'package:umayumcha/controllers/branch_controller.dart'; // Import BranchController
import 'package:umayumcha/models/branch_model.dart'; // Import Branch model
import 'package:umayumcha/models/branch_product_model.dart'; // Import BranchProduct model
import 'package:umayumcha/controllers/consumable_controller.dart'; // New: Import ConsumableController
import 'package:umayumcha/models/consumable_model.dart'; // New: Import Consumable model

// Helper class for selectable items (Moved to top-level)
class SelectableItem {
  final String id;
  final String name;
  final int quantity;
  final String type; // 'product' or 'consumable'

  SelectableItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.type,
  });
}

class DeliveryNoteFormScreen extends StatefulWidget {
  const DeliveryNoteFormScreen({super.key});

  @override
  State<DeliveryNoteFormScreen> createState() => _DeliveryNoteFormScreenState();
}

class _DeliveryNoteFormScreenState extends State<DeliveryNoteFormScreen> {
  final DeliveryNoteController deliveryNoteController = Get.find();
  final InventoryController inventoryController = Get.find();
  final BranchController branchController =
      Get.find(); // Import BranchController
  final ConsumableController consumableController =
      Get.find(); // New: Get ConsumableController

  final TextEditingController customerNameController = TextEditingController();
  final TextEditingController destinationAddressController =
      TextEditingController();
  DateTime selectedDeliveryDate = DateTime.now();

  Branch? selectedToBranch; // New: Selected destination branch

  final RxList<Map<String, dynamic>> selectedProducts =
      <Map<String, dynamic>>[].obs;

  Rx<Branch?> umayumchaHQBranch = Rx<Branch?>(
    null,
  ); // To hold the UmayumchaHQ branch

  @override
  void initState() {
    super.initState();
    // Listen for changes in branches and set UmayumchaHQ
    ever(branchController.branches, (_) {
      _findAndSetUmayumchaHQBranch();
    });

    // Also check immediately in case branches are already loaded
    _findAndSetUmayumchaHQBranch();
  }

  void _findAndSetUmayumchaHQBranch() {
    final foundBranch = branchController.branches.firstWhereOrNull(
      (branch) => branch.name == 'UmayumchaHQ',
    );
    if (foundBranch != null) {
      umayumchaHQBranch.value = foundBranch;
    } else if (!branchController.isLoading.value) {
      Get.snackbar(
        'Error',
        'UmayumchaHQ branch not found. Please ensure it exists.',
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDeliveryDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDeliveryDate) {
      setState(() {
        selectedDeliveryDate = picked;
      });
    }
  }

  void _addProductToNote() async {
    if (umayumchaHQBranch.value == null) {
      Get.snackbar('Error', 'UmayumchaHQ branch not found. Cannot add item.');
      return;
    }

    if (umayumchaHQBranch.value!.id == null) {
      Get.snackbar('Error', 'UmayumchaHQ branch ID is missing.');
      return;
    }

    // Fetch products and consumables
    final List<BranchProduct> availableProducts = await inventoryController
        .fetchBranchProductsById(
          umayumchaHQBranch.value!.id!,
        ); // Products from UmayumchaHQ
    final List<Consumable> availableConsumables =
        consumableController.consumables
            .where((c) => c.quantity > 0)
            .toList(); // All consumables with quantity > 0

    // Combine into a single list of SelectableItem
    final List<SelectableItem> selectableItems = [];
    for (var bp in availableProducts) {
      selectableItems.add(
        SelectableItem(
          id: bp.productId,
          name: bp.product?.name ?? 'N/A',
          quantity: bp.quantity,
          type: 'product',
        ),
      );
    }
    for (var c in availableConsumables) {
      selectableItems.add(
        SelectableItem(
          id: c.id.toString(), // Consumable ID is int, convert to String
          name: c.name,
          quantity: c.quantity,
          type: 'consumable',
        ),
      );
    }

    if (selectableItems.isEmpty) {
      Get.snackbar(
        'Info',
        'No products or consumables available in the selected source branch.',
      );
      return;
    }

    Get.dialog(
      AlertDialog(
        title: const Text('Add Item to Delivery Note'),
        content: DropdownButtonFormField<SelectableItem>(
          isExpanded: true, // Added to fix layout issues
          decoration: const InputDecoration(labelText: 'Select Item'),
          items:
              selectableItems.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(
                    '${item.name} (Stock: ${item.quantity}) [${item.type.capitalizeFirst}]',
                  ),
                );
              }).toList(),
          onChanged: (SelectableItem? selectedItem) {
            if (selectedItem != null) {
              Get.dialog(
                AlertDialog(
                  title: Text('Enter Quantity for ${selectedItem.name}'),
                  content: TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Quantity (Max: ${selectedItem.quantity})',
                    ),
                    onSubmitted: (value) {
                      final int? quantity = int.tryParse(value);
                      if (quantity != null &&
                          quantity > 0 &&
                          quantity <= selectedItem.quantity) {
                        selectedProducts.add({
                          'id': selectedItem.id,
                          'name': selectedItem.name,
                          'quantity': quantity,
                          'type': selectedItem.type, // Store type
                        });
                        Get.back(); // Close quantity dialog
                        Get.back(); // Close item selection dialog
                      } else {
                        Get.snackbar(
                          'Error',
                          'Please enter a valid quantity within available stock.',
                        );
                      }
                    },
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Delivery Note')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // From Branch Selection (Hidden and pre-selected to UmayumchaHQ)
            Obx(() {
              if (branchController.isLoading.value) {
                return const CircularProgressIndicator();
              }
              if (umayumchaHQBranch.value == null) {
                return const Text(
                  'UmayumchaHQ branch not found. Please ensure it exists.',
                );
              }
              return AbsorbPointer(
                child: DropdownButtonFormField<Branch>(
                  decoration: const InputDecoration(labelText: 'From Branch'),
                  value: umayumchaHQBranch.value,
                  onChanged: (Branch? newValue) {},
                  items:
                      [umayumchaHQBranch.value!].map((branch) {
                        return DropdownMenuItem<Branch>(
                          value: branch,
                          child: Text(branch.name),
                        );
                      }).toList(),
                ),
              );
            }),
            const SizedBox(height: 16),

            // To Branch Selection
            Obx(() {
              if (branchController.isLoading.value) {
                return const CircularProgressIndicator();
              }
              if (branchController.branches.isEmpty) {
                return const SizedBox.shrink();
              }
              final List<Branch> otherBranches =
                  branchController.branches
                      .where((branch) => branch.name != 'UmayumchaHQ')
                      .toList();
              return DropdownButtonFormField<Branch>(
                decoration: const InputDecoration(labelText: 'To Branch'),
                value: selectedToBranch,
                onChanged: (Branch? newValue) {
                  setState(() {
                    selectedToBranch = newValue;
                  });
                },
                items:
                    otherBranches.map((branch) {
                      return DropdownMenuItem<Branch>(
                        value: branch,
                        child: Text(branch.name),
                      );
                    }).toList(),
              );
            }),
            const SizedBox(height: 16),

            ListTile(
              title: Text(
                'Delivery Date: ${selectedDeliveryDate.toLocal().toString().split(' ').first}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 16),
            const Text(
              'Products for Delivery:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Obx(() {
              // Access selectedProducts.length to ensure Obx reacts to changes
              selectedProducts.length;
              return Expanded(
                child: ListView.builder(
                  itemCount: selectedProducts.length,
                  itemBuilder: (context, index) {
                    final item = selectedProducts[index];
                    return ListTile(
                      title: Text(
                        '${item['name']} (from ${umayumchaHQBranch.value?.name ?? 'N/A'}) [${(item['type'] as String).capitalizeFirst}]',
                      ),
                      trailing: Text('x${item['quantity']}'),
                      onLongPress: () {
                        Get.dialog(
                          AlertDialog(
                            title: const Text('Remove Item?'),
                            content: Text(
                              'Do you want to remove ${item['name']}?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Get.back(),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  selectedProducts.removeAt(index);
                                  Get.back();
                                },
                                child: const Text('Remove'),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            }),
            ElevatedButton.icon(
              onPressed: _addProductToNote,
              icon: const Icon(Icons.add),
              label: const Text('Add Product to Note'),
            ),
            const SizedBox(height: 24),
            Obx(() {
              return deliveryNoteController.isLoading.value
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                    onPressed: () {
                      if (umayumchaHQBranch.value == null) {
                        Get.snackbar('Error', 'UmayumchaHQ branch not found.');
                        return;
                      }
                      if (selectedToBranch == null) {
                        Get.snackbar('Error', 'Please select a To Branch.');
                        return;
                      }
                      if (selectedProducts.isEmpty) {
                        Get.snackbar(
                          'Error',
                          'Please add at least one product to the delivery note.',
                        );
                        return;
                      }
                      if (umayumchaHQBranch.value!.id == null) {
                        Get.snackbar(
                          'Error',
                          'UmayumchaHQ Branch ID is missing.',
                        );
                        return;
                      }
                      if (selectedToBranch!.id == null) {
                        Get.snackbar('Error', 'To Branch ID is missing.');
                        return;
                      }
                      deliveryNoteController.createDeliveryNote(
                        customerName: 'Internal Transfer', // Default value
                        destinationAddress:
                            'Internal Transfer', // Default value
                        deliveryDate: selectedDeliveryDate,
                        fromBranchId: umayumchaHQBranch.value!.id!,
                        toBranchId: selectedToBranch!.id!,
                        items:
                            selectedProducts.toList(), // Pass the modified list
                      );
                    },
                    child: const Text('Save Delivery Note'),
                  );
            }),
          ],
        ),
      ),
    );
  }
}
