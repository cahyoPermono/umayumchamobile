import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio_lib;
import '../models/combined_delivery_note_model.dart';

import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

class CombinedReportExporter {
  static Future<void> exportToPdf(List<CombinedDeliveryNote> data) async {
    final pdf = pw.Document();

    // Load logo image
    final ByteData bytes = await rootBundle.load('assets/images/logoprint.png');
    final Uint8List logoBytes = bytes.buffer.asUint8List();
    final pw.MemoryImage logoImage = pw.MemoryImage(logoBytes);

    // Calculate totals
    final totalIn = data
        .where((d) => d.type == 'In')
        .fold<num>(0, (sum, item) => sum + item.quantity);
    final totalOut = data
        .where((d) => d.type == 'Out')
        .fold<num>(0, (sum, item) => sum + item.quantity.abs());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.portrait,
        footer:
            (context) => pw.Container(
              alignment: pw.Alignment.centerLeft,
              margin: const pw.EdgeInsets.only(top: 1.0 * PdfPageFormat.cm),
              child: pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.Theme.of(
                  context,
                ).defaultTextStyle.copyWith(color: PdfColors.grey),
              ),
            ),
        build:
            (context) => [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Image(logoImage, width: 80, height: 80),
                  pw.SizedBox(width: 20),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'REPORT DELIVERY NOTE(IN & OUT)',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      pw.Text('HEADQUARTER', style: pw.TextStyle(fontSize: 12)),
                      pw.Text('MALANG', style: pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headers: [
                  'Nama Barang',
                  'From (Vendor)',
                  'To (Cabang)',
                  'Delivery Date',
                  'Quantity',
                  'Keterangan',
                ],
                data:
                    data
                        .map(
                          (item) => [
                            item.itemName,
                            item.fromVendor ?? '',
                            item.toBranch ?? '',
                            DateFormat('dd-MMM-yyyy').format(item.date),
                            item.quantity.toString(),
                            item.keterangan ?? '',
                          ],
                        )
                        .toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'Total Quantity In: ',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(totalIn.toString()),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'Total Quantity Out: ',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(totalOut.toString()),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'Net Total (In - Out): ',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text((totalIn - totalOut).toString()),
                ],
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
    final xlsio_lib.Workbook workbook = xlsio_lib.Workbook();
    final xlsio_lib.Worksheet sheet = workbook.worksheets[0];

    // Add logo
    final ByteData bytes = await rootBundle.load('assets/images/logoprint.png');
    final Uint8List logoBytes = bytes.buffer.asUint8List();
    final xlsio.Picture picture = sheet.pictures.addStream(1, 1, logoBytes);

    // Set width and calculate height to maintain aspect ratio
    picture.width = 125;
    // picture.height = (150 / aspectRatio).round();
    picture.height = 75;

    // Add header texts
    sheet.getRangeByName('C1').setText('REPORT DELIVERY NOTE(IN & OUT)');
    sheet.getRangeByName('C1').cellStyle.fontSize = 16;
    sheet.getRangeByName('C1').cellStyle.bold = true;
    sheet.getRangeByName('C2').setText('HEADQUARTER');
    sheet.getRangeByName('C3').setText('MALANG');

    // Headers
    final headers = [
      'Nama Barang',
      'From (Vendor)',
      'To (Cabang)',
      'Delivery Date',
      'Quantity',
      'Keterangan',
    ];
    for (int i = 0; i < headers.length; i++) {
      sheet
          .getRangeByIndex(5, i + 1)
          .setText(headers[i]); // Start headers from row 5
    }

    // Data
    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      sheet.getRangeByIndex(i + 6, 1).setText(item.itemName);
      sheet.getRangeByIndex(i + 6, 2).setText(item.fromVendor ?? '');
      sheet.getRangeByIndex(i + 6, 3).setText(item.toBranch ?? '');
      sheet
          .getRangeByIndex(i + 6, 4)
          .setText(DateFormat('dd-MMM-yyyy').format(item.date));
      sheet.getRangeByIndex(i + 6, 5).setNumber(item.quantity.toDouble());
      sheet.getRangeByIndex(i + 6, 6).setText(item.keterangan ?? '');
    }

    // Totals
    final totalIn = data
        .where((d) => d.type == 'In')
        .fold<num>(0, (sum, item) => sum + item.quantity);
    final totalOut = data
        .where((d) => d.type == 'Out')
        .fold<num>(0, (sum, item) => sum + item.quantity.abs());
    final int lastRow = data.length + 8; // Adjust row for totals

    sheet.getRangeByIndex(lastRow, 4).setText('Total Quantity In:');
    sheet.getRangeByIndex(lastRow, 5).setNumber(totalIn.toDouble());

    sheet.getRangeByIndex(lastRow + 1, 4).setText('Total Quantity Out:');
    sheet.getRangeByIndex(lastRow + 1, 5).setNumber(totalOut.toDouble());

    sheet.getRangeByIndex(lastRow + 2, 4).setText('Net Total (In - Out):');
    sheet
        .getRangeByIndex(lastRow + 2, 5)
        .setNumber((totalIn - totalOut).toDouble());

    // Auto-fit columns
    sheet.autoFitColumn(1);
    sheet.autoFitColumn(2);
    sheet.autoFitColumn(3);
    sheet.autoFitColumn(4);
    sheet.autoFitColumn(5);
    sheet.autoFitColumn(6);

    // Save the file
    final List<int> excelBytes = workbook.saveAsStream();
    workbook.dispose();

    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    final file = File('$path/CombinedDeliveryReport.xlsx');
    await file.writeAsBytes(excelBytes, flush: true);
    OpenFilex.open(file.path);
  }
}
