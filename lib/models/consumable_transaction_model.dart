
class ConsumableTransaction {
  final int id;
  final int consumableId;
  final String? consumableName;
  final int quantityChange;
  final String type;
  final String? reason;
  final DateTime createdAt;
  final String? userId;

  ConsumableTransaction({
    required this.id,
    required this.consumableId,
    this.consumableName,
    required this.quantityChange,
    required this.type,
    this.reason,
    required this.createdAt,
    this.userId,
  });

  factory ConsumableTransaction.fromJson(Map<String, dynamic> json) {
    return ConsumableTransaction(
      id: json['id'] as int,
      consumableId: json['consumable_id'] as int,
      consumableName: json['consumables']?['name'] as String?,
      quantityChange: json['quantity_change'] as int,
      type: json['type'] as String,
      reason: json['reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      userId: json['user_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'consumable_id': consumableId,
      'quantity_change': quantityChange,
      'type': type,
      'reason': reason,
      'user_id': userId,
    };
  }
}
