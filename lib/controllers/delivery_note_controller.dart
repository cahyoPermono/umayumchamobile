import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:flutter/services.dart'; // For rootBundle
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:umayumcha_ims/controllers/consumable_controller.dart';
import 'package:umayumcha_ims/controllers/inventory_controller.dart';
import 'package:umayumcha_ims/models/delivery_note_model.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:pdf/pdf.dart' as pdf_colors; // New alias for PdfColors
import 'package:pdf/widgets.dart' as pdf_lib; // Changed alias to pdf_lib

import 'package:intl/intl.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart'
    as blue_printer; // Alias to avoid conflict
import 'package:image/image.dart' as img;

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
        final String reason = item['description'] ?? ''; // Get description

        if (itemType == 'product') {
          await inventoryController.addTransaction(
            productId: itemId as String, // Cast to String for products
            type: 'out',
            quantityChange: quantity,
            reason: reason, // Pass the description as the reason
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
            reason: reason, // Pass the description as the reason
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
      //     .delete()
      //     .eq('consumable_transactions')
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
        final String reason = item['description'] ?? ''; // Get description

        if (itemType == 'product') {
          await inventoryController.addTransaction(
            productId: itemId as String, // Cast to String for products
            type: 'out',
            quantityChange: quantity,
            reason: reason, // Pass the description as the reason
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
            reason: reason, // Pass the description as the reason
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
      // Create a new Excel document
      final xlsio.Workbook workbook = xlsio.Workbook();
      // Accessing worksheet via index
      final xlsio.Worksheet sheet = workbook.worksheets[0];
      sheet.name = 'Delivery Note';

      // Load logo
      final ByteData logoBytes = await rootBundle.load(
        'assets/images/logoprint.png',
      );
      final Uint8List logoUint8List = logoBytes.buffer.asUint8List();
      final img.Image? logoImage = img.decodeImage(logoUint8List);

      if (logoImage == null) {
        Get.snackbar('Error', 'Failed to decode logo for Excel export.');
        return null;
      }

      // Add the image to the worksheet
      final xlsio.Picture picture = sheet.pictures.addStream(
        1, // Row 1
        1, // Column 1 (A1)
        logoUint8List,
      );

      // Set width and calculate height to maintain aspect ratio
      picture.width = 200;
      // picture.height = (150 / aspectRatio).round();
      picture.height = 150;

      // Header - Address to the right of the logo
      sheet.getRangeByName('C2').setText('HEADQUARTER');
      sheet.getRangeByName('C2').cellStyle.hAlign = xlsio.HAlignType.left;
      sheet.getRangeByName('C2').cellStyle.bold = true;

      sheet.getRangeByName('C3').setText('MALANG');
      sheet.getRangeByName('C3').cellStyle.hAlign = xlsio.HAlignType.left;

      sheet.getRangeByName('A9').setText('No. Surat Jalan:');
      sheet
          .getRangeByName('B9')
          .setText(deliveryNote.dnNumber ?? deliveryNote.id.toString());

      sheet.getRangeByName('A10').setText('Penerima:');
      sheet.getRangeByName('B10').setText('Umayumcha $toBranchName');

      sheet.getRangeByName('A11').setText('Tanggal:');
      sheet
          .getRangeByName('B11')
          .setText(DateFormat('dd-MM-yyyy').format(deliveryNote.deliveryDate));

      // Keterangan
      sheet.getRangeByName('A12').setText('Catatan:');
      sheet.getRangeByName('B12').setText(deliveryNote.keterangan ?? '');

      // Items Table Header
      sheet.getRangeByName('A14').setText('Nama Barang');
      sheet.getRangeByName('B14').setText('Quantity');
      sheet.getRangeByName('C14').setText('Check');
      sheet.getRangeByName('D14').setText('Keterangan');

      // Apply bold style to table headers
      final xlsio.Style headerStyle = workbook.styles.add('headerStyle');
      headerStyle.bold = true;
      headerStyle.hAlign = xlsio.HAlignType.center;
      headerStyle.vAlign = xlsio.VAlignType.center;

      sheet.getRangeByName('A14').cellStyle = headerStyle;
      sheet.getRangeByName('B14').cellStyle = headerStyle;
      sheet.getRangeByName('C14').cellStyle = headerStyle;
      sheet.getRangeByName('D14').cellStyle = headerStyle;

      // Items Table Data
      int rowIndex = 15;
      for (var item in items) {
        sheet.getRangeByName('A$rowIndex').setText(item['name']);
        sheet
            .getRangeByName('B$rowIndex')
            .setNumber(item['quantity'].abs().toDouble());
        sheet.getRangeByName('C$rowIndex').setText('✓'); // Auto checklist
        sheet
            .getRangeByName('D$rowIndex')
            .setText(item['reason'] ?? ''); // Reason column
        rowIndex++;
      }

      // Signatures
      rowIndex += 3; // Add some space
      sheet.getRangeByName('A$rowIndex').setText('Pengirim');
      sheet.getRangeByName('C$rowIndex').setText('Mengetahui');
      sheet.getRangeByName('E$rowIndex').setText('Penerima');

      rowIndex += 4; // Space for signature
      sheet.getRangeByName('A$rowIndex').setText('(____________)');
      sheet.getRangeByName('C$rowIndex').setText('(____________)');
      sheet.getRangeByName('E$rowIndex').setText('(____________)');

      // Auto-fit columns for better visibility
      sheet.autoFitColumn(1);
      sheet.autoFitColumn(2);
      sheet.autoFitColumn(3);
      sheet.autoFitColumn(4);

      // Save the document
      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      return bytes; // Return bytes
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
        'assets/images/logoprint.png',
      );
      final Uint8List logoUint8List = logoBytes.buffer.asUint8List();
      final pdf_lib.MemoryImage logoImage = pdf_lib.MemoryImage(logoUint8List);

      pdf.addPage(
        pdf_lib.Page(
          build: (pdf_lib.Context context) {
            return pdf_lib.Column(
              crossAxisAlignment: pdf_lib.CrossAxisAlignment.start,
              children: [
                pdf_lib.Row(
                  mainAxisAlignment: pdf_lib.MainAxisAlignment.start,
                  children: [
                    pdf_lib.Image(logoImage, width: 150, height: 50),
                    pdf_lib.SizedBox(width: 20),
                    pdf_lib.Column(
                      crossAxisAlignment: pdf_lib.CrossAxisAlignment.start,
                      children: [
                        pdf_lib.Text(
                          'HEADQUARTER',
                          style: pdf_lib.TextStyle(
                            fontWeight: pdf_lib.FontWeight.bold,
                          ),
                        ),
                        pdf_lib.Text('MALANG'),
                      ],
                    ),
                  ],
                ),
                pdf_lib.SizedBox(height: 20),
                pdf_lib.Table(
                  columnWidths: {
                    // 0: const pdf_lib.IntrinsicColumnWidth(),
                    0: const pdf_lib.FixedColumnWidth(32),
                    1: const pdf_lib.FixedColumnWidth(2),
                  },
                  children: [
                    pdf_lib.TableRow(
                      children: [
                        pdf_lib.Text('No. Surat Jalan'),
                        pdf_lib.Text(':'),
                        pdf_lib.Text(
                          ' ${deliveryNote.dnNumber ?? deliveryNote.id}',
                        ),
                      ],
                    ),
                    pdf_lib.TableRow(
                      children: [
                        pdf_lib.Text('Penerima'),
                        pdf_lib.Text(':'),
                        pdf_lib.Text(' Umayumcha $toBranchName'),
                      ],
                    ),
                    pdf_lib.TableRow(
                      children: [
                        pdf_lib.Text('Tanggal'),
                        pdf_lib.Text(':'),
                        pdf_lib.Text(
                          ' ${DateFormat('dd-MM-yyyy').format(deliveryNote.deliveryDate)}',
                        ),
                      ],
                    ),
                  ],
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
                        pdf_lib.Text('Mengetahui'),
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

  // Helper function to wrap text for thermal printer
  List<String> _wrapText(String text, int maxCharsPerLine) {
    List<String> lines = [];
    String currentLine = '';
    List<String> words = text.split(' ');

    for (String word in words) {
      if ((currentLine + word).length <= maxCharsPerLine) {
        currentLine += (currentLine.isEmpty ? '' : ' ') + word;
      } else {
        lines.add(currentLine);
        currentLine = word;
      }
    }
    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }
    return lines;
  }

  Future<void> printDeliveryNote({
    required DeliveryNote deliveryNote,
    required String toBranchName,
    required List<Map<String, dynamic>> items,
    required blue_printer.BluetoothDevice selectedDevice,
  }) async {
    try {
      isLoading.value = true;

      // 1. Request Bluetooth permissions (already handled in UI)
      var bluetoothStatus = await Permission.bluetooth.status;
      var bluetoothConnectStatus = await Permission.bluetoothConnect.status;
      var bluetoothScanStatus = await Permission.bluetoothScan.status;

      if (!bluetoothStatus.isGranted ||
          !bluetoothConnectStatus.isGranted ||
          !bluetoothScanStatus.isGranted) {
        Map<Permission, PermissionStatus> statuses =
            await [
              Permission.bluetooth,
              Permission.bluetoothConnect,
              Permission.bluetoothScan,
            ].request();

        if (statuses[Permission.bluetooth] != PermissionStatus.granted ||
            statuses[Permission.bluetoothConnect] != PermissionStatus.granted ||
            statuses[Permission.bluetoothScan] != PermissionStatus.granted) {
          Get.snackbar('Error', 'Bluetooth permissions not granted.');
          return;
        }
      }

      blue_printer.BlueThermalPrinter bluetooth =
          blue_printer.BlueThermalPrinter.instance;

      // 2. Connect to the selected device
      bool? isConnected = await bluetooth.isConnected;
      if (isConnected == true) {
        await bluetooth.disconnect();
      }

      await bluetooth.connect(selectedDevice);
      isConnected = await bluetooth.isConnected;

      if (isConnected == false) {
        Get.snackbar('Error', 'Failed to connect to printer.');
        return;
      }

      // 3. Format and print data
      final ByteData logoBytes = await rootBundle.load(
        'assets/images/logoprintblack.png', // Corrected path
      );
      final Uint8List logoUint8List = logoBytes.buffer.asUint8List();

      // --- Resize the image ---
      final img.Image? originalImage = img.decodeImage(logoUint8List);
      if (originalImage == null) {
        Get.snackbar('Error', 'Failed to decode logo image.');
        return;
      }
      final img.Image resizedImage = img.copyResize(
        originalImage,
        width: 360, // A reasonable width for a 58mm thermal printer
      );
      final Uint8List resizedLogoBytes = Uint8List.fromList(
        img.encodePng(resizedImage),
      );
      // --- End of resize ---

      await bluetooth.printImageBytes(
        resizedLogoBytes,
      ); // Print the resized image

      // Add a small delay to allow the printer to process the image
      await Future.delayed(const Duration(milliseconds: 500));

      bluetooth.printNewLine();
      bluetooth.printCustom('HEADQUARTER', 1, 1);
      bluetooth.printCustom('MALANG', 0, 1);
      bluetooth.printNewLine();

      bluetooth.printLeftRight(
        'No. Surat Jalan:',
        deliveryNote.dnNumber ?? deliveryNote.id,
        0,
      );
      bluetooth.printLeftRight('Penerima:', 'Cabang $toBranchName', 0);
      bluetooth.printLeftRight(
        'Tanggal:',
        DateFormat('dd-MM-yyyy HH:mm').format(deliveryNote.deliveryDate),
        0,
      );
      bluetooth.printNewLine();

      if (deliveryNote.keterangan != null &&
          deliveryNote.keterangan!.isNotEmpty) {
        bluetooth.printCustom('Catatan:', 0, 0);
        List<String> wrappedKeterangan = _wrapText(
          deliveryNote.keterangan!,
          32,
        ); // 32 chars per line for 54mm printer
        for (String line in wrappedKeterangan) {
          bluetooth.printCustom(line, 0, 0);
        }
        bluetooth.printNewLine(); // Add newline after notes
      }

      bluetooth.printCustom('--------------------------------', 0, 1);
      bluetooth.printCustom('Nama Barang  Qty  Keterangan', 0, 0);
      bluetooth.printCustom('--------------------------------', 0, 1);

      for (var item in items) {
        String itemName = item['name'];
        int quantity = item['quantity'].abs();
        String description = item['description'] ?? '';

        bluetooth.printCustom(' $itemName  $quantity  $description', 0, 0);
        // bluetooth.printLeftRight(itemName, 'x$quantity', 0);
        // if (description.isNotEmpty) {
        //   bluetooth.printCustom('  Keterangan: $description', 0, 0);
        // }
      }
      bluetooth.printCustom('--------------------------------', 0, 1);
      bluetooth.printNewLine();

      bluetooth.printCustom('Pengirim', 0, 1);
      bluetooth.printNewLine();
      bluetooth.printNewLine();
      bluetooth.printCustom('(____________)', 0, 1);
      bluetooth.printNewLine();
      bluetooth.printCustom('Mengetahui', 0, 1);
      bluetooth.printNewLine();
      bluetooth.printNewLine();
      bluetooth.printCustom('(____________)', 0, 1);
      bluetooth.printNewLine();
      bluetooth.printCustom('Penerima', 0, 1);
      bluetooth.printNewLine();
      bluetooth.printNewLine();
      bluetooth.printCustom('(____________)', 0, 1);
      bluetooth.printNewLine();
      bluetooth.printNewLine();
      bluetooth.printNewLine();

      await bluetooth.disconnect();
      Get.snackbar('Success', 'Delivery note sent to printer!');
    } catch (e) {
      debugPrint('Error printing delivery note: ${e.toString()}');
      Get.snackbar('Error', 'Failed to print delivery note: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
}
