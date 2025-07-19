import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:umayumcha/controllers/delivery_note_controller.dart';
import 'package:umayumcha/screens/delivery_note_form_screen.dart';

class DeliveryNoteListScreen extends StatelessWidget {
  const DeliveryNoteListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DeliveryNoteController controller = Get.put(DeliveryNoteController());

    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Notes (Reports)')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.deliveryNotes.isEmpty) {
          return const Center(child: Text('No delivery notes found.'));
        }
        return ListView.builder(
          itemCount: controller.deliveryNotes.length,
          itemBuilder: (context, index) {
            final note = controller.deliveryNotes[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ExpansionTile(
                title: Text(
                  '${note.customerName} - ${DateFormat('dd/MM/yyyy').format(note.deliveryDate)}',
                ),
                subtitle: Text(
                  '${note.destinationAddress ?? 'No Address'} | From: ${note.fromBranchName ?? 'N/A'} | To: ${note.toBranchName ?? 'N/A'}',
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Items:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (note.items != null && note.items!.isNotEmpty)
                          ...note.items!.map(
                            (item) => Text(
                              '- ${item['product_name']} (x${item['quantity_change']})',
                            ),
                          )
                        else
                          const Text(
                            'No items recorded for this delivery note.',
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => DeliveryNoteFormScreen());
        },
        tooltip: 'Create Delivery Note',
        child: const Icon(Icons.add),
      ),
    );
  }
}
