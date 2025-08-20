import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:umayumcha_ims/models/delivery_note_model.dart';

class ReceiptWidget extends StatelessWidget {
  final DeliveryNote deliveryNote;
  final String toBranchName;
  final List<Map<String, dynamic>> items;

  const ReceiptWidget({
    super.key,
    required this.deliveryNote,
    required this.toBranchName,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    const double receiptWidth = 320; // 58mm paper width in pixels (approx)

    return Material(
      child: Container(
        width: receiptWidth,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Center(
                child: Image.asset('assets/images/logoprintthermal.png', width: 150, height: 60),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Umayumcha',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
              ),
              const Center(
                child: Text(
                  'HEADQUARTER',
                  style: TextStyle(fontSize: 14, color: Colors.black),
                ),
              ),
              const Center(
                child: Text(
                  'MALANG',
                  style: TextStyle(fontSize: 14, color: Colors.black),
                ),
              ),
              const SizedBox(height: 16),

              // Info
              Text(
                'No: ${deliveryNote.dnNumber ?? deliveryNote.id}',
                style: const TextStyle(fontSize: 12, color: Colors.black),
              ),
              Text(
                'Tgl: ${DateFormat('dd-MM-yyyy HH:mm').format(deliveryNote.deliveryDate)}',
                style: const TextStyle(fontSize: 12, color: Colors.black),
              ),
              Text(
                'Penerima: Cabang $toBranchName',
                style: const TextStyle(fontSize: 12, color: Colors.black),
              ),
              const SizedBox(height: 8),
              if (deliveryNote.keterangan != null &&
                  deliveryNote.keterangan!.isNotEmpty)
                Text(
                  'Catatan: ${deliveryNote.keterangan!}',
                  style: const TextStyle(fontSize: 12, color: Colors.black),
                ),
              const Divider(color: Colors.black, thickness: 1),

              // Items Table
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(2.5),
                  1: FlexColumnWidth(0.8),
                  2: FlexColumnWidth(2),
                },
                border: TableBorder.all(width: 0.5, color: Colors.white), // Hidden border
                children: [
                  // Table Header
                  const TableRow(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Text('Barang', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Text('Keterangan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
                      ),
                    ],
                  ),
                  // Divider Row
                  TableRow(
                    children: [
                      Container(height: 1, color: Colors.black),
                      Container(height: 1, color: Colors.black),
                      Container(height: 1, color: Colors.black),
                    ],
                  ),
                  // Table Body
                  ...items.map((item) {
                    return TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(item['name'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.black)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text((item['quantity']?.abs() ?? 0).toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.black)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(item['description'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.black)),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),

              const Divider(color: Colors.black, thickness: 1),
              const SizedBox(height: 24),

              // Footer
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text('Pengirim', style: TextStyle(fontSize: 12, color: Colors.black)),
                      SizedBox(height: 40),
                      Text('(____________)', style: TextStyle(fontSize: 12, color: Colors.black)),
                    ],
                  ),
                   Column(
                    children: [
                      Text('Mengetahui', style: TextStyle(fontSize: 12, color: Colors.black)),
                      SizedBox(height: 40),
                      Text('(____________)', style: TextStyle(fontSize: 12, color: Colors.black)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('Penerima', style: TextStyle(fontSize: 12, color: Colors.black)),
                      SizedBox(height: 40),
                      Text('(____________)', style: TextStyle(fontSize: 12, color: Colors.black)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}