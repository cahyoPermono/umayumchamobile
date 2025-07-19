
class Product {
  final String id;
  final String name;
  final String code; // Changed from sku and made required
  final String? description;
  final String? merk; // New optional field
  final String? kondisi; // New optional field
  final String? tahunPerolehan; // New optional field
  final double? nilaiResidu; // New optional field
  final String? pengguna; // New optional field
  final double? price;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.code, // Required
    this.description,
    this.merk,
    this.kondisi,
    this.tahunPerolehan,
    this.nilaiResidu,
    this.pengguna,
    this.price,
    required this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String, // Required
      description: json['description'] as String?,
      merk: json['merk'] as String?,
      kondisi: json['kondisi'] as String?,
      tahunPerolehan: json['tahun_perolehan'] as String?,
      nilaiResidu: (json['nilai_residu'] as num?)?.toDouble(),
      pengguna: json['pengguna'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code, // Required
      'description': description,
      'merk': merk,
      'kondisi': kondisi,
      'tahun_perolehan': tahunPerolehan,
      'nilai_residu': nilaiResidu,
      'pengguna': pengguna,
      'price': price,
    };
  }
}
