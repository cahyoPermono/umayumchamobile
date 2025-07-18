class DeliveryNote {
  final String id;
  final DateTime createdAt;
  final String? customerName;
  final String? destinationAddress;
  final DateTime deliveryDate;
  final String? userId;
  final String? fromBranchId;
  final String? toBranchId;
  final String? fromBranchName;
  final String? toBranchName;
  final List<Map<String, dynamic>>? items; // For displaying items in the note

  DeliveryNote({
    required this.id,
    required this.createdAt,
    this.customerName,
    this.destinationAddress,
    required this.deliveryDate,
    this.userId,
    this.fromBranchId,
    this.toBranchId,
    this.fromBranchName,
    this.toBranchName,
    this.items,
  });

  factory DeliveryNote.fromJson(Map<String, dynamic> json) {
    return DeliveryNote(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      customerName: json['customer_name'] as String?,
      destinationAddress: json['destination_address'] as String?,
      deliveryDate: DateTime.parse(json['delivery_date'] as String),
      userId: json['user_id'] as String?,
      fromBranchId:
          (json['from_branch_id'] as Map<String, dynamic>?)?['id'] as String?,
      toBranchId:
          (json['to_branch_id'] as Map<String, dynamic>?)?['id'] as String?,
      fromBranchName:
          (json['from_branch_id'] as Map<String, dynamic>?)?['name'],
      toBranchName: (json['to_branch_id'] as Map<String, dynamic>?)?['name'],
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
      'delivery_date': deliveryDate.toIso8601String().split('T').first,
      'from_branch_id': fromBranchId,
      'to_branch_id': toBranchId,
    };
  }
}
