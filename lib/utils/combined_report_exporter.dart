
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../models/combined_delivery_note_model.dart';
import 'package:intl/intl.dart';

class CombinedReportExporter {
  static Future<void> exportToPdf(List<CombinedDeliveryNote> data) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('Combined Delivery Note Report')),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Item Name', 'Quantity', 'From Vendor', 'To Branch', 'Type'],
            data: data
                .map((item) => [
                      DateFormat('yyyy-MM-dd').format(item.date),
                      item.itemName,
                      item.quantity.toString(),
                      item.fromVendor ?? '',
                      item.toBranch ?? '',
                      item.type,
                    ])
                .toList(),
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
    // Implement Excel export logic here
    // For simplicity, we are not implementing this part now.
    // You can use a package like 'excel' to generate the excel file.
  }
}
