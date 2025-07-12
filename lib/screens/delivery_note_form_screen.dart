
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:umayumcha/controllers/delivery_note_controller.dart';
import 'package:umayumcha/controllers/inventory_controller.dart';
import 'package:umayumcha/models/product_model.dart';

class DeliveryNoteFormScreen extends StatefulWidget {
  const DeliveryNoteFormScreen({super.key});

  @override
  State<DeliveryNoteFormScreen> createState() => _DeliveryNoteFormScreenState();
}

class _DeliveryNoteFormScreenState extends State<DeliveryNoteFormScreen> {
  final DeliveryNoteController deliveryNoteController = Get.find();
  final InventoryController inventoryController = Get.find();

  final TextEditingController customerNameController = TextEditingController();
  final TextEditingController destinationAddressController = TextEditingController();
  DateTime selectedDeliveryDate = DateTime.now();

  final RxList<Map<String, dynamic>> selectedProducts = <Map<String, dynamic>>[].obs;

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
    Get.dialog(
      AlertDialog(
        title: const Text('Add Product to Delivery Note'),
        content: Obx(() {
          if (inventoryController.products.isEmpty) {
            return const Text('No products available.');
          }
          return DropdownButtonFormField<Product>(
            decoration: const InputDecoration(labelText: 'Select Product'),
            items: inventoryController.products.map((product) {
              return DropdownMenuItem(
                value: product,
                child: Text(product.name),
              );
            }).toList(),
            onChanged: (Product? product) {
              if (product != null) {
                Get.dialog(
                  AlertDialog(
                    title: Text('Enter Quantity for ${product.name}'),
                    content: TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      onSubmitted: (value) {
                        final int? quantity = int.tryParse(value);
                        if (quantity != null && quantity > 0) {
                          selectedProducts.add({
                            'product_id': product.id,
                            'product_name': product.name,
                            'quantity': quantity,
                          });
                          Get.back(); // Close quantity dialog
                          Get.back(); // Close product selection dialog
                        } else {
                          Get.snackbar('Error', 'Please enter a valid quantity.');
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
            TextField(
              controller: customerNameController,
              decoration: const InputDecoration(labelText: 'Customer Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: destinationAddressController,
              decoration: const InputDecoration(labelText: 'Destination Address (Optional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text('Delivery Date: ${selectedDeliveryDate.toLocal().toString().split(' ').first}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 16),
            const Text('Products for Delivery:', style: TextStyle(fontWeight: FontWeight.bold)),
            Obx(() {
              return Expanded(
                child: ListView.builder(
                  itemCount: selectedProducts.length,
                  itemBuilder: (context, index) {
                    final item = selectedProducts[index];
                    return ListTile(
                      title: Text(item['product_name']),
                      trailing: Text('x${item['quantity']}'),
                      onLongPress: () {
                        Get.dialog(
                          AlertDialog(
                            title: const Text('Remove Item?'),
                            content: Text('Do you want to remove ${item['product_name']}?'),
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
                        if (customerNameController.text.isEmpty) {
                          Get.snackbar('Error', 'Customer Name cannot be empty.');
                          return;
                        }
                        if (selectedProducts.isEmpty) {
                          Get.snackbar('Error', 'Please add at least one product to the delivery note.');
                          return;
                        }
                        deliveryNoteController.createDeliveryNote(
                          customerName: customerNameController.text.trim(),
                          destinationAddress: destinationAddressController.text.trim(),
                          deliveryDate: selectedDeliveryDate,
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
