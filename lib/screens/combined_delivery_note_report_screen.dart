
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:umayumcha_ims/controllers/combined_delivery_note_report_controller.dart';
import 'package:umayumcha_ims/utils/combined_report_exporter.dart';

class CombinedDeliveryNoteReportScreen extends StatelessWidget {
  CombinedDeliveryNoteReportScreen({super.key});

  final CombinedDeliveryNoteReportController controller = Get.put(CombinedDeliveryNoteReportController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Delivery Note (In & Out)'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildFilterSection(context),
          ),
          _buildExportButtons(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.reportData.isEmpty) {
                return const Center(child: Text('No data available for the selected filters.'));
              }
              return _buildDataTable();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context) {
    return Column(
      children: [
        Obx(() {
          return DropdownButtonFormField<String?>(
            decoration: const InputDecoration(
              labelText: 'Filter by Product/Consumable',
              border: OutlineInputBorder(),
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
              ...controller.itemNames.map((name) {
                return DropdownMenuItem<String?>(
                  value: name,
                  child: Text(name),
                );
              }),
            ],
          );
        }),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Obx(() => TextFormField(
                readOnly: true,
                controller: TextEditingController(
                  text: controller.selectedFromDate.value == null
                      ? ''
                      : DateFormat('yyyy-MM-dd').format(controller.selectedFromDate.value!),
                ),
                decoration: const InputDecoration(
                  labelText: 'From Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: controller.selectedFromDate.value ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null) {
                    controller.selectedFromDate.value = picked;
                    controller.fetchReportData();
                  }
                },
              )),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Obx(() => TextFormField(
                readOnly: true,
                controller: TextEditingController(
                  text: controller.selectedToDate.value == null
                      ? ''
                      : DateFormat('yyyy-MM-dd').format(controller.selectedToDate.value!),
                ),
                decoration: const InputDecoration(
                  labelText: 'To Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: controller.selectedToDate.value ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null) {
                    controller.selectedToDate.value = picked;
                    controller.fetchReportData();
                  }
                },
              )),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExportButtons() {
    return Obx(() {
      final canExport = !controller.isLoading.value && controller.reportData.isNotEmpty;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: canExport
                    ? () => CombinedReportExporter.exportToPdf(controller.reportData)
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
                onPressed: null, // Excel export not implemented yet
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
    });
  }

  Widget _buildDataTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Item Name')),
          DataColumn(label: Text('Quantity')),
          DataColumn(label: Text('From Vendor')),
          DataColumn(label: Text('To Branch')),
          DataColumn(label: Text('Type')),
        ],
        rows: controller.reportData.map((item) {
          return DataRow(
            cells: [
              DataCell(Text(DateFormat('yyyy-MM-dd').format(item.date))),
              DataCell(Text(item.itemName)),
              DataCell(Text(item.quantity.toString())),
              DataCell(Text(item.fromVendor ?? '')),
              DataCell(Text(item.toBranch ?? '')),
              DataCell(Text(item.type)),
            ],
          );
        }).toList(),
      ),
    );
  }
}
