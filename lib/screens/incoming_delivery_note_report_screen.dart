import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:umayumcha_ims/controllers/auth_controller.dart';
import 'package:umayumcha_ims/controllers/incoming_delivery_note_report_controller.dart'; // Updated import
import 'package:umayumcha_ims/utils/pdf_report_exporter.dart';
import 'package:umayumcha_ims/utils/excel_report_exporter.dart';

class IncomingDeliveryNoteReportScreen extends StatelessWidget {
  const IncomingDeliveryNoteReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final IncomingDeliveryNoteReportController controller = Get.put(
      IncomingDeliveryNoteReportController(),
    ); // Updated controller
    final AuthController authController = Get.find();

    if (authController.userRole.value != 'finance') {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Text('You do not have permission to view this report.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Incoming Delivery Notes Report',
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
                // Filter by From Branch
                Obx(() {
                  return DropdownButtonFormField<String?>(
                    decoration: const InputDecoration(
                      labelText: 'Filter by From Vendor',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    value: controller.selectedFromBranchName.value,
                    hint: const Text('All Vendor'),
                    onChanged: (newValue) {
                      controller.selectedFromBranchName.value = newValue;
                      controller.fetchReportData();
                    },
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Vendor'),
                      ),
                      ...controller.distinctFromBranchNames.map((branchName) {
                        return DropdownMenuItem<String?>(
                          value: branchName,
                          child: Text(branchName),
                        );
                      }),
                    ],
                  );
                }),
                const SizedBox(height: 16),

                // Filter by Item Name
                Obx(() {
                  return DropdownButtonFormField<String?>(
                    decoration: const InputDecoration(
                      labelText: 'Filter by Product/Consumable',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    value: controller.selectedItemName.value,
                    hint: const Text('All Items'),
                    onChanged: (newValue) {
                      controller.selectedItemName.value = newValue;
                      controller.fetchReportData();
                    },
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Items'),
                      ),
                      ...controller.distinctProductConsumableNames.map((
                        itemName,
                      ) {
                        return DropdownMenuItem<String?>(
                          value: itemName,
                          child: Text(itemName),
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
                              controller.fetchReportData();
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
                              controller.fetchReportData();
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
          // Export Buttons
          Obx(() {
            final bool canExport =
                !controller.isLoading.value &&
                controller.reportItems.isNotEmpty;
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          canExport
                              ? () {
                                PdfReportExporter.generateAndOpenPdfIncoming(
                                  reportItems: controller.reportItems,
                                  totalOverallCost:
                                      controller.totalOverallCost.value,
                                  totalOverallQuantity:
                                      controller.totalOverallQuantity.value,
                                );
                              }
                              : null,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Export PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          canExport
                              ? () {
                                ExcelReportExporter.generateAndOpenExcel(
                                  reportItems: controller.reportItems,
                                  totalOverallCost:
                                      controller.totalOverallCost.value,
                                  totalOverallQuantity:
                                      controller.totalOverallQuantity.value,
                                );
                              }
                              : null,
                      icon: const Icon(Icons.table_chart),
                      label: const Text('Export Excel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.reportItems.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No report data found for the selected filters.',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: controller.reportItems.length,
                itemBuilder: (context, index) {
                  final item = controller.reportItems[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item['item_name']} (${item['type'] == 'product' ? 'Product' : 'Consumable'})',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('From: ${item['from_branch_name']}'),
                          Text(
                            'Delivery Date: ${DateFormat('dd-MMM-yyyy HH:mm').format(item['delivery_date'])}',
                          ),
                          Text('Quantity: ${item['quantity']}'),
                          Text(
                            'Price per Unit: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(item['price_per_unit'])}',
                          ),
                          Text(
                            'Total Price: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(item['total_price'])}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          if (item['keterangan'] != null &&
                              item['keterangan'].isNotEmpty)
                            Text('Description: ${item['keterangan']}'),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          // Summary Section
          Obx(() {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 10),
                  Text(
                    'Total Overall Quantity: ${controller.totalOverallQuantity.value}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Total Overall Cost: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(controller.totalOverallCost.value)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
