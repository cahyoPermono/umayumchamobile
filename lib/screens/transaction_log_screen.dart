import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:umayumcha_ims/controllers/transaction_log_controller.dart';
import 'package:umayumcha_ims/models/inventory_transaction_model.dart'; // Explicitly import the model

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
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Obx(
                        () => TextFormField(
                          controller: TextEditingController(
                            text: controller.startDate.value == null
                                ? ''
                                : DateFormat('yyyy-MM-dd')
                                    .format(controller.startDate.value!),
                          ),
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'From Date',
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate:
                                  controller.startDate.value ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (pickedDate != null) {
                              controller.startDate.value = pickedDate;
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Obx(
                        () => TextFormField(
                          controller: TextEditingController(
                            text: controller.endDate.value == null
                                ? ''
                                : DateFormat('yyyy-MM-dd')
                                    .format(controller.endDate.value!),
                          ),
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'To Date',
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate:
                                  controller.endDate.value ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (pickedDate != null) {
                              controller.endDate.value = pickedDate;
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Search (Product, From Branch, To Branch)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    controller.searchQuery.value = value;
                  },
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
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  transaction.productName ?? 'N/A',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                isIncoming
                                    ? Icons.arrow_circle_up
                                    : Icons.arrow_circle_down,
                                color: isIncoming ? Colors.green : Colors.red,
                                size: 28,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Quantity: ${transaction.quantityChange > 0 ? '+' : ''}${transaction.quantityChange}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  color: isIncoming ? Colors.green : Colors.red,
                                ),
                          ),
                          const SizedBox(height: 4),
                          if (transaction.fromBranchName != null &&
                              transaction.fromBranchName!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'From: ${transaction.fromBranchName}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          if (transaction.toBranchName != null &&
                              transaction.toBranchName!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'To: ${transaction.toBranchName}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          if (transaction.reason != null &&
                              transaction.reason!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Text(
                                'Reason: ${transaction.reason}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Date: ${DateFormat('yyyy-MM-dd HH:mm').format(transaction.createdAt.add(const Duration(hours: 7)))}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ],
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
