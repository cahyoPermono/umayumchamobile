import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:umayumcha_ims/utils/file_exporter.dart'; // Import the new file_exporter

class ExcelReportExporter {
  static Future<void> generateAndOpenExcel({
    required List<Map<String, dynamic>> reportItems,
    required double totalOverallCost,
    required double totalOverallQuantity,
    required String userRole, // Added userRole parameter
  }) async {
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];

    // Load image
    final List<int> logoBytes =
        (await rootBundle.load(
          'assets/images/logoprint.png',
        )).buffer.asUint8List();

    // Add image and set row height
    final Picture picture = sheet.pictures.addStream(1, 1, logoBytes);

    // Set width and calculate height to maintain aspect ratio
    picture.width = 125;
    // picture.height = (150 / aspectRatio).round();
    picture.height = 75;

    // Header
    sheet.getRangeByName('C2').setText('REPORT DELIVERY NOTE (OUT)');
    sheet.getRangeByName('C2').cellStyle.bold = true;
    sheet.getRangeByName('C2').cellStyle.fontSize = 18;

    sheet.getRangeByName('C3').setText('HEADQUARTER');
    sheet.getRangeByName('C3').cellStyle.fontSize = 14;

    sheet.getRangeByName('C4').setText('MALANG');
    sheet.getRangeByName('C4').cellStyle.fontSize = 14;

    // Table Headers
    const int tableHeaderRow = 6;
    sheet.getRangeByName('A$tableHeaderRow').setText('Nama Barang');
    sheet.getRangeByName('B$tableHeaderRow').setText('To (Cabang)');
    sheet.getRangeByName('C$tableHeaderRow').setText('Delivery Date');
    sheet.getRangeByName('D$tableHeaderRow').setText('Quantity');
    sheet.getRangeByName('E$tableHeaderRow').setText('Keterangan');

    if (userRole != 'admin') {
      sheet.getRangeByName('F$tableHeaderRow').setText('Harga');
      sheet.getRangeByName('G$tableHeaderRow').setText('Total');
    }

    // Apply bold style to headers
    final String headerRange =
        userRole != 'admin'
            ? 'A$tableHeaderRow:G$tableHeaderRow'
            : 'A$tableHeaderRow:E$tableHeaderRow';
    sheet.getRangeByName(headerRange).cellStyle.bold = true;

    // Populate data
    int rowIndex = tableHeaderRow + 1;
    for (var item in reportItems) {
      sheet.getRangeByIndex(rowIndex, 1).setText(item['item_name']);
      sheet.getRangeByIndex(rowIndex, 2).setText(item['to_branch_name']);
      sheet
          .getRangeByIndex(rowIndex, 3)
          .setText(
            DateFormat('dd-MM-yyyy HH:mm').format(item['delivery_date']),
          );
      sheet.getRangeByIndex(rowIndex, 4).setNumber(item['quantity'].toDouble());
      sheet.getRangeByIndex(rowIndex, 5).setText(item['keterangan']);
      if (userRole != 'admin') {
        sheet
            .getRangeByIndex(rowIndex, 6)
            .setNumber(item['price_per_unit'].toDouble());
        sheet
            .getRangeByIndex(rowIndex, 7)
            .setNumber(item['total_price'].toDouble());
      }
      rowIndex++;
    }

    // Totals
    final int summaryRow = rowIndex + 2;
    if (userRole != 'admin') {
      sheet.getRangeByIndex(summaryRow, 6).setText('Total Keseluruhan:');
      sheet.getRangeByIndex(summaryRow, 7).setNumber(totalOverallCost);
      sheet
          .getRangeByIndex(summaryRow, 7)
          .setText(
            NumberFormat.currency(
              locale: 'id_ID',
              symbol: 'Rp ',
              decimalDigits: 0,
            ).format(totalOverallCost),
          );
    }

    // Always show total quantity
    final int quantitySummaryRow =
        userRole != 'admin' ? summaryRow + 1 : summaryRow;
    final int quantityLabelCol = userRole != 'admin' ? 6 : 3;
    final int quantityValueCol = userRole != 'admin' ? 7 : 4;

    sheet
        .getRangeByIndex(quantitySummaryRow, quantityLabelCol)
        .setText('Total Quantity:');
    sheet
        .getRangeByIndex(quantitySummaryRow, quantityValueCol)
        .setNumber(totalOverallQuantity);

    // Auto-fit columns for better readability
    for (int i = 1; i <= (userRole != 'admin' ? 7 : 5); i++) {
      sheet.autoFitColumn(i);
    }

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    await saveFile(
      fileBytes: bytes,
      fileName: 'Report Delivery Notes (Out).xlsx',
    );
  }

  static Future<void> generateAndOpenExcelIncoming({
    required List<Map<String, dynamic>> reportItems,
    required double totalOverallCost,
    required double totalOverallQuantity,
    required String userRole, // Added userRole parameter
  }) async {
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];

    // Load image
    final List<int> logoBytes =
        (await rootBundle.load(
          'assets/images/logoprint.png',
        )).buffer.asUint8List();

    // Add image and set row height
    final Picture picture = sheet.pictures.addStream(1, 1, logoBytes);

    // Set width and calculate height to maintain aspect ratio
    picture.width = 125;
    // picture.height = (150 / aspectRatio).round();
    picture.height = 75;

    // Header
    sheet.getRangeByName('C2').setText('REPORT DELIVERY NOTE (IN)');
    sheet.getRangeByName('C2').cellStyle.bold = true;
    sheet.getRangeByName('C2').cellStyle.fontSize = 18;

    sheet.getRangeByName('C3').setText('HEADQUARTER');
    sheet.getRangeByName('C3').cellStyle.fontSize = 14;

    sheet.getRangeByName('C4').setText('MALANG');
    sheet.getRangeByName('C4').cellStyle.fontSize = 14;

    // Table Headers
    const int tableHeaderRow = 6;
    sheet.getRangeByName('A$tableHeaderRow').setText('Nama Barang');
    sheet.getRangeByName('B$tableHeaderRow').setText('From (Vendor)');
    sheet.getRangeByName('C$tableHeaderRow').setText('Delivery Date');
    sheet.getRangeByName('D$tableHeaderRow').setText('Quantity');
    sheet.getRangeByName('E$tableHeaderRow').setText('Keterangan');

    if (userRole != 'admin') {
      sheet.getRangeByName('F$tableHeaderRow').setText('Harga');
      sheet.getRangeByName('G$tableHeaderRow').setText('Total');
    }

    // Apply bold style to headers
    final String headerRange =
        userRole != 'admin'
            ? 'A$tableHeaderRow:G$tableHeaderRow'
            : 'A$tableHeaderRow:E$tableHeaderRow';
    sheet.getRangeByName(headerRange).cellStyle.bold = true;

    // Populate data
    int rowIndex = tableHeaderRow + 1;
    for (var item in reportItems) {
      sheet.getRangeByIndex(rowIndex, 1).setText(item['item_name']);
      sheet.getRangeByIndex(rowIndex, 2).setText(item['from_branch_name']);
      sheet
          .getRangeByIndex(rowIndex, 3)
          .setText(
            DateFormat('dd-MM-yyyy HH:mm').format(item['delivery_date']),
          );
      sheet.getRangeByIndex(rowIndex, 4).setNumber(item['quantity'].toDouble());
      sheet.getRangeByIndex(rowIndex, 5).setText(item['keterangan']);
      if (userRole != 'admin') {
        sheet
            .getRangeByIndex(rowIndex, 6)
            .setNumber(item['price_per_unit'].toDouble());
        sheet
            .getRangeByIndex(rowIndex, 7)
            .setNumber(item['total_price'].toDouble());
      }
      rowIndex++;
    }

    // Totals
    final int summaryRow = rowIndex + 2;
    if (userRole != 'admin') {
      sheet.getRangeByIndex(summaryRow, 6).setText('Total Keseluruhan:');
      sheet.getRangeByIndex(summaryRow, 7).setNumber(totalOverallCost);
      sheet
          .getRangeByIndex(summaryRow, 7)
          .setText(
            NumberFormat.currency(
              locale: 'id_ID',
              symbol: 'Rp ',
              decimalDigits: 0,
            ).format(totalOverallCost),
          );
    }

    // Always show total quantity
    final int quantitySummaryRow =
        userRole != 'admin' ? summaryRow + 1 : summaryRow;
    final int quantityLabelCol = userRole != 'admin' ? 6 : 3;
    final int quantityValueCol = userRole != 'admin' ? 7 : 4;

    sheet
        .getRangeByIndex(quantitySummaryRow, quantityLabelCol)
        .setText('Total Quantity:');
    sheet
        .getRangeByIndex(quantitySummaryRow, quantityValueCol)
        .setNumber(totalOverallQuantity);

    // Auto-fit columns for better readability
    for (int i = 1; i <= (userRole != 'admin' ? 7 : 5); i++) {
      sheet.autoFitColumn(i);
    }

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    await saveFile(
      fileBytes: bytes,
      fileName: 'Report Delivery Notes (In).xlsx',
    );
  }
}
