
class ConsumableTransaction {
  final int id;
  final int? consumableId;
  final String? consumableName;
  final int quantityChange;
  final String type;
  final String? reason;
  final DateTime createdAt;
  final String? userId;
  final String? userEmail;
  final String? branchSourceId;
  final String? branchSourceName;
  final String? branchDestinationId;
  final String? branchDestinationName;
  final String? deliveryNoteId; // New: delivery_note_id

  ConsumableTransaction({
    required this.id,
    this.consumableId,
    this.consumableName,
    required this.quantityChange,
    required this.type,
    this.reason,
    required this.createdAt,
    this.userId,
    this.userEmail,
    this.branchSourceId,
    this.branchSourceName,
    this.branchDestinationId,
    this.branchDestinationName,
    this.deliveryNoteId, // New: delivery_note_id
  });

  factory ConsumableTransaction.fromJson(Map<String, dynamic> json) {
    return ConsumableTransaction(
      id: json['id'] as int,
      consumableId: json['consumable_id'] as int?,
      consumableName: json['consumable_name'] as String?,
      quantityChange: json['quantity_change'] as int,
      type: json['type'] as String,
      reason: json['reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      userId: json['user_id'] as String?,
      userEmail: json['user_email'] as String?,
      branchSourceId: json['branch_source_id'] as String?,
      branchSourceName: json['branch_source_name'] as String?,
      branchDestinationId: json['branch_destination_id'] as String?,
      branchDestinationName: json['branch_destination_name'] as String?,
      deliveryNoteId: json['delivery_note_id'] as String?, // New: delivery_note_id
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'consumable_id': consumableId,
      'quantity_change': quantityChange,
      'type': type,
      'reason': reason,
      'user_id': userId,
      'consumable_name': consumableName,
      'branch_source_id': branchSourceId,
      'branch_source_name': branchSourceName,
      'branch_destination_id': branchDestinationId,
      'branch_destination_name': branchDestinationName,
      'delivery_note_id': deliveryNoteId, // New: delivery_note_id
    };
  }
}
