import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:umayumcha_ims/controllers/auth_controller.dart';
import 'package:umayumcha_ims/models/branch_product_model.dart';
import 'package:umayumcha_ims/models/branch_model.dart';
import 'package:umayumcha_ims/models/product_model.dart';
import 'package:umayumcha_ims/controllers/consumable_controller.dart'; // Import ConsumableController

class InventoryController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;

  var branchProducts = <BranchProduct>[].obs;
  var isLoading = false.obs;
  var selectedBranch = Rx<Branch?>(null);
  var globalLowStockProducts = <BranchProduct>[].obs; // Renamed and now global
  var searchQuery = ''.obs;
  String? umayumchaHQBranchId; // To store UmayumchaHQ branch ID

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

      await supabase.from('products').update(updateData).eq('id', product.id!);

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
    _fetchUmayumchaHQBranchId(); // Fetch UmayumchaHQ branch ID on init
    fetchGlobalLowStockProducts(); // Fetch global low stock on init
    super.onInit();
  }

  Future<void> _fetchUmayumchaHQBranchId() async {
    try {
      final response =
          await supabase
              .from('branches')
              .select('id')
              .eq('name', 'UmayumchaHQ')
              .single();
      umayumchaHQBranchId = response['id'] as String;
      debugPrint('UmayumchaHQ branch ID fetched: $umayumchaHQBranchId');
    } catch (e) {
      debugPrint('Error fetching UmayumchaHQ branch ID: $e');
    }
  }

  Future<void> fetchGlobalLowStockProducts() async {
    try {
      if (umayumchaHQBranchId == null) {
        await _fetchUmayumchaHQBranchId(); // Ensure branch ID is fetched
      }
      if (umayumchaHQBranchId == null) {
        debugPrint(
          'UmayumchaHQ branch ID is null, cannot fetch low stock products.',
        );
        return;
      }

      final response = await supabase.rpc(
        'get_low_stock_products',
        params: {'p_branch_id': umayumchaHQBranchId!},
      );

      globalLowStockProducts.value =
          (response as List).map((item) {
            final product = Product(
              id: item['product_id'] as String,
              name: item['product_name'] as String,
              code: item['product_code'] as String,
              description: item['product_description'] as String?,
              merk: item['product_merk'] as String?,
              kondisi: item['product_kondisi'] as String?,
              tahunPerolehan: item['product_tahun_perolehan'] as String?,
              nilaiResidu: (item['product_nilai_residu'] as num?)?.toDouble(),
              pengguna: item['product_pengguna'] as String?,
              price: (item['product_price'] as num?)?.toDouble(),
              lowStock: item['product_low_stock'] as int? ?? 50,
              createdAt: item['created_at'] != null
                  ? DateTime.parse(item['created_at'] as String)
                  : null,
              updatedAt: item['updated_at'] != null
                  ? DateTime.parse(item['updated_at'] as String)
                  : null,
            );

            final branch = Branch(
              id: item['branch_id'] as String,
              name: item['branch_name'] as String,
              // Assuming other branch fields are not needed or can be null
            );

            return BranchProduct(
              id: item['id'] as String,
              productId: item['product_id'] as String,
              branchId: item['branch_id'] as String,
              quantity: item['quantity'] as int,
              createdAt: DateTime.parse(item['created_at'] as String),
              product: product,
              branchName: branch.name,
            );
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
    final consumableController = Get.find<ConsumableController>();
    await consumableController.fetchGlobalLowStockConsumables();
    await consumableController.fetchConsumables();
  }

  Future<void> fetchBranchProducts() async {
    if (selectedBranch.value == null || selectedBranch.value!.id == null) {
      branchProducts.clear();
      return; // No branch selected or branch ID is null, clear products
    }
    try {
      isLoading.value = true;
      final response = await supabase
          .from('branch_products')
          .select('*, products(*)')
          .eq('branch_id', selectedBranch.value!.id!)
          .order('created_at', ascending: true);

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

  Future<void> reverseTransaction(String transactionId) async {
    try {
      final transaction =
          await supabase
              .from('inventory_transactions')
              .select('*')
              .eq('id', transactionId)
              .single();

      // update transaction set deliveryNoteId to null
      await supabase
          .from('inventory_transactions')
          .update({'delivery_note_id': null})
          .eq('id', transactionId);

      final String productId = transaction['product_id'];
      final String type = transaction['type'];
      final int quantityChange = transaction['quantity_change'].abs();
      final String? fromBranchId = transaction['from_branch_id'];
      final String? toBranchId = transaction['to_branch_id'];
      final String? fromBranchName = transaction['from_branch_name'];
      final String? toBranchName = transaction['to_branch_name'];

      // Reverse the transaction type and branches
      final String reversedType = type == 'in' ? 'out' : 'in';
      final String? reversedFromBranchId = toBranchId;
      final String? reversedToBranchId = fromBranchId;
      final String? reversedFromBranchName = toBranchName;
      final String? reversedToBranchName = fromBranchName;

      await addTransaction(
        productId: productId,
        type: reversedType,
        quantityChange: quantityChange,
        reason: 'Reversal of transaction $transactionId',
        fromBranchId: reversedFromBranchId,
        toBranchId: reversedToBranchId,
        fromBranchName: reversedFromBranchName,
        toBranchName: reversedToBranchName,
      );
      debugPrint('Reversed inventory transaction $transactionId');
    } catch (e) {
      debugPrint(
        'Error reversing inventory transaction $transactionId: ${e.toString()}',
      );
      Get.snackbar(
        'Error',
        'Failed to reverse inventory transaction: ${e.toString()}',
      );
      rethrow; // Rethrow to allow calling function to catch and handle
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
      final productResponse =
          await supabase
              .from('products')
              .select('name')
              .eq('id', productId)
              .single();
      final productName = productResponse['name'] as String;

      // Use provided branch names, or fetch them if only IDs are available.
      String? finalFromBranchName = fromBranchName;
      if (fromBranchId != null && finalFromBranchName == null) {
        final fromBranchResponse =
            await supabase
                .from('branches')
                .select('name')
                .eq('id', fromBranchId)
                .single();
        finalFromBranchName = fromBranchResponse['name'] as String;
      }

      String? finalToBranchName = toBranchName;
      if (toBranchId != null && finalToBranchName == null) {
        final toBranchResponse =
            await supabase
                .from('branches')
                .select('name')
                .eq('id', toBranchId)
                .single();
        finalToBranchName = toBranchResponse['name'] as String;
      }

      final int finalQuantityChange =
          type == 'out' ? -quantityChange : quantityChange;

      // The database trigger 'on_branch_inventory_transaction' handles all stock updates.
      // This function's only responsibility is to insert the transaction record.
      await supabase.from('inventory_transactions').insert({
        'product_id': productId,
        'product_name': productName,
        'type': type,
        'quantity_change':
            finalQuantityChange, // Now correctly signed (negative for 'out')
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
      Get.snackbar('Error', 'Failed to add transaction: ${e.toString()}');
      return false; // Return false on failure
    } finally {
      isLoading.value = false;
    }
  }
}
