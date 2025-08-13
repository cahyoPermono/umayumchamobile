import 'package:flutter/foundation.dart'; // Added for debugPrint
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:umayumcha_ims/utils/file_exporter.dart'; // Import the new file_exporter

class PdfReportExporter {
  static Future<void> generateAndOpenPdf({
    required List<Map<String, dynamic>> reportItems,
    required double totalOverallCost,
    required double totalOverallQuantity,
  }) async {
    final pdf = pw.Document();

    final ByteData bytes = await rootBundle.load('assets/images/logoprint.png');
    final Uint8List logoBytes = bytes.buffer.asUint8List();

    debugPrint('PDF Export: reportItems length: ${reportItems.length}');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  pw.Image(pw.MemoryImage(logoBytes), width: 200, height: 150),
                  pw.SizedBox(width: 20),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'REPORT DELIVERY NOTE (OUT)',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text('HEADQUARTER', style: pw.TextStyle(fontSize: 18)),
                      pw.Text('MALANG', style: pw.TextStyle(fontSize: 18)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),
              pw.TableHelper.fromTextArray(
                headers: [
                  'Nama Barang',
                  'To (Cabang)',
                  'Delivery Date',
                  'Quantity',
                  'Keterangan',
                  'Harga',
                  'Total',
                ],
                data:
                    reportItems.map((item) {
                      return [
                        item['item_name'],
                        item['to_branch_name'],
                        DateFormat(
                          'dd-MM-yyyy HH:mm',
                        ).format(item['delivery_date']),
                        item['quantity'].toString(),
                        item['keterangan'],
                        NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(item['price_per_unit']),
                        NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(item['total_price']),
                      ];
                    }).toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Align(
                alignment: pw.Alignment.bottomRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Total Keseluruhan: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(totalOverallCost)}',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    pw.Text(
                      'Total Quantity: ${totalOverallQuantity.toInt()}',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();
    await saveFile(fileBytes: pdfBytes, fileName: 'delivery_note_report.pdf');
  }
}
