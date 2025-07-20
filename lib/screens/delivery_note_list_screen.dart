import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:umayumcha/controllers/delivery_note_controller.dart';

class DeliveryNoteListScreen extends StatelessWidget {
  const DeliveryNoteListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DeliveryNoteController controller = Get.put(DeliveryNoteController());

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Delivery Notes',
          style: TextStyle(
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // To Branch Filter
                Obx(() {
                  return DropdownButtonFormField<String?>(
                    decoration: const InputDecoration(
                      labelText: 'Filter by To Branch',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    value: controller.selectedToBranchName.value,
                    hint: const Text('All Branches'),
                    onChanged: (newValue) {
                      controller.selectedToBranchName.value = newValue;
                    },
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Branches'),
                      ),
                      ...controller.distinctToBranchNames.map((branchName) {
                        return DropdownMenuItem<String?>(
                          value: branchName,
                          child: Text(branchName),
                        );
                      }),
                    ],
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
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Filter Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          controller.fetchDeliveryNotes();
                        },
                        icon: const Icon(Icons.filter_list),
                        label: const Text('Apply Filters'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          controller.selectedToBranchName.value = null;
                          controller.selectedFromDate.value = null;
                          controller.selectedToDate.value = null;
                          controller.fetchDeliveryNotes();
                        },
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear Filters'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.deliveryNotes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.note_add_outlined, // A more aesthetic icon
                        size: 80,
                        color:
                            Colors.grey[300], // Light grey for minimalist feel
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No delivery notes found.',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600], // Slightly darker grey
                        ),
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
                padding: const EdgeInsets.all(16.0), // Add padding to the list
                itemCount: controller.deliveryNotes.length,
                itemBuilder: (context, index) {
                  final note = controller.deliveryNotes[index];
                  return Container(
                    margin: const EdgeInsets.only(
                      bottom: 16,
                    ), // Spacing between cards
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        12,
                      ), // Rounded corners
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(
                            alpha: 0.1,
                          ), // Subtle shadow
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
                        note.customerName ?? 'Internal Transfer',
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
                            'Date: ${DateFormat('dd MMM yyyy').format(note.deliveryDate)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'From: ${note.fromBranchName ?? 'N/A'} | To: ${note.toBranchName ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      children: [
                        const Divider(
                          height: 1,
                          color: Colors.grey,
                        ), // Separator
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
                                    child: Row(
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
                                  ),
                                ),
                              if (note.consumableItems != null &&
                                  note.consumableItems!.isNotEmpty)
                                ...note.consumableItems!.map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 5.0),
                                    child: Row(
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
                                  ),
                                ),
                              if ((note.productItems == null ||
                                      note.productItems!.isEmpty) &&
                                  (note.consumableItems == null ||
                                      note.consumableItems!.isEmpty))
                                Text(
                                  'No items recorded for this delivery note.',
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
    );
  }
}
