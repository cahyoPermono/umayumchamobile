import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:umayumcha_ims/controllers/delivery_note_controller.dart';
import 'package:umayumcha_ims/controllers/inventory_controller.dart';
import 'package:umayumcha_ims/controllers/branch_controller.dart'; // Import BranchController
import 'package:umayumcha_ims/models/branch_model.dart'; // Import Branch model
import 'package:umayumcha_ims/models/branch_product_model.dart'; // Import BranchProduct model
import 'package:umayumcha_ims/controllers/consumable_controller.dart'; // New: Import ConsumableController
import 'package:umayumcha_ims/models/consumable_model.dart'; // New: Import Consumable model
import 'package:umayumcha_ims/widgets/item_selection_dialog.dart'; // New: Import ItemSelectionDialog
import 'package:umayumcha_ims/models/delivery_note_model.dart'; // Import DeliveryNote model
import 'package:umayumcha_ims/utils/file_exporter.dart'; // New: Import file_exporter
import 'package:umayumcha_ims/controllers/auth_controller.dart'; // Import AuthController
import 'package:intl/intl.dart'; // Import intl package
import 'package:umayumcha_ims/models/selectable_item.dart'; // Import SelectableItem

class DeliveryNoteFormScreen extends StatefulWidget {
  final DeliveryNote? deliveryNote;
  const DeliveryNoteFormScreen({super.key, this.deliveryNote});

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
  final TextEditingController keteranganController =
      TextEditingController(); // New: Keterangan controller
  DateTime selectedDeliveryDate = DateTime.now();

  Branch? selectedToBranch; // New: Selected destination branch

  final RxList<Map<String, dynamic>> selectedProducts =
      <Map<String, dynamic>>[].obs;

  Rx<Branch?> umayumchaHQBranch = Rx<Branch?>(
    null,
  ); // To hold the UmayumchaHQ branch

  String?
  deliveryNoteId; // New: To store the ID of the delivery note being edited

  @override
  void initState() {
    super.initState();
    if (widget.deliveryNote != null) {
      deliveryNoteId = widget.deliveryNote!.id;
      selectedDeliveryDate = widget.deliveryNote!.deliveryDate;
      selectedProducts.clear(); // Clear existing items before populating
      // Find the branch object from branchController.branches based on to_branch_id
      selectedToBranch = branchController.branches.firstWhereOrNull(
        (branch) => branch.id == widget.deliveryNote!.toBranchId,
      );
      keteranganController.text =
          widget.deliveryNote!.keterangan ?? ''; // Initialize keterangan

      // Populate selectedProducts from existing productItems and consumableItems
      if (widget.deliveryNote!.productItems != null) {
        for (var item in widget.deliveryNote!.productItems!) {
          selectedProducts.add({
            'id': item['product_id'],
            'name': item['product_name'],
            'quantity': item['quantity_change'],
            'type': 'product',
            'description': item['reason'], // Add description
          });
        }
      }
      if (widget.deliveryNote!.consumableItems != null) {
        for (var item in widget.deliveryNote!.consumableItems!) {
          selectedProducts.add({
            'id': item['consumable_id'].toString(), // Convert int to String
            'name': item['consumable_name'],
            'quantity': item['quantity_change'],
            'type': 'consumable',
            'description': item['reason'], // Add description
          });
        }
      }
    }

    // Listen for changes in branches and set UmayumchaHQ
    ever(branchController.branches, (_) {
      _findAndSetUmayumchaHQBranch();
    });

    // Also check immediately in case branches are already loaded
    _findAndSetUmayumchaHQBranch();
  }

  void _findAndSetUmayumchaHQBranch() {
    final foundBranch = branchController.branches.firstWhereOrNull(
      (branch) => branch.id == '2e109b1a-12c6-4572-87ab-6c96add8a603',
    );
    if (foundBranch != null) {
      umayumchaHQBranch.value = foundBranch;
    } else if (!branchController.isLoading.value) {
      Get.snackbar(
        'Error',
        'HeadQuarter branch not found. Please ensure it exists.',
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

  void _addProductToNote() async {
    if (umayumchaHQBranch.value == null) {
      Get.snackbar('Error', 'HeadQuarter branch not found. Cannot add item.');
      return;
    }

    if (umayumchaHQBranch.value!.id == null) {
      Get.snackbar('Error', 'HeadQuarter branch ID is missing.');
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

    final SelectableItem? selectedItem = await Get.dialog<SelectableItem>(
      ItemSelectionDialog(items: selectableItems),
    );

    if (selectedItem != null) {
      final TextEditingController quantityController = TextEditingController();
      final TextEditingController descriptionController =
          TextEditingController(); // New: Description controller
      Get.dialog(
        AlertDialog(
          title: Text('Add Item: ${selectedItem.name}'), // Changed title
          content: Column(
            // Use Column to hold multiple text fields
            mainAxisSize: MainAxisSize.min, // Make column take minimum space
            children: [
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantity (Max: ${selectedItem.quantity})',
                ),
              ),
              const SizedBox(height: 16), // Add some spacing
              TextField(
                controller:
                    descriptionController, // New: Description text field
                decoration: const InputDecoration(
                  labelText: 'Keterangan (Optional)',
                ),
                maxLines: 3, // Allow multiple lines for description
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Get.back(); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final int? quantity = int.tryParse(quantityController.text);
                if (quantity != null &&
                    quantity > 0 &&
                    quantity <= selectedItem.quantity) {
                  selectedProducts.add({
                    'id': selectedItem.id,
                    'name': selectedItem.name,
                    'quantity': quantity,
                    'type': selectedItem.type,
                    'description':
                        descriptionController.text, // New: Add description
                  });
                  Get.back(); // Close dialog
                } else {
                  Get.snackbar(
                    'Error',
                    'Please enter a valid quantity within available stock.',
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
          widget.deliveryNote == null
              ? 'Create Delivery Note'
              : 'Edit Delivery Note',
          style: const TextStyle(
            color: Colors.white, // White text for consistency
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor, // Use primary color
        iconTheme: const IconThemeData(
          color: Colors.white,
        ), // White back button
        elevation: 4, // Restore default elevation
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.deliveryNote?.dnNumber != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'DN Number: ${widget.deliveryNote!.dnNumber}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            // From Branch Selection (Hidden and pre-selected to UmayumchaHQ)
            Obx(() {
              if (branchController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (umayumchaHQBranch.value == null) {
                return const Text(
                  'Headquarter branch not found. Please ensure it exists.',
                  style: TextStyle(color: Colors.red),
                );
              }
              return AbsorbPointer(
                child: DropdownButtonFormField<Branch>(
                  decoration: InputDecoration(
                    labelText: 'From Branch',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.warehouse),
                  ),
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
                return const Center(child: CircularProgressIndicator());
              }
              if (branchController.branches.isEmpty) {
                return const SizedBox.shrink();
              }
              final List<Branch> otherBranches =
                  branchController.branches
                      .where(
                        (branch) =>
                            branch.id != '2e109b1a-12c6-4572-87ab-6c96add8a603',
                      )
                      .toList();
              return DropdownButtonFormField<Branch>(
                decoration: InputDecoration(
                  labelText: 'To Branch',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.store),
                ),
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

            // Products for Delivery Section
            Text(
              'Items for Delivery:',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
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
                shrinkWrap: true, // Important for nested ListView in Column
                physics:
                    const NeverScrollableScrollPhysics(), // Disable scrolling for nested ListView
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
                            ), // Adjust padding to align with subtitle
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
                onPressed: _addProductToNote,
                icon: const Icon(Icons.add),
                label: const Text('Add Item to Delivery Note'),
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
              return deliveryNoteController.isLoading.value
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                    children: [
                      SizedBox(
                        width: double.infinity, // Make button full width
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (umayumchaHQBranch.value == null) {
                              Get.snackbar(
                                'Error',
                                'Headquarter branch not found.',
                              );
                              return;
                            }
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
                                'Please add at least one item to the delivery note.',
                              );
                              return;
                            }
                            if (umayumchaHQBranch.value!.id == null) {
                              Get.snackbar(
                                'Error',
                                'Headquarter Branch ID is missing.',
                              );
                              return;
                            }
                            if (selectedToBranch!.id == null) {
                              Get.snackbar('Error', 'To Branch ID is missing.');
                              return;
                            }

                            if (widget.deliveryNote == null) {
                              // Create new delivery note
                              deliveryNoteController.createDeliveryNote(
                                customerName: 'Internal Transfer',
                                destinationAddress: 'Internal Transfer',
                                deliveryDate: selectedDeliveryDate,
                                fromBranchId: umayumchaHQBranch.value!.id!,
                                toBranchId: selectedToBranch!.id!,
                                items: selectedProducts.toList(),
                                keterangan: keteranganController.text,
                              );
                            } else {
                              // Update existing delivery note
                              deliveryNoteController.updateDeliveryNote(
                                deliveryNoteId: deliveryNoteId!,
                                customerName: 'Internal Transfer',
                                destinationAddress: 'Internal Transfer',
                                deliveryDate: selectedDeliveryDate,
                                fromBranchId: umayumchaHQBranch.value!.id!,
                                toBranchId: selectedToBranch!.id!,
                                newItems: selectedProducts.toList(),
                                originalItems:
                                    widget.deliveryNote!.productItems! +
                                    widget.deliveryNote!.consumableItems!,
                                keterangan: keteranganController.text,
                              );
                            }
                          },
                          icon: Icon(
                            widget.deliveryNote == null
                                ? Icons.save
                                : Icons.update,
                          ),
                          label: Text(
                            widget.deliveryNote == null
                                ? 'Save Delivery Note'
                                : 'Update Delivery Note',
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
                      ),
                      if (widget.deliveryNote != null) ...[
                        Obx(() {
                          final AuthController authController = Get.find();
                          if (authController.userRole.value == 'admin') {
                            return Column(
                              children: [
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      // Added async
                                      final excelBytes =
                                          await deliveryNoteController
                                              .exportToExcel(
                                                deliveryNote:
                                                    widget.deliveryNote!,
                                                toBranchName:
                                                    selectedToBranch?.name ??
                                                    'N/A',
                                                items:
                                                    selectedProducts.toList(),
                                              );
                                      if (excelBytes != null) {
                                        await exportPdfAndExcel(
                                          pdfBytes:
                                              [], // No PDF bytes for Excel export
                                          pdfFileName: '', // No PDF file name
                                          excelBytes: excelBytes,
                                          excelFileName:
                                              'DeliveryNote_${(widget.deliveryNote!.dnNumber ?? widget.deliveryNote!.id).replaceAll('/', '_')}.xlsx',
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.download),
                                    label: const Text('Export to Excel'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 15,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      backgroundColor:
                                          Colors.green, // Green for Excel
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      // Added async
                                      final pdfBytes =
                                          await deliveryNoteController
                                              .exportToPdf(
                                                deliveryNote:
                                                    widget.deliveryNote!,
                                                toBranchName:
                                                    selectedToBranch?.name ??
                                                    'N/A',
                                                items:
                                                    selectedProducts.toList(),
                                              );
                                      if (pdfBytes != null) {
                                        await exportPdfAndExcel(
                                          pdfBytes: pdfBytes,
                                          pdfFileName:
                                              'DeliveryNote_${(widget.deliveryNote!.dnNumber ?? widget.deliveryNote!.id).replaceAll('/', '_')}.pdf',
                                          excelBytes:
                                              [], // No Excel bytes for PDF export
                                          excelFileName:
                                              '', // No Excel file name
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.picture_as_pdf),
                                    label: const Text('Export to PDF'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 15,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      backgroundColor:
                                          Colors.red, // Red for PDF
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          } else {
                            return const SizedBox.shrink();
                          }
                        }),
                      ],
                    ],
                  );
            }),
          ],
        ),
      ),
    );
  }
}
