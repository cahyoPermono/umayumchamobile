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
  double totalPrice = 0.0; // ADDED for calculated total price

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
    this.totalPrice = 0.0, // Initialize totalPrice in constructor
  });

  factory IncomingDeliveryNote.fromJson(Map<String, dynamic> json) {
    double calculatedTotalPrice = 0.0;

    final List<Map<String, dynamic>>? productItems = (json['inventory_transactions'] as List?)
        ?.map(
          (e) => {
            'product_id': e['product_id'],
            'quantity_change': e['quantity_change'],
            'product_name': e['product_name'],
            'reason': e['reason'],
            'type': 'product',
            'price': (e['product']?['price'] as num?)?.toDouble(), // Get price from nested product
          },
        )
        .toList();

    if (productItems != null) {
      for (var item in productItems) {
        final double price = item['price'] ?? 0.0;
        final int quantity = (item['quantity_change'] as int).abs();
        calculatedTotalPrice += price * quantity;
      }
    }

    final List<Map<String, dynamic>>? consumableItems = (json['consumable_transactions'] as List?)
        ?.map(
          (e) => {
            'consumable_id': e['consumable_id'],
            'quantity_change': e['quantity_change'],
            'consumable_name': e['consumable_name'],
            'reason': e['reason'],
            'type': 'consumable',
            'price': (e['consumable']?['price'] as num?)?.toDouble(), // Get price from nested consumable
          },
        )
        .toList();

    if (consumableItems != null) {
      for (var item in consumableItems) {
        final double price = item['price'] ?? 0.0;
        final int quantity = (item['quantity_change'] as int).abs();
        calculatedTotalPrice += price * quantity;
      }
    }

    return IncomingDeliveryNote(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      fromVendorName: json['from_vendor_name'] as String?,
      deliveryDate: DateTime.parse(json['delivery_date'] as String).toLocal(),
      toBranchId: json['to_branch_id'] as String,
      toBranchName: json['to_branch_name'] as String,
      keterangan: json['keterangan'] as String?,
      productItems: productItems,
      consumableItems: consumableItems,
      totalPrice: calculatedTotalPrice, // Assign calculated total price
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
