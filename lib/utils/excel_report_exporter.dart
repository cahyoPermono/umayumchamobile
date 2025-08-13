import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:umayumcha_ims/utils/file_exporter.dart'; // Import the new file_exporter

class ExcelReportExporter {
  static Future<void> generateAndOpenExcel({
    required List<Map<String, dynamic>> reportItems,
    required double totalOverallCost,
    required double totalOverallQuantity,
  }) async {
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];

    // Header
    sheet.getRangeByName('A1').setText('REPORT DELIVERY NOTE (OUT)');
    sheet.getRangeByName('A1').cellStyle.bold = true;
    sheet.getRangeByName('A1').cellStyle.fontSize = 18;

    sheet.getRangeByName('A2').setText('HEADQUARTER');
    sheet.getRangeByName('A2').cellStyle.fontSize = 14;

    sheet.getRangeByName('A3').setText('MALANG');
    sheet.getRangeByName('A3').cellStyle.fontSize = 14;

    // Table Headers
    sheet.getRangeByName('A5').setText('Nama Barang');
    sheet.getRangeByName('B5').setText('To (Cabang)');
    sheet.getRangeByName('C5').setText('Delivery Date');
    sheet.getRangeByName('D5').setText('Quantity');
    sheet.getRangeByName('E5').setText('Keterangan');
    sheet.getRangeByName('F5').setText('Harga');
    sheet.getRangeByName('G5').setText('Total');

    // Apply bold style to headers
    sheet.getRangeByName('A5:G5').cellStyle.bold = true;

    // Populate data
    int rowIndex = 6;
    for (var item in reportItems) {
      sheet.getRangeByIndex(rowIndex, 1).setText(item['item_name']);
      sheet.getRangeByIndex(rowIndex, 2).setText(item['to_branch_name']);
      sheet.getRangeByIndex(rowIndex, 3).setText(DateFormat('dd-MM-yyyy HH:mm').format(item['delivery_date']));
      sheet.getRangeByIndex(rowIndex, 4).setNumber(item['quantity'].toDouble());
      sheet.getRangeByIndex(rowIndex, 5).setText(item['keterangan']);
      sheet.getRangeByIndex(rowIndex, 6).setNumber(item['price_per_unit'].toDouble());
      sheet.getRangeByIndex(rowIndex, 7).setNumber(item['total_price'].toDouble());
      rowIndex++;
    }

    // Totals
    sheet.getRangeByIndex(rowIndex + 2, 6).setText('Total Keseluruhan:');
    sheet.getRangeByIndex(rowIndex + 2, 7).setNumber(totalOverallCost);
    sheet.getRangeByIndex(rowIndex + 2, 7).setText(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(totalOverallCost));

    sheet.getRangeByIndex(rowIndex + 3, 6).setText('Total Quantity:');
    sheet.getRangeByIndex(rowIndex + 3, 7).setNumber(totalOverallQuantity);

    // Auto-fit columns for better readability
    sheet.autoFitColumn(1);
    sheet.autoFitColumn(2);
    sheet.autoFitColumn(3);
    sheet.autoFitColumn(4);
    sheet.autoFitColumn(5);
    sheet.autoFitColumn(6);
    sheet.autoFitColumn(7);

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    await saveFile(fileBytes: bytes, fileName: 'delivery_note_report.xlsx');
  }
}
