
class Branch {
  final String? id;
  final String name;
  final String? address;
  final DateTime? createdAt;

  Branch({
    this.id,
    required this.name,
    this.address,
    this.createdAt,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
    };
  }
}
