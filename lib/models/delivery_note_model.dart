class DeliveryNote {
  final String id;
  final DateTime createdAt;
  final String customerName;
  final String? destinationAddress;
  final DateTime deliveryDate;
  final String? userId;
  final List<Map<String, dynamic>>? items; // For displaying items in the note

  DeliveryNote({
    required this.id,
    required this.createdAt,
    required this.customerName,
    this.destinationAddress,
    required this.deliveryDate,
    this.userId,
    this.items,
  });

  factory DeliveryNote.fromJson(Map<String, dynamic> json) {
    return DeliveryNote(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      customerName: json['customer_name'] as String,
      destinationAddress: json['destination_address'] as String?,
      deliveryDate: DateTime.parse(json['delivery_date'] as String),
      userId: json['user_id'] as String?,
      items:
          (json['inventory_transactions'] as List?)
              ?.map(
                (e) => {
                  'product_id': e['product_id'],
                  'quantity_change': e['quantity_change'],
                  'product_name':
                      (e['products'] as Map<String, dynamic>?)?['name'],
                },
              )
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_name': customerName,
      'destination_address': destinationAddress,
      'delivery_date':
          deliveryDate
              .toIso8601String()
              .split('T')
              .first, // Format for date only
    };
  }
}
