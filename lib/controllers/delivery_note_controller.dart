import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:flutter/services.dart'; // For rootBundle
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:umayumcha_ims/controllers/consumable_controller.dart';
import 'package:umayumcha_ims/controllers/inventory_controller.dart';
import 'package:umayumcha_ims/models/delivery_note_model.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart' as pdf_colors; // New alias for PdfColors
import 'package:pdf/widgets.dart' as pdf_lib; // Changed alias to pdf_lib

import 'package:intl/intl.dart';

class DeliveryNoteController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;
  final InventoryController inventoryController = Get.find();
  final ConsumableController consumableController =
      Get.find(); // New: Get ConsumableController

  var deliveryNotes = <DeliveryNote>[].obs;
  var isLoading = false.obs;
  var distinctToBranchNames = <String>[].obs; // New: For filter dropdown
  var selectedToBranchName = Rx<String?>(null); // New: Selected filter
  var selectedFromDate = Rx<DateTime?>(null); // New: Selected filter
  var selectedToDate = Rx<DateTime?>(null); // New: Selected filter

  @override
  void onInit() {
    _initializeFiltersAndFetch();
    fetchDistinctToBranchNames(); // Fetch distinct branch names on init
    super.onInit();
  }

  void _initializeFiltersAndFetch() {
    // Set default fromDate to yesterday
    selectedFromDate.value = DateTime.now().subtract(const Duration(days: 1));
    // Set default toDate to today
    selectedToDate.value = DateTime.now();
    fetchDeliveryNotes(); // Fetch notes with initial filters
  }

  Future<void> fetchDistinctToBranchNames() async {
    try {
      final response = await supabase
          .from('distinct_to_branch_names') // Query the new view
          .select('to_branch_name');
      distinctToBranchNames.value =
          (response as List).map((e) => e['to_branch_name'] as String).toList();
    } catch (e) {
      debugPrint('Error fetching distinct branch names: ${e.toString()}');
    }
  }

  Future<void> fetchDeliveryNotes() async {
    try {
      isLoading.value = true;
      var query = supabase
          .from('delivery_notes')
          .select(
            '*, inventory_transactions(product_id, product_name, quantity_change, reason), consumable_transactions(consumable_id, consumable_name, quantity_change, reason), keterangan',
          );

      // Apply filters
      if (selectedToBranchName.value != null) {
        query = query.eq('to_branch_name', selectedToBranchName.value!);
      }
      if (selectedFromDate.value != null) {
        query = query.gte(
          'delivery_date',
          selectedFromDate.value!.toIso8601String().split('T').first,
        );
      }
      if (selectedToDate.value != null) {
        query = query.lte(
          'delivery_date',
          selectedToDate.value!
              .add(Duration(days: 1))
              .toIso8601String()
              .split('T')
              .first,
        );
      }

      final response = await query.order('created_at', ascending: false);
      debugPrint(response.toString());

      deliveryNotes.value =
          (response as List)
              .map((item) => DeliveryNote.fromJson(item))
              .toList();
      debugPrint('Delivery notes fetched: ${deliveryNotes.length}');
    } catch (e) {
      debugPrint('Error fetching delivery notes: ${e.toString()}');
      Get.snackbar('Error', 'Failed to fetch delivery notes: ${e.toString()}');
    } finally {
      isLoading(false);
    }
  }

  Future<void> deleteDeliveryNote(String deliveryNoteId) async {
    try {
      isLoading(true);
      await supabase.rpc(
        'delete_delivery_note_and_restock',
        params: {'p_delivery_note_id': deliveryNoteId},
      );
      Get.snackbar('Success', 'Delivery Note deleted and stock restored');
      fetchDeliveryNotes(); // Refresh the list
    } catch (e) {
      Get.snackbar('Error', 'Error deleting Delivery Note: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> createDeliveryNote({
    String? customerName,
    String? destinationAddress,
    required DateTime deliveryDate,
    required String fromBranchId,
    required String toBranchId,
    required List<Map<String, dynamic>> items, // {id, name, quantity, type}
    String? keterangan,
  }) async {
    try {
      isLoading.value = true;

      // Fetch branch names before inserting into delivery_notes
      final fromBranchResponse =
          await supabase
              .from('branches')
              .select('name')
              .eq('id', fromBranchId)
              .single();
      final String fromBranchName = fromBranchResponse['name'] as String;

      final toBranchResponse =
          await supabase
              .from('branches')
              .select('name')
              .eq('id', toBranchId)
              .single();
      final String toBranchName = toBranchResponse['name'] as String;

      // 1. Create the delivery note entry
      final response =
          await supabase
              .from('delivery_notes')
              .insert({
                'customer_name': customerName ?? 'Internal Transfer',
                'destination_address':
                    destinationAddress ?? 'Internal Transfer',
                'delivery_date': deliveryDate.toUtc().toIso8601String(),
                'from_branch_id': fromBranchId,
                'to_branch_id': toBranchId,
                'from_branch_name': fromBranchName, // Save branch name
                'to_branch_name': toBranchName, // Save branch name
                'keterangan': keterangan, // New field
              })
              .select('id') // Only select ID now, names are already saved
              .single();

      final String deliveryNoteId = response['id'];
      debugPrint('Delivery note created with ID: $deliveryNoteId');

      // 2. Create transactions for each item in the delivery note
      for (var item in items) {
        final String itemType = item['type'];
        final dynamic itemId =
            item['id']; // Use dynamic to handle both int and String
        final String itemName = item['name'];
        final int quantity = item['quantity'];

        if (itemType == 'product') {
          await inventoryController.addTransaction(
            productId: itemId as String, // Cast to String for products
            type: 'out',
            quantityChange: quantity,
            reason: 'Delivery Note: $customerName - ${item['description']}',
            deliveryNoteId: deliveryNoteId,
            fromBranchId: fromBranchId,
            toBranchId: toBranchId,
            fromBranchName: fromBranchName,
            toBranchName: toBranchName,
          );
          debugPrint('Transaction added for product $itemName');
        } else if (itemType == 'consumable') {
          await consumableController.addConsumableTransactionFromDeliveryNote(
            consumableId: int.parse(itemId), // Cast to int for consumables
            consumableName: itemName,
            quantityChange: quantity,
            reason: 'Delivery Note: $customerName - ${item['description']}',
            deliveryNoteId: deliveryNoteId,
            fromBranchId: fromBranchId,
            toBranchId: toBranchId,
            fromBranchName: fromBranchName, // Pass branch names
            toBranchName: toBranchName, // Pass branch names
          );
          debugPrint('Transaction added for consumable $itemName');
        }
      }

      fetchDeliveryNotes(); // Refresh the list
      Get.back(); // Close the form screen
      Get.snackbar('Success', 'Delivery note created successfully!');
    } catch (e) {
      debugPrint('Error creating delivery note: ${e.toString()}');
      Get.snackbar('Error', 'Failed to create delivery note: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateDeliveryNote({
    required String deliveryNoteId,
    String? customerName,
    String? destinationAddress,
    required DateTime deliveryDate,
    required String fromBranchId,
    required String toBranchId,
    required List<Map<String, dynamic>> newItems,
    required List<Map<String, dynamic>> originalItems,
    String? keterangan,
  }) async {
    try {
      isLoading.value = true;

      // --- Start a transaction
      // Note: Supabase Flutter doesn't have a direct transaction API like node.js
      // Instead, we'll perform the operations and handle rollbacks manually on error.

      // 1. Reverse and delete original product transactions
      final originalProductTransactions = await supabase
          .from('inventory_transactions')
          .select()
          .eq('delivery_note_id', deliveryNoteId);

      for (final transaction in originalProductTransactions) {
        await inventoryController.reverseTransaction(transaction['id']);
      }
      // await supabase
      //     .from('inventory_transactions')
      //     .delete()
      //     .eq('delivery_note_id', deliveryNoteId);

      // 2. Reverse and delete original consumable transactions
      final originalConsumableTransactions = await supabase
          .from('consumable_transactions')
          .select()
          .eq('delivery_note_id', deliveryNoteId);

      for (final transaction in originalConsumableTransactions) {
        await consumableController.reverseConsumableTransaction(
          transaction['id'],
        );
      }
      // await supabase
      //     .from('consumable_transactions')
      //     .delete()
      //     .eq('delivery_note_id', deliveryNoteId);

      debugPrint('Original transactions reversed and deleted.');

      // 3. Update the delivery note entry itself
      final fromBranchResponse =
          await supabase
              .from('branches')
              .select('name')
              .eq('id', fromBranchId)
              .single();
      final toBranchResponse =
          await supabase
              .from('branches')
              .select('name')
              .eq('id', toBranchId)
              .single();
      final String fromBranchName = fromBranchResponse['name'];
      final String toBranchName = toBranchResponse['name'];

      await supabase
          .from('delivery_notes')
          .update({
            'customer_name': customerName ?? 'Internal Transfer',
            'destination_address': destinationAddress ?? 'Internal Transfer',
            'delivery_date': deliveryDate.toUtc().toIso8601String(),
            'from_branch_id': fromBranchId,
            'to_branch_id': toBranchId,
            'from_branch_name': fromBranchName,
            'to_branch_name': toBranchName,
            'keterangan': keterangan,
          })
          .eq('id', deliveryNoteId);

      // 4. Create new transactions for the updated items
      for (var item in newItems) {
        final String itemType = item['type'];
        final dynamic itemId =
            item['id']; // Use dynamic to handle both int and String
        final String itemName = item['name'];
        final int quantity = item['quantity'].abs();

        if (itemType == 'product') {
          await inventoryController.addTransaction(
            productId: itemId as String, // Cast to String for products
            type: 'out',
            quantityChange: quantity,
            reason: 'Delivery Note: ${customerName ?? 'Internal Transfer'} - ${item['description']}',
            deliveryNoteId: deliveryNoteId,
            fromBranchId: fromBranchId,
            toBranchId: toBranchId,
            fromBranchName: fromBranchName,
            toBranchName: toBranchName,
          );
          debugPrint('New transaction added for product $itemName');
        } else if (itemType == 'consumable') {
          await consumableController.addConsumableTransactionFromDeliveryNote(
            consumableId: int.parse(itemId), // Cast to int for consumables
            consumableName: itemName,
            quantityChange: quantity,
            reason: 'Delivery Note: ${customerName ?? 'Internal Transfer'} - ${item['description']}',
            deliveryNoteId: deliveryNoteId,
            fromBranchId: fromBranchId,
            toBranchId: toBranchId,
            fromBranchName: fromBranchName,
            toBranchName: toBranchName,
          );
          debugPrint('New transaction added for consumable $itemName');
        }
      }

      // --- If all operations are successful, commit
      fetchDeliveryNotes();
      Get.back();
      Get.snackbar('Success', 'Delivery note updated successfully!');
    } catch (e) {
      // --- If any error occurs, we should ideally roll back the changes.
      // However, without a proper transaction block, a full rollback is complex.
      // The reversal logic at the start helps, but if an error happens *after*
      // reversal but *before* creating new items, the state is inconsistent.
      // For now, we'll just show an error. A more robust solution would
      // involve creating a stored procedure in Supabase for this entire update process.
      debugPrint('Error updating delivery note: ${e.toString()}');
      Get.snackbar('Error', 'Failed to update delivery note: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<int>?> exportToExcel({
    required DeliveryNote deliveryNote,
    required String toBranchName,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Delivery Note'];

      // Header
      sheet.merge(CellIndex.indexByString('A5'), CellIndex.indexByString('F5'));
      sheet.cell(CellIndex.indexByString('A5')).value =
          'Umayumcha Head Quarter Malang';
      sheet.cell(CellIndex.indexByString('A5')).cellStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Left,
        bold: true,
      );

      sheet.merge(CellIndex.indexByString('A6'), CellIndex.indexByString('F6'));
      sheet.cell(CellIndex.indexByString('A6')).value =
          'Jalan Dirgantara 4 no A5/11';
      sheet.cell(CellIndex.indexByString('A6')).cellStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Left,
      );

      sheet.merge(CellIndex.indexByString('A7'), CellIndex.indexByString('F7'));
      sheet.cell(CellIndex.indexByString('A7')).value = 'Sawojajar Malang';
      sheet.cell(CellIndex.indexByString('A7')).cellStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Left,
      );

      sheet.cell(CellIndex.indexByString('A9')).value = 'No. Surat Jalan:';
      sheet.cell(CellIndex.indexByString('B9')).value =
          deliveryNote.dnNumber ?? deliveryNote.id.toString();

      sheet.cell(CellIndex.indexByString('A10')).value = 'Penerima:';
      sheet.cell(CellIndex.indexByString('B10')).value = 'Cabang $toBranchName';

      sheet.cell(CellIndex.indexByString('A11')).value = 'Tanggal:';
      sheet.cell(CellIndex.indexByString('B11')).value = DateFormat(
        'dd-MM-yyyy',
      ).format(deliveryNote.deliveryDate);

      // Keterangan
      sheet.cell(CellIndex.indexByString('A12')).value = 'Catatan:';
      sheet.cell(CellIndex.indexByString('B12')).value =
          deliveryNote.keterangan ?? '';

      // Items Table Header
      sheet.cell(CellIndex.indexByString('A14')).value = 'Nama Barang';
      sheet.cell(CellIndex.indexByString('B14')).value = 'Quantity';
      sheet.cell(CellIndex.indexByString('C14')).value = 'Check';
      sheet.cell(CellIndex.indexByString('D14')).value = 'Keterangan';

      // Apply bold style to table headers
      final headerStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );
      sheet.cell(CellIndex.indexByString('A14')).cellStyle = headerStyle;
      sheet.cell(CellIndex.indexByString('B14')).cellStyle = headerStyle;
      sheet.cell(CellIndex.indexByString('C14')).cellStyle = headerStyle;
      sheet.cell(CellIndex.indexByString('D14')).cellStyle = headerStyle;

      // Items Table Data
      int rowIndex = 15;
      for (var item in items) {
        sheet.cell(CellIndex.indexByString('A$rowIndex')).value = item['name'];
        sheet.cell(CellIndex.indexByString('B$rowIndex')).value =
            item['quantity'].abs();
        sheet.cell(CellIndex.indexByString('C$rowIndex')).value =
            '✓'; // Auto checklist
        sheet.cell(CellIndex.indexByString('D$rowIndex')).value =
            item['reason'] ?? ''; // Reason column
        rowIndex++;
      }

      // Signatures
      rowIndex += 3; // Add some space
      sheet.cell(CellIndex.indexByString('A$rowIndex')).value = 'Pengirim';
      sheet.cell(CellIndex.indexByString('D$rowIndex')).value = 'Penerima';

      rowIndex += 4; // Space for signature
      sheet.cell(CellIndex.indexByString('A$rowIndex')).value =
          '(____________)';
      sheet.cell(CellIndex.indexByString('D$rowIndex')).value =
          '(____________)';

      return excel.save(); // Return bytes
    } catch (e) {
      debugPrint('Error generating Excel: ${e.toString()}');
      Get.snackbar('Error', 'Failed to generate Excel: ${e.toString()}');
      return null;
    }
  }

  Future<List<int>?> exportToPdf({
    required DeliveryNote deliveryNote,
    required String toBranchName,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final pdf_lib.Document pdf = pdf_lib.Document();

      // Load logo
      final ByteData logoBytes = await rootBundle.load(
        'assets/images/logo2.png',
      );
      final Uint8List logoUint8List = logoBytes.buffer.asUint8List();
      final pdf_lib.MemoryImage logoImage = pdf_lib.MemoryImage(logoUint8List);

      pdf.addPage(
        pdf_lib.Page(
          build: (pdf_lib.Context context) {
            return pdf_lib.Column(
              crossAxisAlignment: pdf_lib.CrossAxisAlignment.start,
              children: [
                pdf_lib.Image(logoImage, width: 150, height: 50),
                pdf_lib.SizedBox(height: 20),
                pdf_lib.Text(
                  'Umayumcha Head Quarter Malang',
                  style: pdf_lib.TextStyle(fontWeight: pdf_lib.FontWeight.bold),
                ),
                pdf_lib.Text('Jalan Dirgantara 4 no A5/11'),
                pdf_lib.Text('Sawojajar Malang'),
                pdf_lib.SizedBox(height: 20),
                pdf_lib.Text(
                  'No. Surat Jalan: ${deliveryNote.dnNumber ?? deliveryNote.id}',
                ),
                pdf_lib.Text('Penerima: Cabang $toBranchName'),
                pdf_lib.Text(
                  'Tanggal: ${DateFormat('dd-MM-yyyy').format(deliveryNote.deliveryDate)}',
                ),

                pdf_lib.SizedBox(height: 20),
                pdf_lib.TableHelper.fromTextArray(
                  // Changed to TableHelper
                  headers: ['Nama Barang', 'Quantity', 'Check', 'Keterangan'],
                  data:
                      items
                          .map(
                            (item) => [
                              item['name'],
                              item['quantity'].abs().toString(),
                              '', // Auto checklist
                              item['reason'] ?? '', // Reason
                            ],
                          )
                          .toList(),
                  border: pdf_lib.TableBorder.all(
                    color: pdf_colors.PdfColors.black,
                  ), // Corrected PdfColors
                  headerStyle: pdf_lib.TextStyle(
                    fontWeight: pdf_lib.FontWeight.bold,
                  ),
                  cellAlignment: pdf_lib.Alignment.centerLeft,
                  cellPadding: const pdf_lib.EdgeInsets.all(5),
                ),
                if (deliveryNote.keterangan != null &&
                    deliveryNote.keterangan!.isNotEmpty)
                  pdf_lib.Column(
                    crossAxisAlignment: pdf_lib.CrossAxisAlignment.start,
                    children: [
                      pdf_lib.SizedBox(height: 10),
                      pdf_lib.Text('Catatan:'),
                      pdf_lib.Text(deliveryNote.keterangan!),
                    ],
                  ),
                pdf_lib.SizedBox(height: 50),
                pdf_lib.Row(
                  mainAxisAlignment: pdf_lib.MainAxisAlignment.spaceAround,
                  children: [
                    pdf_lib.Column(
                      children: [
                        pdf_lib.Text('Pengirim'),
                        pdf_lib.SizedBox(height: 40),
                        pdf_lib.Text('(____________)'),
                      ],
                    ),
                    pdf_lib.Column(
                      children: [
                        pdf_lib.Text('Penerima'),
                        pdf_lib.SizedBox(height: 40),
                        pdf_lib.Text('(____________)'),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      return pdf.save(); // Return bytes
    } catch (e) {
      debugPrint('Error generating PDF: ${e.toString()}');
      Get.snackbar('Error', 'Failed to generate PDF: ${e.toString()}');
      return null;
    }
  }
}
