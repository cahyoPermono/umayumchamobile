
class Product {
  final String id;
  final String name;
  final String? description;
  final String? sku;
  final double? price;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    this.description,
    this.sku,
    this.price,
    required this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      sku: json['sku'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'sku': sku,
      'price': price,
    };
  }
}
