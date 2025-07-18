
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:umayumcha/controllers/consumable_transaction_log_controller.dart';

class ConsumableTransactionLogScreen extends StatelessWidget {
  final ConsumableTransactionLogController controller = Get.put(ConsumableTransactionLogController());

  ConsumableTransactionLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consumable Transaction Log'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.transactions.isEmpty) {
          return const Center(child: Text('No consumable transactions found.'));
        }
        return ListView.builder(
          itemCount: controller.transactions.length,
          itemBuilder: (context, index) {
            final transaction = controller.transactions[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${transaction.consumableName ?? 'N/A'} - ${transaction.type.toUpperCase()}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Quantity Change: ${transaction.quantityChange}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (transaction.reason != null && transaction.reason!.isNotEmpty)
                      Text(
                        'Reason: ${transaction.reason}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    Text(
                      'Date: ${DateFormat('yyyy-MM-dd HH:mm').format(transaction.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (transaction.userEmail != null && transaction.userEmail!.isNotEmpty)
                      Text(
                        'By: ${transaction.userEmail}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
