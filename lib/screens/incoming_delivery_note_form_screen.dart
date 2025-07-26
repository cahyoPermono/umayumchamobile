import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:umayumcha_ims/controllers/incoming_delivery_note_controller.dart';
import 'package:umayumcha_ims/controllers/inventory_controller.dart';
import 'package:umayumcha_ims/controllers/branch_controller.dart';
import 'package:umayumcha_ims/models/branch_model.dart';
import 'package:umayumcha_ims/models/branch_product_model.dart';
import 'package:umayumcha_ims/controllers/consumable_controller.dart';
import 'package:umayumcha_ims/models/consumable_model.dart';
import 'package:umayumcha_ims/widgets/item_selection_dialog.dart';
import 'package:umayumcha_ims/models/incoming_delivery_note_model.dart';
import 'package:intl/intl.dart';
import 'package:umayumcha_ims/models/selectable_item.dart'; // Import SelectableItem
import 'package:umayumcha_ims/utils/app_constants.dart';

class IncomingDeliveryNoteFormScreen extends StatefulWidget {
  final IncomingDeliveryNote? incomingDeliveryNote;
  const IncomingDeliveryNoteFormScreen({super.key, this.incomingDeliveryNote});

  @override
  State<IncomingDeliveryNoteFormScreen> createState() => _IncomingDeliveryNoteFormScreenState();
}

class _IncomingDeliveryNoteFormScreenState extends State<IncomingDeliveryNoteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final IncomingDeliveryNoteController incomingDeliveryNoteController = Get.find();
  final InventoryController inventoryController = Get.find();
  final BranchController branchController = Get.find();
  final ConsumableController consumableController = Get.find();

  final TextEditingController _fromVendorNameController = TextEditingController();
  final TextEditingController keteranganController = TextEditingController();
  DateTime selectedDeliveryDate = DateTime.now();

  Branch? selectedToBranch;

  final RxList<Map<String, dynamic>> selectedProducts = <Map<String, dynamic>>[].obs;

  String? incomingDeliveryNoteId;

  @override
  void initState() {
    super.initState();
    if (widget.incomingDeliveryNote != null) {
      incomingDeliveryNoteId = widget.incomingDeliveryNote!.id;
      selectedDeliveryDate = widget.incomingDeliveryNote!.deliveryDate;
      _fromVendorNameController.text = widget.incomingDeliveryNote!.fromVendorName ?? '';
      keteranganController.text = widget.incomingDeliveryNote!.keterangan ?? '';

      selectedProducts.clear();
      selectedToBranch = branchController.branches.firstWhereOrNull(
        (branch) => branch.id == widget.incomingDeliveryNote!.toBranchId,
      );

      if (widget.incomingDeliveryNote!.productItems != null) {
        for (var item in widget.incomingDeliveryNote!.productItems!) {
          selectedProducts.add({
            'id': item['product_id'],
            'name': item['product_name'],
            'quantity': item['quantity_change'],
            'type': 'product',
            'description': item['reason'],
          });
        }
      }
      if (widget.incomingDeliveryNote!.consumableItems != null) {
        for (var item in widget.incomingDeliveryNote!.consumableItems!) {
          selectedProducts.add({
            'id': item['consumable_id'].toString(),
            'name': item['consumable_name'],
            'quantity': item['quantity_change'],
            'type': 'consumable',
            'description': item['reason'],
          });
        }
      }
    } else {
      // Default to headquarter branch for new incoming delivery notes
      selectedToBranch = branchController.branches.firstWhereOrNull(
        (branch) => branch.id == headquarterId,
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDeliveryDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (context.mounted && pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDeliveryDate),
      );

      if (context.mounted && pickedTime != null) {
        setState(() {
          selectedDeliveryDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _addItemToNote() async {
    // For incoming notes, we can add any product/consumable, not just from HQ
    // So we fetch all products and consumables
    final List<BranchProduct> allProducts = [];
    for (var branch in branchController.branches) {
      allProducts.addAll(await inventoryController.fetchBranchProductsById(branch.id!));
    }
    final List<Consumable> allConsumables = consumableController.consumables.toList();

    // Combine into a single list of SelectableItem
    final List<SelectableItem> selectableItems = [];
    for (var bp in allProducts) {
      selectableItems.add(
        SelectableItem(
          id: bp.productId,
          name: bp.product?.name ?? 'N/A',
          quantity: 999999, // Set a very high quantity for incoming, as we are not limited by current stock
          type: 'product',
        ),
      );
    }
    for (var c in allConsumables) {
      selectableItems.add(
        SelectableItem(
          id: c.id.toString(),
          name: c.name,
          quantity: 999999, // Set a very high quantity for incoming
          type: 'consumable',
        ),
      );
    }

    if (selectableItems.isEmpty) {
      Get.snackbar(
        'Info',
        'No products or consumables available to add.',
      );
      return;
    }

    final SelectableItem? selectedItem = await Get.dialog<SelectableItem>(
      ItemSelectionDialog(items: selectableItems),
    );

    if (selectedItem != null) {
      final TextEditingController quantityController = TextEditingController();
      final TextEditingController descriptionController = TextEditingController();
      Get.dialog(
        AlertDialog(
          title: Text('Add Item: ${selectedItem.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Keterangan (Optional)',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Get.back();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final int? quantity = int.tryParse(quantityController.text);
                if (quantity != null && quantity > 0) {
                  selectedProducts.add({
                    'id': selectedItem.id,
                    'name': selectedItem.name,
                    'quantity': quantity,
                    'type': selectedItem.type,
                    'description': descriptionController.text,
                  });
                  Get.back();
                } else {
                  Get.snackbar(
                    'Error',
                    'Please enter a valid quantity.',
                  );
                }
              },
              child: const Text('Accept'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.incomingDeliveryNote == null
              ? 'Create Incoming Delivery Note'
              : 'Edit Incoming Delivery Note',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingController) {
                  if (textEditingController.text == '') {
                    return const Iterable<String>.empty();
                  }
                  return incomingDeliveryNoteController.distinctVendorNames
                      .where((String option) {
                    return option
                        .toLowerCase()
                        .contains(textEditingController.text.toLowerCase());
                  });
                },
                onSelected: (String selection) {
                  _fromVendorNameController.text = selection;
                },
                fieldViewBuilder: (BuildContext context,
                    TextEditingController textEditingController,
                    FocusNode focusNode,
                    void Function() onFieldSubmitted) {
                  textEditingController.text = _fromVendorNameController.text;
                  return TextFormField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: 'From (Vendor Name)',
                      hintText: 'e.g., Supplier A, Main Warehouse',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.business),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'From (Vendor Name) cannot be empty';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      _fromVendorNameController.text = value;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              // To Branch Selection
              Obx(() {
                if (branchController.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (branchController.branches.isEmpty) {
                  return const SizedBox.shrink();
                }
                return DropdownButtonFormField<Branch>(
                  decoration: InputDecoration(
                    labelText: 'To Branch',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.store),
                  ),
                  value: selectedToBranch,
                  onChanged: null, // Disable the dropdown
                  items: selectedToBranch != null
                      ? [
                          DropdownMenuItem<Branch>(
                            value: selectedToBranch,
                            child: Text(selectedToBranch!.name),
                          ),
                        ]
                      : [],
                );
              }),
              const SizedBox(height: 16),

              // Delivery Date
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: TextEditingController(
                      text: DateFormat(
                        'yyyy-MM-dd HH:mm',
                      ).format(selectedDeliveryDate.toLocal()),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Delivery Date',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.calendar_today),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: keteranganController,
                decoration: InputDecoration(
                  labelText: 'Catatan',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Items for Delivery Section
              Text(
                'Items for Incoming Delivery:',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Obx(() {
                if (selectedProducts.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Center(
                      child: Text(
                        'No items added yet. Tap "Add Item" to begin.',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: selectedProducts.length,
                  itemBuilder: (context, index) {
                    final item = selectedProducts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Icon(
                              item['type'] == 'product'
                                  ? Icons.inventory_2_outlined
                                  : Icons.category_outlined,
                              color:
                                  item['type'] == 'product'
                                      ? Colors.blueGrey
                                      : Colors.teal,
                            ),
                            title: Text(
                              '${item['name']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              'Type: ${(item['type'] as String).capitalizeFirst} | Quantity: x${item['quantity']}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
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
                            ),
                          ),
                          if (item['description'] != null &&
                              item['description'].isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                72.0,
                                0.0,
                                16.0,
                                8.0,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Keterangan: ${item['description']}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              }),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _addItemToNote,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item to Incoming Delivery Note'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              Obx(() {
                return incomingDeliveryNoteController.isLoading.value
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();
                              if (selectedToBranch == null) {
                                Get.snackbar(
                                  'Error',
                                  'Please select a To Branch.',
                                );
                                return;
                              }
                              if (selectedProducts.isEmpty) {
                                Get.snackbar(
                                  'Error',
                                  'Please add at least one item to the incoming delivery note.',
                                );
                                return;
                              }
                              if (selectedToBranch!.id == null) {
                                Get.snackbar('Error', 'To Branch ID is missing.');
                                return;
                              }

                              if (widget.incomingDeliveryNote == null) {
                                // Create new incoming delivery note
                                incomingDeliveryNoteController.createIncomingDeliveryNote(
                                  fromVendorName: _fromVendorNameController.text,
                                  deliveryDate: selectedDeliveryDate,
                                  toBranchId: selectedToBranch!.id!,
                                  toBranchName: selectedToBranch!.name,
                                  items: selectedProducts.toList(),
                                  keterangan: keteranganController.text,
                                );
                              } else {
                                // Update existing incoming delivery note
                                incomingDeliveryNoteController.updateIncomingDeliveryNote(
                                  incomingDeliveryNoteId: incomingDeliveryNoteId!,
                                  fromVendorName: _fromVendorNameController.text,
                                  deliveryDate: selectedDeliveryDate,
                                  toBranchId: selectedToBranch!.id!,
                                  toBranchName: selectedToBranch!.name,
                                  newItems: selectedProducts.toList(),
                                  originalItems: (
                                      widget.incomingDeliveryNote!.productItems ?? []
                                    ) + (
                                      widget.incomingDeliveryNote!.consumableItems ?? []
                                    ),
                                  keterangan: keteranganController.text,
                                );
                              }
                            }
                          },
                          icon: Icon(
                            widget.incomingDeliveryNote == null
                                ? Icons.save
                                : Icons.update,
                          ),
                          label: Text(
                            widget.incomingDeliveryNote == null
                                ? 'Save Incoming Delivery Note'
                                : 'Update Incoming Delivery Note',
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
              }),
            ],
          ), // Closing parenthesis for Column
        ), // Closing parenthesis for Form
      ), // Closing parenthesis for SingleChildScrollView
    ); // Closing parenthesis for Scaffold
  }
}