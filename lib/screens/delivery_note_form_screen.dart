import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:umayumcha/controllers/delivery_note_controller.dart';
import 'package:umayumcha/controllers/inventory_controller.dart';
import 'package:umayumcha/controllers/branch_controller.dart'; // Import BranchController
import 'package:umayumcha/models/branch_model.dart'; // Import Branch model
import 'package:umayumcha/models/branch_product_model.dart'; // Import BranchProduct model

class DeliveryNoteFormScreen extends StatefulWidget {
  const DeliveryNoteFormScreen({super.key});

  @override
  State<DeliveryNoteFormScreen> createState() => _DeliveryNoteFormScreenState();
}

class _DeliveryNoteFormScreenState extends State<DeliveryNoteFormScreen> {
  final DeliveryNoteController deliveryNoteController = Get.find();
  final InventoryController inventoryController = Get.find();
  final BranchController branchController = Get.find(); // Get BranchController

  final TextEditingController customerNameController = TextEditingController();
  final TextEditingController destinationAddressController =
      TextEditingController();
  DateTime selectedDeliveryDate = DateTime.now();

  Branch? selectedFromBranch; // New: Selected source branch
  Branch? selectedToBranch; // New: Selected destination branch

  final RxList<Map<String, dynamic>> selectedProducts =
      <Map<String, dynamic>>[].obs;

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

  void _addProductToNote() {
    if (selectedFromBranch == null) {
      Get.snackbar('Error', 'Please select a source branch first.');
      return;
    }

    Get.dialog(
      AlertDialog(
        title: const Text('Add Product to Delivery Note'),
        content: Obx(() {
          // Filter products by the selected source branch inside Obx
          final availableProducts = inventoryController.branchProducts
              .where((bp) => bp.branchId == selectedFromBranch!.id)
              .toList();

          if (availableProducts.isEmpty) {
            return const Text('No products available in the selected source branch.');
          }
          return DropdownButtonFormField<BranchProduct>(
            decoration: const InputDecoration(labelText: 'Select Product'),
            items: availableProducts.map((branchProduct) {
              return DropdownMenuItem(
                value: branchProduct,
                child: Text(
                  '${branchProduct.product?.name ?? 'N/A'} (Stock: ${branchProduct.quantity})',
                ),
              );
            }).toList(),
            onChanged: (BranchProduct? branchProduct) {
              if (branchProduct != null) {
                Get.dialog(
                  AlertDialog(
                    title: Text(
                      'Enter Quantity for ${branchProduct.product?.name ?? 'N/A'}',
                    ),
                    content: TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Quantity (Max: ${branchProduct.quantity})',
                      ),
                      onSubmitted: (value) {
                        final int? quantity = int.tryParse(value);
                        if (quantity != null &&
                            quantity > 0 &&
                            quantity <= branchProduct.quantity) {
                          selectedProducts.add({
                            'product_id': branchProduct.productId,
                            'product_name':
                                branchProduct.product?.name ?? 'N/A',
                            'quantity': quantity,
                          });
                          Get.back(); // Close quantity dialog
                          Get.back(); // Close product selection dialog
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
          );
        }),
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
            // From Branch Selection
            Obx(() {
              if (branchController.isLoading.value) {
                return const CircularProgressIndicator();
              }
              if (branchController.branches.isEmpty) {
                return const Text(
                  'No branches available. Please add branches first.',
                );
              }
              return DropdownButtonFormField<Branch>(
                decoration: const InputDecoration(labelText: 'From Branch'),
                value: selectedFromBranch,
                onChanged: (Branch? newValue) {
                  setState(() {
                    selectedFromBranch = newValue;
                    // When from branch changes, clear selected products
                    selectedProducts.clear();
                  });
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
            const SizedBox(height: 16),

            // To Branch Selection
            Obx(() {
              if (branchController.isLoading.value) {
                return const CircularProgressIndicator();
              }
              if (branchController.branches.isEmpty) {
                return const SizedBox.shrink();
              }
              return DropdownButtonFormField<Branch>(
                decoration: const InputDecoration(labelText: 'To Branch'),
                value: selectedToBranch,
                onChanged: (Branch? newValue) {
                  setState(() {
                    selectedToBranch = newValue;
                  });
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
            const SizedBox(height: 16),

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
                        '${item['product_name']} (from ${selectedFromBranch?.name ?? 'N/A'})',
                      ),
                      trailing: Text('x${item['quantity']}'),
                      onLongPress: () {
                        Get.dialog(
                          AlertDialog(
                            title: const Text('Remove Item?'),
                            content: Text(
                              'Do you want to remove ${item['product_name']}?',
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
                      if (selectedFromBranch == null) {
                        Get.snackbar('Error', 'Please select a From Branch.');
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
                      deliveryNoteController.createDeliveryNote(
                        customerName: 'Internal Transfer', // Default value
                        destinationAddress: 'Internal Transfer', // Default value
                        deliveryDate: selectedDeliveryDate,
                        fromBranchId: selectedFromBranch!.id,
                        toBranchId: selectedToBranch!.id,
                        items: selectedProducts.toList(),
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
