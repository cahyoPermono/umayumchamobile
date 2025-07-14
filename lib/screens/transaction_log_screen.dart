import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:umayumcha/controllers/transaction_log_controller.dart';
import 'package:umayumcha/models/inventory_transaction_model.dart'; // Explicitly import the model

class TransactionLogScreen extends StatelessWidget {
  const TransactionLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TransactionLogController controller = Get.put(
      TransactionLogController(),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => controller.exportTransactionsToPdf(),
            tooltip: 'Export to PDF',
          ),
          IconButton(
            icon: const Icon(Icons.table_chart),
            onPressed: () => controller.exportTransactionsToExcel(),
            tooltip: 'Export to Excel',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: Obx(
                    () => ListTile(
                      title: const Text('From:'),
                      subtitle: Text(
                        controller.startDate.value != null
                            ? DateFormat(
                              'dd/MM/yyyy',
                            ).format(controller.startDate.value!)
                            : 'Select Date',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate:
                              controller.startDate.value ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          controller.startDate.value = picked;
                        }
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Obx(
                    () => ListTile(
                      title: const Text('To:'),
                      subtitle: Text(
                        controller.endDate.value != null
                            ? DateFormat(
                              'dd/MM/yyyy',
                            ).format(controller.endDate.value!)
                            : 'Select Date',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate:
                              controller.endDate.value ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          controller.endDate.value = picked;
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.transactions.isEmpty) {
                return const Center(
                  child: Text(
                    'No transactions found for the selected date range.',
                  ),
                );
              }
              return ListView.builder(
                itemCount: controller.transactions.length,
                itemBuilder: (context, index) {
                  final InventoryTransaction transaction =
                      controller.transactions[index];
                  final bool isIncoming = transaction.type == 'in';
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading: Icon(
                        isIncoming
                            ? Icons.arrow_circle_down
                            : Icons.arrow_circle_up,
                        color: isIncoming ? Colors.green : Colors.red,
                      ),
                      title: Text(
                        '${transaction.quantityChange} x ${transaction.productName ?? transaction.productId}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Type: ${transaction.type.capitalizeFirst}'),
                          if (transaction.fromBranchId != null)
                            Text(
                              'From: ${transaction.fromBranchName ?? 'N/A'}',
                            ),
                          if (transaction.toBranchId != null)
                            Text('To: ${transaction.toBranchName ?? 'N/A'}'),
                          Text('Reason: ${transaction.reason ?? 'N/A'}'),
                          Text(
                            'Date: ${DateFormat('dd MMM yyyy, HH:mm').format(transaction.createdAt)}',
                          ),
                        ],
                      ),
                      trailing: Text(
                        isIncoming
                            ? '+${transaction.quantityChange}'
                            : '-${transaction.quantityChange}',
                        style: TextStyle(
                          color: isIncoming ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
