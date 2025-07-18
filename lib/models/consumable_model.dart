
class Consumable {
  final int? id;
  final String code;
  final String name;
  final int quantity;
  final String? description; // Optional description
  final DateTime? expiredDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? updatedBy;

  Consumable({
    this.id,
    required this.code,
    required this.name,
    required this.quantity,
    this.description,
    this.expiredDate,
    this.createdAt,
    this.updatedAt,
    this.updatedBy,
  });

  factory Consumable.fromJson(Map<String, dynamic> json) {
    return Consumable(
      id: json['id'],
      code: json['code'],
      name: json['name'],
      quantity: json['quantity'],
      description: json['description'],
      expiredDate: json['expired_date'] != null
          ? DateTime.parse(json['expired_date'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      updatedBy: json['updated_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'code': code,
      'name': name,
      'quantity': quantity,
      'description': description,
      'expired_date': expiredDate?.toIso8601String(),
      'updated_by': updatedBy,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }
}
