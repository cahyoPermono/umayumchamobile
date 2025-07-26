import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:umayumcha_ims/controllers/incoming_delivery_note_controller.dart';
import 'package:umayumcha_ims/controllers/inventory_controller.dart';
import 'package:umayumcha_ims/controllers/consumable_controller.dart';
import 'package:umayumcha_ims/screens/incoming_delivery_note_form_screen.dart';

class IncomingDeliveryNoteListScreen extends StatelessWidget {
  const IncomingDeliveryNoteListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final IncomingDeliveryNoteController controller = Get.put(
      IncomingDeliveryNoteController(),
    );
    final InventoryController inventoryController = Get.find();
    final ConsumableController consumableController = Get.find();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Delivery Notes (In)',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 4,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // To Branch Filter
                Obx(() {
                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Filter by Vendor',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                    ),
                    value: controller.selectedVendorName.value,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Vendors'),
                      ),
                      ...controller.distinctVendorNames.map((vendorName) {
                        return DropdownMenuItem(
                          value: vendorName,
                          child: Text(vendorName),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      controller.selectedVendorName.value = value;
                      controller.fetchIncomingDeliveryNotes();
                    },
                  );
                }),
                const SizedBox(height: 16),

                // Date Filters
                Row(
                  children: [
                    Expanded(
                      child: Obx(
                        () => TextFormField(
                          readOnly: true,
                          controller: TextEditingController(
                            text:
                                controller.selectedFromDate.value == null
                                    ? ''
                                    : DateFormat('dd/MM/yyyy').format(
                                      controller.selectedFromDate.value!,
                                    ),
                          ),
                          decoration: const InputDecoration(
                            labelText: 'From Date',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate:
                                  controller.selectedFromDate.value ??
                                  DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (pickedDate != null) {
                              controller.selectedFromDate.value = pickedDate;
                              controller.fetchIncomingDeliveryNotes();
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Obx(
                        () => TextFormField(
                          readOnly: true,
                          controller: TextEditingController(
                            text:
                                controller.selectedToDate.value == null
                                    ? ''
                                    : DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(controller.selectedToDate.value!),
                          ),
                          decoration: const InputDecoration(
                            labelText: 'To Date',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate:
                                  controller.selectedToDate.value ??
                                  DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (pickedDate != null) {
                              controller.selectedToDate.value = pickedDate;
                              controller.fetchIncomingDeliveryNotes();
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.incomingDeliveryNotes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.note_add_outlined,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No incoming delivery notes found.',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Tap the + button to create one.',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: controller.incomingDeliveryNotes.length,
                itemBuilder: (context, index) {
                  final note = controller.incomingDeliveryNotes[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      title: Text(
                        note.fromVendorName ?? 'N/A',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            'Date: ${DateFormat('dd-MMM-yyyy HH:mm').format(note.deliveryDate)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'To: ${note.toBranchName}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.grey),
                            onPressed: () {
                              Get.to(
                                () => IncomingDeliveryNoteFormScreen(
                                  incomingDeliveryNote: note,
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              Get.defaultDialog(
                                title: "Delete Incoming Delivery Note",
                                middleText:
                                    "Are you sure you want to delete this incoming delivery note? This action cannot be undone and will reverse product quantities.",
                                textConfirm: "Delete",
                                textCancel: "Cancel",
                                confirmTextColor: Colors.white,
                                buttonColor: Colors.red,
                                onConfirm: () {
                                  controller.deleteIncomingDeliveryNote(
                                    note.id,
                                  );
                                  inventoryController
                                      .fetchBranchProducts(); // Refresh relevant data
                                  consumableController
                                      .fetchConsumables(); // Refresh relevant data
                                  Get.back();
                                },
                              );
                            },
                          ),
                        ],
                      ),
                      children: [
                        const Divider(height: 1, color: Colors.grey),
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Items:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (note.productItems != null &&
                                  note.productItems!.isNotEmpty)
                                ...note.productItems!.map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 5.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.inventory_2_outlined,
                                              size: 18,
                                              color: Colors.blueGrey,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                '${item['product_name']} (x${item['quantity_change']})',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.grey[800],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (item['reason'] != null &&
                                            item['reason'].isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 26.0,
                                              top: 2.0,
                                            ),
                                            child: Text(
                                              'Keterangan: ${item['reason']}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (note.consumableItems != null &&
                                  note.consumableItems!.isNotEmpty)
                                ...note.consumableItems!.map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 5.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.category_outlined,
                                              size: 18,
                                              color: Colors.teal,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                '${item['consumable_name']} (x${item['quantity_change']})',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.grey[800],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (item['reason'] != null &&
                                            item['reason'].isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 26.0,
                                              top: 2.0,
                                            ),
                                            child: Text(
                                              'Keterangan: ${item['reason']}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              if ((note.productItems == null ||
                                      note.productItems!.isEmpty) &&
                                  (note.consumableItems == null ||
                                      note.consumableItems!.isEmpty))
                                Text(
                                  'No items recorded for this incoming delivery note.',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => const IncomingDeliveryNoteFormScreen());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
