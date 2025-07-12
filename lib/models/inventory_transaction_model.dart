class InventoryTransaction {
  final String id;
  final String productId;
  final String? productName; // Added for display
  final String type;
  final int quantityChange;
  final String? reason;
  final String? deliveryNoteId;
  final DateTime createdAt;

  InventoryTransaction({
    required this.id,
    required this.productId,
    this.productName,
    required this.type,
    required this.quantityChange,
    this.reason,
    this.deliveryNoteId,
    required this.createdAt,
  });

  factory InventoryTransaction.fromJson(Map<String, dynamic> json) {
    return InventoryTransaction(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String?,
      type: json['type'] as String,
      quantityChange: json['quantity_change'] as int,
      reason: json['reason'] as String?,
      deliveryNoteId: json['delivery_note_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'type': type,
      'quantity_change': quantityChange,
      'reason': reason,
      'delivery_note_id': deliveryNoteId,
    };
  }
}