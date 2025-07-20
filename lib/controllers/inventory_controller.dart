import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:umayumcha/controllers/auth_controller.dart';
import 'package:umayumcha/models/branch_product_model.dart';
import 'package:umayumcha/models/branch_model.dart';
import 'package:umayumcha/models/product_model.dart';

class InventoryController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;

  var branchProducts = <BranchProduct>[].obs;
  var isLoading = false.obs;
  var selectedBranch = Rx<Branch?>(null);
  var globalLowStockProducts = <BranchProduct>[].obs; // Renamed and now global
  var searchQuery = ''.obs;

  // Filtered list based on search query
  RxList<BranchProduct> get filteredBranchProducts =>
      branchProducts
          .where((product) {
            final query = searchQuery.value.toLowerCase();
            return product.product!.name.toLowerCase().contains(query) ||
                product.product!.code.toLowerCase().contains(query);
          })
          .toList()
          .obs;

  static const int lowStockThreshold = 50; // Define your threshold here

  Future<bool> updateProduct(Product product) async {
    isLoading.value = true;
    try {
      final authController = Get.find<AuthController>();
      final String? currentUserId = authController.currentUser.value?.id;

      final Map<String, dynamic> updateData = {
        'name': product.name,
        'code': product.code,
        'description': product.description,
        'merk': product.merk,
        'kondisi': product.kondisi,
        'tahun_perolehan': product.tahunPerolehan,
        'nilai_residu': product.nilaiResidu,
        'pengguna': product.pengguna,
        'price': product.price,
        'updated_at': DateTime.now().toIso8601String(), // Set updated_at here
      };

      if (currentUserId != null) {
        updateData['updated_by'] = currentUserId as dynamic;
      }

      await supabase
          .from('products')
          .update(updateData)
          .eq('id', product.id!);

      fetchBranchProducts(); // Refresh the list
      return true; // Return true on success
    } catch (e) {
      debugPrint('Error updating product: $e');
      Get.snackbar('Error', 'Failed to update product: ${e.toString()}');
      return false; // Return false on failure
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteProduct(String productId) async {
    isLoading.value = true;
    try {
      await supabase.from('products').delete().eq('id', productId);

      // If no exception is thrown, the deletion is successful.
      Get.snackbar('Success', 'Product deleted successfully');
      fetchBranchProducts(); // Refresh the list
    } catch (e) {
      debugPrint('Error deleting product: $e'); // Log the actual error
      Get.snackbar('Error', 'Failed to delete product: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onInit() {
    // Listen for changes in selectedBranch and refetch products
    ever(selectedBranch, (_) => fetchBranchProducts());
    fetchGlobalLowStockProducts(); // Fetch global low stock on init
    super.onInit();
  }

  Future<void> fetchGlobalLowStockProducts() async {
    try {
      var query = supabase
          .from('branch_products')
          .select(
            '*, products(*), branches(name)',
          ) // Join products and branches
          .lt('quantity', lowStockThreshold);

      // Filter by user's branch if not admin
      final authController = Get.find<AuthController>();
      if (authController.userRole.value != 'admin' &&
          authController.userBranchId.value != null) {
        query = query.eq(
          'branch_id',
          authController.userBranchId.value!,
        ); // Filter by user's branch
      }

      final response = await query;

      globalLowStockProducts.value =
          (response as List).map((item) {
            // Manually attach branch name for display
            final Map<String, dynamic> bpData = Map.from(item);
            bpData['branches'] =
                item['branches']; // Ensure branch data is passed
            return BranchProduct.fromJson(bpData);
          }).toList();
      debugPrint(
        'Global low stock products fetched: ${globalLowStockProducts.length}',
      );
    } catch (e) {
      debugPrint('Error fetching global low stock products: ${e.toString()}');
    }
  }

  Future<void> refreshDashboardData() async {
    await fetchGlobalLowStockProducts();
    // Add other dashboard-related data fetches here if needed
  }

  Future<void> fetchBranchProducts() async {
    if (selectedBranch.value == null || selectedBranch.value!.id == null) {
      branchProducts.clear();
      return; // No branch selected or branch ID is null, clear products
    }
    try {
      isLoading.value = true;
      var query = supabase
          .from('branch_products')
          .select('*, products(*)')
          .eq('branch_id', selectedBranch.value!.id!)
          .order('created_at', ascending: true);

      // Allow all users to view UmayumchaHQ inventory
      final authController = Get.find<AuthController>();
      if (authController.userRole.value != 'admin' &&
          selectedBranch.value?.name != 'UmayumchaHQ' &&
          authController.userBranchId.value != selectedBranch.value!.id) {
        // If a non-admin user tries to select a branch that is not theirs, clear products and show error
        branchProducts.clear();
        Get.snackbar(
          'Access Denied',
          'You can only view products for your assigned branch or UmayumchaHQ.',
        );
        isLoading.value = false;
        return;
      }

      final response = await query;

      debugPrint('Raw response from Supabase: $response');

      branchProducts.value =
          (response as List)
              .map((item) => BranchProduct.fromJson(item))
              .toList();
      debugPrint('Branch products fetched: ${branchProducts.length}');

      // No longer update lowStockProducts here, as it's now global
    } catch (e) {
      debugPrint('Error fetching branch products: ${e.toString()}');
      Get.snackbar('Error', 'Failed to fetch branch products: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<BranchProduct>> fetchBranchProductsById(String branchId) async {
    try {
      final authController = Get.find<AuthController>();
      // Non-admin users can only fetch products for their assigned branch
      if (authController.userRole.value != 'admin' &&
          authController.userBranchId.value != branchId) {
        debugPrint(
          'Access Denied: Non-admin user trying to fetch products for unassigned branch.',
        );
        return [];
      }

      final response = await supabase
          .from('branch_products')
          .select(
            '*, products(*)',
          ) // Select branch_product and join product details
          .eq('branch_id', branchId)
          .order('created_at', ascending: true);

      final List<BranchProduct> products =
          (response as List)
              .map((item) => BranchProduct.fromJson(item))
              .toList();
      debugPrint(
        'Branch products fetched by ID ($branchId): ${products.length}',
      );
      return products;
    } catch (e) {
      debugPrint(
        'Error fetching branch products by ID ($branchId): ${e.toString()}',
      );
      return [];
    }
  }

  Future<String?> addProductAndGetId(Product product) async {
    try {
      isLoading.value = true;
      final response =
          await supabase
              .from('products')
              .insert(product.toJson())
              .select('id')
              .single();
      debugPrint('Product added with ID: ${response['id']}');
      return response['id'] as String;
    } catch (e) {
      debugPrint('Error adding product: ${e.toString()}');
      Get.snackbar('Error', 'Failed to add product: ${e.toString()}');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addTransaction({
    required String productId,
    required String type,
    required int quantityChange,
    String? reason,
    String? deliveryNoteId,
    String? fromBranchId,
    String? toBranchId,
    String? fromBranchName,
    String? toBranchName,
  }) async {
    try {
      isLoading.value = true;

      // Fetch product name
      final productResponse = await supabase
          .from('products')
          .select('name')
          .eq('id', productId)
          .single();
      final productName = productResponse['name'] as String;

      // Use provided branch names, or fetch them if only IDs are available.
      String? finalFromBranchName = fromBranchName;
      if (fromBranchId != null && finalFromBranchName == null) {
        final fromBranchResponse = await supabase
            .from('branches')
            .select('name')
            .eq('id', fromBranchId)
            .single();
        finalFromBranchName = fromBranchResponse['name'] as String;
      }

      String? finalToBranchName = toBranchName;
      if (toBranchId != null && finalToBranchName == null) {
        final toBranchResponse = await supabase
            .from('branches')
            .select('name')
            .eq('id', toBranchId)
            .single();
        finalToBranchName = toBranchResponse['name'] as String;
      }

      final int finalQuantityChange = type == 'out' ? -quantityChange : quantityChange;

      // The database trigger 'on_branch_inventory_transaction' handles all stock updates.
      // This function's only responsibility is to insert the transaction record.
      await supabase.from('inventory_transactions').insert({
        'product_id': productId,
        'product_name': productName,
        'type': type,
        'quantity_change': finalQuantityChange, // Now correctly signed (negative for 'out')
        'reason': reason,
        'delivery_note_id': deliveryNoteId,
        'from_branch_id': fromBranchId,
        'from_branch_name': finalFromBranchName,
        'to_branch_id': toBranchId,
        'to_branch_name': finalToBranchName,
      });

      debugPrint(
        'Transaction added: type=$type, quantity=$quantityChange, product=$productId',
      );
      fetchBranchProducts();
      fetchGlobalLowStockProducts();
      return true; // Return true on success
    } catch (e) {
      debugPrint('Error adding transaction: ${e.toString()}');
      Get.snackbar(
        'Error',
        'Failed to add transaction: ${e.toString()}',
      );
      return false; // Return false on failure
    } finally {
      isLoading.value = false;
    }
  }
}
