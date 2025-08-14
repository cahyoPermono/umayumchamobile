import 'dart:io';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import '../models/combined_delivery_note_model.dart';

class CombinedReportExporter {
  static Future<void> exportToPdf(List<CombinedDeliveryNote> data) async {
    final pdf = pw.Document();

    // Calculate totals
    final totalIn = data.where((d) => d.type == 'In').fold<num>(0, (sum, item) => sum + item.quantity);
    final totalOut = data.where((d) => d.type == 'Out').fold<num>(0, (sum, item) => sum + item.quantity.abs());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('Combined Delivery Note Report')),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headers: ['Nama Barang', 'From (Vendor)', 'To (Cabang)', 'Delivery Date', 'Quantity', 'Keterangan'],
            data: data.map((item) => [
              item.itemName,
              item.fromVendor ?? '',
              item.toBranch ?? '',
              DateFormat('dd-MMM-yyyy').format(item.date),
              item.quantity.toString(),
              item.keterangan ?? '',
            ]).toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text('Total Quantity In: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(totalIn.toString()),
            ]
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text('Total Quantity Out: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(totalOut.toString()),
            ]
          ),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/combined_report.pdf');
    await file.writeAsBytes(await pdf.save());
    OpenFilex.open(file.path);
  }

  static Future<void> exportToExcel(List<CombinedDeliveryNote> data) async {
    final xlsio.Workbook workbook = xlsio.Workbook();
    final xlsio.Worksheet sheet = workbook.worksheets[0];

    // Headers
    final headers = ['Nama Barang', 'From (Vendor)', 'To (Cabang)', 'Delivery Date', 'Quantity', 'Keterangan'];
    for (int i = 0; i < headers.length; i++) {
      sheet.getRangeByIndex(1, i + 1).setText(headers[i]);
    }

    // Data
    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      sheet.getRangeByIndex(i + 2, 1).setText(item.itemName);
      sheet.getRangeByIndex(i + 2, 2).setText(item.fromVendor ?? '');
      sheet.getRangeByIndex(i + 2, 3).setText(item.toBranch ?? '');
      sheet.getRangeByIndex(i + 2, 4).setText(DateFormat('dd-MMM-yyyy').format(item.date));
      sheet.getRangeByIndex(i + 2, 5).setNumber(item.quantity.toDouble());
      sheet.getRangeByIndex(i + 2, 6).setText(item.keterangan ?? '');
    }

    // Totals
    final totalIn = data.where((d) => d.type == 'In').fold<num>(0, (sum, item) => sum + item.quantity);
    final totalOut = data.where((d) => d.type == 'Out').fold<num>(0, (sum, item) => sum + item.quantity.abs());
    final int lastRow = data.length + 4;

    sheet.getRangeByIndex(lastRow, 4).setText('Total Quantity In:');
    sheet.getRangeByIndex(lastRow, 5).setNumber(totalIn.toDouble());

    sheet.getRangeByIndex(lastRow + 1, 4).setText('Total Quantity Out:');
    sheet.getRangeByIndex(lastRow + 1, 5).setNumber(totalOut.toDouble());

    // Save the file
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    final file = File('$path/CombinedDeliveryReport.xlsx');
    await file.writeAsBytes(bytes, flush: true);
    OpenFilex.open(file.path);
  }
}