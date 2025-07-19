class InventoryTransaction {
  final String id;
  final String? productId;
  final String? productName;
  final String? type;
  final int quantityChange;
  final String? reason;
  final String? deliveryNoteId;
  final String? fromBranchId;
  final String? toBranchId;
  final String? fromBranchName;
  final String? toBranchName;
  final DateTime createdAt;

  InventoryTransaction({
    required this.id,
    this.productId,
    this.productName,
    this.type,
    required this.quantityChange,
    this.reason,
    this.deliveryNoteId,
    this.fromBranchId,
    this.toBranchId,
    this.fromBranchName,
    this.toBranchName,
    required this.createdAt,
  });

  factory InventoryTransaction.fromJson(Map<String, dynamic> json) {
    return InventoryTransaction(
      id: json['id'] as String,
      productId: json['product_id'] as String?,
      productName: json['products']?['name'] as String?,
      type: json['type'] as String?,
      quantityChange: json['quantity_change'] as int,
      reason: json['reason'] as String?,
      deliveryNoteId: json['delivery_note_id'] as String?,
      fromBranchId: (json['from_branch_id'] as Map<String, dynamic>?)?['id'] as String?,
      toBranchId: (json['to_branch_id'] as Map<String, dynamic>?)?['id'] as String?,
      fromBranchName: (json['from_branch_id'] as Map<String, dynamic>?)?['name'] as String?,
      toBranchName: (json['to_branch_id'] as Map<String, dynamic>?)?['name'] as String?,
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
      'from_branch_id': fromBranchId,
      'to_branch_id': toBranchId,
    };
  }
}