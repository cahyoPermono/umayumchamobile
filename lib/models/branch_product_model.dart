
import 'package:umayumcha/models/product_model.dart';

class BranchProduct {
  final String id;
  final String branchId;
  final String productId;
  final int quantity;
  final DateTime createdAt;
  final Product? product; // To hold product details
  final String? branchName; // New: To hold branch name for display

  BranchProduct({
    required this.id,
    required this.branchId,
    required this.productId,
    required this.quantity,
    required this.createdAt,
    this.product,
    this.branchName,
  });

  factory BranchProduct.fromJson(Map<String, dynamic> json) {
    return BranchProduct(
      id: json['id'] as String,
      branchId: json['branch_id'] as String,
      productId: json['product_id'] as String,
      quantity: json['quantity'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      product: json['products'] != null
          ? Product.fromJson(json['products'] as Map<String, dynamic>)
          : null,
      branchName: (json['branches'] as Map<String, dynamic>?)?['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'branch_id': branchId,
      'product_id': productId,
      'quantity': quantity,
    };
  }
}
