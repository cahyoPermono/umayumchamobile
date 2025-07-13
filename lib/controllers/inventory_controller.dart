import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:umayumcha/models/branch_product_model.dart';
import 'package:umayumcha/models/branch_model.dart';
import 'package:umayumcha/models/product_model.dart';

class InventoryController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;

  var branchProducts = <BranchProduct>[].obs;
  var isLoading = false.obs;
  var selectedBranch = Rx<Branch?>(null);

  @override
  void onInit() {
    // Listen for changes in selectedBranch and refetch products
    ever(selectedBranch, (_) => fetchBranchProducts());
    super.onInit();
  }

  Future<void> fetchBranchProducts() async {
    if (selectedBranch.value == null) {
      branchProducts.clear();
      return; // No branch selected, clear products
    }
    try {
      isLoading.value = true;
      final response = await supabase
          .from('branch_products')
          .select(
            '*, products(*)',
          ) // Select branch_product and join product details
          .eq('branch_id', selectedBranch.value!.id)
          .order('created_at', ascending: true);

      branchProducts.value =
          (response as List)
              .map((item) => BranchProduct.fromJson(item))
              .toList();
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch branch products: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> addProductAndGetId(Product product) async {
    try {
      isLoading.value = true;
      final response = await supabase.from('products').insert(product.toJson()).select('id').single();
      return response['id'] as String;
    } catch (e) {
      Get.snackbar('Error', 'Failed to add product: ${e.toString()}');
      return null;
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
    String? fromBranchId, // New parameter
    String? toBranchId, // New parameter
  }) async {
    try {
      isLoading.value = true;
      await supabase.from('inventory_transactions').insert({
        'product_id': productId,
        'type': type,
        'quantity_change': quantityChange,
        'reason': reason,
        'delivery_note_id': deliveryNoteId,
        'from_branch_id': fromBranchId, // Pass new parameter
        'to_branch_id': toBranchId, // Pass new parameter
      });
      fetchBranchProducts(); // Refresh product quantities for the selected branch
      Get.snackbar('Success', 'Stock updated successfully!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update stock: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
}
