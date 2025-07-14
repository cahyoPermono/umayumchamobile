import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:umayumcha/models/inventory_transaction_model.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart'; // Import excel package
import 'dart:io';
import 'package:intl/intl.dart';

class TransactionLogController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;

  var transactions = <InventoryTransaction>[].obs;
  var isLoading = false.obs;
  var startDate = Rx<DateTime?>(null);
  var endDate = Rx<DateTime?>(null);

  @override
  void onInit() {
    // Set default date range (e.g., last 30 days)
    endDate.value = DateTime.now();
    startDate.value = endDate.value!.subtract(const Duration(days: 30));
    fetchTransactions();
    // Listen to date range changes
    ever(startDate, (_) => fetchTransactions());
    ever(endDate, (_) => fetchTransactions());
    super.onInit();
  }

  Future<void> fetchTransactions() async {
    try {
      isLoading.value = true;
      String selectQuery =
          '*, products(name), from_branch_id(name), to_branch_id(name)';
      List<String> conditions = [];

      if (startDate.value != null) {
        conditions.add('created_at.gte.${startDate.value!.toIso8601String()}');
      }
      if (endDate.value != null) {
        conditions.add(
          'created_at.lte.${endDate.value!.add(const Duration(days: 1)).toIso8601String()}',
        );
      }

      if (conditions.isNotEmpty) {
        selectQuery +=
            '.filter(${conditions.join(',')})'; // Append filter to select string
      }

      final response = await supabase
          .from('inventory_transactions')
          .select(selectQuery) // Pass the full select string with filters
          .order('created_at', ascending: false);

      transactions.value =
          (response as List).map((item) {
            final Map<String, dynamic> transactionData = Map.from(item);
            transactionData['product_name'] = item['products']?['name'];
            transactionData['from_branch_name'] =
                item['from_branch_id']?['name'];
            transactionData['to_branch_name'] = item['to_branch_id']?['name'];
            return InventoryTransaction.fromJson(transactionData);
          }).toList();
      debugPrint('Transactions fetched: ${transactions.length}');
    } catch (e) {
      debugPrint('Error fetching transactions: ${e.toString()}');
      Get.snackbar('Error', 'Failed to fetch transactions: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> exportTransactionsToPdf() async {
    if (transactions.isEmpty) {
      Get.snackbar('Info', 'No transactions to export.');
      return;
    }

    isLoading.value = true;
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Transaction Log Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Date Range: ${startDate.value != null ? DateFormat('dd/MM/yyyy').format(startDate.value!) : 'N/A'} - ${endDate.value != null ? DateFormat('dd/MM/yyyy').format(endDate.value!) : 'N/A'}',
                ),
                pw.SizedBox(height: 20),
                pw.TableHelper.fromTextArray(
                  headers: [
                    'Date',
                    'Product',
                    'Type',
                    'Qty',
                    'From',
                    'To',
                    'Reason',
                  ],
                  data:
                      transactions
                          .map(
                            (t) => [
                              DateFormat(
                                'dd/MM/yyyy HH:mm',
                              ).format(t.createdAt),
                              t.productName ?? t.productId,
                              t.type.capitalizeFirst,
                              t.quantityChange.toString(),
                              t.fromBranchName ?? '-',
                              t.toBranchName ?? '-',
                              t.reason ?? '-',
                            ],
                          )
                          .toList(),
                ),
              ],
            );
          },
        ),
      );

      final directory = await getDownloadsDirectory(); // Use getDownloadsDirectory()
      if (directory == null) {
        Get.snackbar('Error', 'Could not find downloads directory.');
        isLoading.value = false;
        return;
      }
      final filePath =
          '${directory.path}/transaction_log_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      Get.snackbar('Success', 'PDF exported to $filePath');
      debugPrint('PDF exported to: $filePath');
    } catch (e) {
      debugPrint('Error exporting PDF: ${e.toString()}');
      Get.snackbar('Error', 'Failed to export PDF: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> exportTransactionsToExcel() async {
    if (transactions.isEmpty) {
      Get.snackbar('Info', 'No transactions to export.');
      return;
    }

    isLoading.value = true;
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Transaction Log'];

      // Add headers
      sheet.appendRow([
        'Date',
        'Product',
        'Type',
        'Qty',
        'From',
        'To',
        'Reason',
      ]);

      // Add data
      for (var t in transactions) {
        sheet.appendRow([
          DateFormat('dd/MM/yyyy HH:mm').format(t.createdAt),
          t.productName ?? t.productId,
          t.type.capitalizeFirst,
          t.quantityChange.toString(),
          t.fromBranchName ?? '-',
          t.toBranchName ?? '-',
          t.reason ?? '-',
        ]);
      }

      final directory = await getDownloadsDirectory();
      if (directory == null) {
        Get.snackbar('Error', 'Could not find downloads directory.');
        isLoading.value = false;
        return;
      }
      final filePath = '${directory.path}/transaction_log_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!); // Use excel.encode() to get bytes

      Get.snackbar('Success', 'Excel exported to $filePath');
      debugPrint('Excel exported to: $filePath');
    } catch (e) {
      debugPrint('Error exporting Excel: ${e.toString()}');
      Get.snackbar('Error', 'Failed to export Excel: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
}
