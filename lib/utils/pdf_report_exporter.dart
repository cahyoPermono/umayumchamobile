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
    required String userRole, // Added userRole parameter
  }) async {
    final pdf = pw.Document();

    final ByteData bytes = await rootBundle.load('assets/images/logoprint.png');
    final Uint8List logoBytes = bytes.buffer.asUint8List();

    debugPrint('PDF Export: reportItems length: ${reportItems.length}');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.portrait,
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  pw.Image(pw.MemoryImage(logoBytes), width: 100, height: 50),
                  pw.SizedBox(width: 20),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        userRole == 'finance'
                            ? 'REPORT FINANCE DELIVERY NOTE (OUT)'
                            : 'REPORT DELIVERY NOTE (OUT)',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text('HEADQUARTER', style: pw.TextStyle(fontSize: 14)),
                      pw.Text('MALANG', style: pw.TextStyle(fontSize: 14)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
            ],
          );
        },
        build:
            (pw.Context context) => [
              pw.TableHelper.fromTextArray(
                headers:
                    userRole == 'admin'
                        ? [
                          'Nama Barang',
                          'To (Cabang)',
                          'Delivery Date',
                          'Quantity',
                          'Keterangan',
                        ]
                        : [
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
                      final List<String> rowData = [
                        item['item_name'],
                        item['to_branch_name'],
                        DateFormat(
                          'dd-MM-yyyy HH:mm',
                        ).format(item['delivery_date']),
                        item['quantity'].toString(),
                        item['keterangan'],
                      ];
                      if (userRole != 'admin') {
                        rowData.add(
                          NumberFormat.currency(
                            locale: 'id_ID',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(item['price_per_unit']),
                        );
                        rowData.add(
                          NumberFormat.currency(
                            locale: 'id_ID',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(item['total_price']),
                        );
                      }
                      return rowData;
                    }).toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Align(
                alignment: pw.Alignment.bottomRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    if (userRole != 'admin')
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
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerLeft,
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 12),
            ),
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();
    await saveFile(
      fileBytes: pdfBytes,
      fileName: 'Report Finance Delivery Notes (Out).pdf',
    );
  }

  static Future<void> generateAndOpenPdfIncoming({
    required List<Map<String, dynamic>> reportItems,
    required double totalOverallCost,
    required double totalOverallQuantity,
    required String userRole, // Added userRole parameter
  }) async {
    final pdf = pw.Document();

    final ByteData bytes = await rootBundle.load('assets/images/logoprint.png');
    final Uint8List logoBytes = bytes.buffer.asUint8List();

    debugPrint('PDF Export: reportItems length: ${reportItems.length}');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.portrait,
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  pw.Image(pw.MemoryImage(logoBytes), width: 100, height: 50),
                  pw.SizedBox(width: 20),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'REPORT DELIVERY NOTE (IN)',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text('HEADQUARTER', style: pw.TextStyle(fontSize: 14)),
                      pw.Text('MALANG', style: pw.TextStyle(fontSize: 14)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
            ],
          );
        },
        build:
            (pw.Context context) => [
              pw.TableHelper.fromTextArray(
                headers:
                    userRole == 'admin'
                        ? [
                          'Nama Barang',
                          'From (Vendor)',
                          'Delivery Date',
                          'Quantity',
                          'Keterangan',
                        ]
                        : [
                          'Nama Barang',
                          'From (Vendor)',
                          'Delivery Date',
                          'Quantity',
                          'Keterangan',
                          'Harga',
                          'Total',
                        ],
                data:
                    reportItems.map((item) {
                      final List<String> rowData = [
                        item['item_name'],
                        item['from_branch_name'],
                        DateFormat(
                          'dd-MM-yyyy HH:mm',
                        ).format(item['delivery_date']),
                        item['quantity'].toString(),
                        item['keterangan'],
                      ];
                      if (userRole != 'admin') {
                        rowData.add(
                          NumberFormat.currency(
                            locale: 'id_ID',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(item['price_per_unit']),
                        );
                        rowData.add(
                          NumberFormat.currency(
                            locale: 'id_ID',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(item['total_price']),
                        );
                      }
                      return rowData;
                    }).toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Align(
                alignment: pw.Alignment.bottomRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    if (userRole != 'admin')
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
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerLeft,
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 12),
            ),
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();
    await saveFile(
      fileBytes: pdfBytes,
      fileName: 'Report Finance Delivery Notes (In).pdf',
    );
  }
}
