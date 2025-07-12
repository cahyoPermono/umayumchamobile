import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:umayumcha/controllers/transaction_log_controller.dart';

class TransactionLogScreen extends StatelessWidget {
  const TransactionLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TransactionLogController controller = Get.put(
      TransactionLogController(),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Transaction Log')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.transactions.isEmpty) {
          return const Center(child: Text('No transactions found.'));
        }
        return ListView.builder(
          itemCount: controller.transactions.length,
          itemBuilder: (context, index) {
            final transaction = controller.transactions[index];
            final isIncoming = transaction.type == 'in';
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: Icon(
                  isIncoming ? Icons.arrow_circle_down : Icons.arrow_circle_up,
                  color: isIncoming ? Colors.green : Colors.red,
                ),
                title: Text(
                  '${transaction.quantityChange} x ${transaction.productName ?? transaction.productId}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Type: ${transaction.type.capitalizeFirst}'),
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
    );
  }
}
