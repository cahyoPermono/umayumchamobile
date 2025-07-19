import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:umayumcha/controllers/consumable_transaction_log_controller.dart';

class ConsumableTransactionLogScreen extends StatelessWidget {
  final ConsumableTransactionLogController controller = Get.put(
    ConsumableTransactionLogController(),
  );

  ConsumableTransactionLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consumable Transaction Log')),
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
                            text: controller.fromDate.value == null
                                ? ''
                                : DateFormat('yyyy-MM-dd')
                                    .format(controller.fromDate.value!),
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
                                  controller.fromDate.value ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (pickedDate != null) {
                              controller.setFromDate(pickedDate);
                              controller.filterTransactions();
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
                            text: controller.toDate.value == null
                                ? ''
                                : DateFormat('yyyy-MM-dd')
                                    .format(controller.toDate.value!),
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
                                  controller.toDate.value ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (pickedDate != null) {
                              controller.setToDate(pickedDate);
                              controller.filterTransactions();
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Obx(
                  () => DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Filter by Destination Branch',
                      border: OutlineInputBorder(),
                    ),
                    value: controller.selectedBranchDestination.value,
                    hint: const Text('Select a branch'),
                    onChanged: (String? newValue) {
                      controller.setSelectedBranchDestination(newValue);
                    },
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Branches'),
                      ),
                      ...controller.distinctBranchDestinations.map((branch) {
                        return DropdownMenuItem(
                          value: branch,
                          child: Text(branch),
                        );
                      }),
                    ],
                  ),
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
                    child: Text('No consumable transactions found.'));
              }
              return ListView.builder(
                itemCount: controller.transactions.length,
                itemBuilder: (context, index) {
                  final transaction = controller.transactions[index];
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
                                  transaction.consumableName ?? 'N/A',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                transaction.type == 'in'
                                    ? Icons.arrow_circle_up
                                    : Icons.arrow_circle_down,
                                color: transaction.type == 'in'
                                    ? Colors.green
                                    : Colors.red,
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
                                  color: transaction.type == 'in'
                                      ? Colors.green
                                      : Colors.red,
                                ),
                          ),
                          const SizedBox(height: 4),
                          if (transaction.branchSourceName != null &&
                              transaction.branchSourceName!.isNotEmpty)
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
                                    'From: ${transaction.branchSourceName}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          if (transaction.branchDestinationName != null &&
                              transaction.branchDestinationName!.isNotEmpty)
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
                                    'To: ${transaction.branchDestinationName}',
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
                                'Date: ${DateFormat('yyyy-MM-dd HH:mm').format(transaction.createdAt)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                              if (transaction.userEmail != null &&
                                  transaction.userEmail!.isNotEmpty)
                                Text(
                                  'By: ${transaction.userEmail}',
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
        ],)
    );
  }
}
