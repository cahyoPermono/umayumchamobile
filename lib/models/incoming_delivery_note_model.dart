class IncomingDeliveryNote {
  final String id;
  final DateTime createdAt;
  final String? fromVendorName;
  final DateTime deliveryDate;
  final String toBranchId;
  final String toBranchName;
  final String? keterangan;
  final List<Map<String, dynamic>>? productItems;
  final List<Map<String, dynamic>>? consumableItems;

  IncomingDeliveryNote({
    required this.id,
    required this.createdAt,
    this.fromVendorName,
    required this.deliveryDate,
    required this.toBranchId,
    required this.toBranchName,
    this.keterangan,
    this.productItems,
    this.consumableItems,
  });

  factory IncomingDeliveryNote.fromJson(Map<String, dynamic> json) {
    return IncomingDeliveryNote(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      fromVendorName: json['from_vendor_name'] as String?,
      deliveryDate: DateTime.parse(json['delivery_date'] as String).toLocal(),
      toBranchId: json['to_branch_id'] as String,
      toBranchName: json['to_branch_name'] as String,
      keterangan: json['keterangan'] as String?,
      productItems:
          (json['inventory_transactions'] as List?)
              ?.map(
                (e) => {
                  'product_id': e['product_id'],
                  'quantity_change': e['quantity_change'],
                  'product_name': e['product_name'],
                  'reason': e['reason'],
                  'type': 'product',
                },
              )
              .toList(),
      consumableItems:
          (json['consumable_transactions'] as List?)
              ?.map(
                (e) => {
                  'consumable_id': e['consumable_id'],
                  'quantity_change': e['quantity_change'],
                  'consumable_name': e['consumable_name'],
                  'reason': e['reason'],
                  'type': 'consumable',
                },
              )
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from_vendor_name': fromVendorName,
      'delivery_date': deliveryDate.toIso8601String().split('T').first,
      'to_branch_id': toBranchId,
      'to_branch_name': toBranchName,
      'keterangan': keterangan,
    };
  }
}
