class Product {
  final String? id;
  final String name;
  final String code;
  final String? description;
  final String? merk;
  final String? kondisi;
  final String? tahunPerolehan;
  final double? nilaiResidu;
  final String? pengguna;
  final double? price;
  final int lowStock; // Added lowStock field
  final String from; // New field
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? updatedBy;

  Product({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    this.merk,
    this.kondisi,
    this.tahunPerolehan,
    this.nilaiResidu,
    this.pengguna,
    this.price,
    required this.lowStock, // Made lowStock required
    required this.from, // Make it required
    this.createdAt,
    this.updatedAt,
    this.updatedBy,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      description: json['description'] as String?,
      merk: json['merk'] as String?,
      kondisi: json['kondisi'] as String?,
      tahunPerolehan: json['tahun_perolehan'] as String?,
      nilaiResidu: (json['nilai_residu'] as num?)?.toDouble(),
      pengguna: json['pengguna'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      lowStock: json['low_stock'] as int, // lowStock is now required
      from: json['from'] ?? '', // Parse from JSON
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
      updatedBy: json['updated_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'name': name,
      'code': code,
      'description': description,
      'merk': merk,
      'kondisi': kondisi,
      'tahun_perolehan': tahunPerolehan,
      'nilai_residu': nilaiResidu,
      'pengguna': pengguna,
      'price': price,
      'low_stock': lowStock, // Add low_stock to toJson
      'from': from, // Include in JSON
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'updated_by': updatedBy,
    };
    if (id != null) {
      json['id'] = id;
    }
    return json;
  }

  Product copyWith({
    String? id,
    String? name,
    String? code,
    String? description,
    String? merk,
    String? kondisi,
    String? tahunPerolehan,
    double? nilaiResidu,
    String? pengguna,
    double? price,
    required int lowStock,
    required String from, // Make it required
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      merk: merk ?? this.merk,
      kondisi: kondisi ?? this.kondisi,
      tahunPerolehan: tahunPerolehan ?? this.tahunPerolehan,
      nilaiResidu: nilaiResidu ?? this.nilaiResidu,
      pengguna: pengguna ?? this.pengguna,
      price: price ?? this.price,
      lowStock: lowStock, // Update lowStock in copyWith
      from: from, // Update from in copyWith
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
