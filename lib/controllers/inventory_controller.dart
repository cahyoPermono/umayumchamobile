import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:umayumcha/models/product_model.dart';

class InventoryController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;

  var products = <Product>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    fetchProducts();
    super.onInit();
  }

  Future<void> fetchProducts() async {
    try {
      isLoading.value = true;
      final response = await supabase
          .from('products')
          .select()
          .order('name', ascending: true);

      products.value =
          (response as List).map((item) => Product.fromJson(item)).toList();
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch products: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addProduct(Product product) async {
    try {
      isLoading.value = true;
      await supabase.from('products').insert(product.toJson());
      fetchProducts(); // Refresh the list
      Get.back(); // Close the form screen
      Get.snackbar('Success', 'Product added successfully!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to add product: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addTransaction({
    required String productId,
    required String type,
    required int quantityChange,
    String? reason,
    String? deliveryNoteId,
  }) async {
    try {
      isLoading.value = true;
      await supabase.from('inventory_transactions').insert({
        'product_id': productId,
        'type': type,
        'quantity_change': quantityChange,
        'reason': reason,
        'delivery_note_id': deliveryNoteId,
      });
      fetchProducts(); // Refresh product quantities
      Get.snackbar('Success', 'Stock updated successfully!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update stock: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
}
