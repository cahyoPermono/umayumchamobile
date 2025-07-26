import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:umayumcha_ims/models/inventory_transaction_model.dart';

class TransactionLogController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;

  var transactions = <InventoryTransaction>[].obs;
  var isLoading = false.obs;
  var startDate = Rx<DateTime?>(null);
  var endDate = Rx<DateTime?>(null);
  var searchQuery = ''.obs; // New: For free-text search

  @override
  void onInit() {
    // Set default date range (e.g., last 30 days)
    endDate.value = DateTime.now();
    startDate.value = endDate.value!.subtract(const Duration(days: 30));
    fetchTransactions();
    // Listen to date range changes
    ever(startDate, (_) => fetchTransactions());
    ever(endDate, (_) => fetchTransactions());
    // New: Listen to search query changes with debounce
    debounce(searchQuery, (_) => fetchTransactions(), time: const Duration(milliseconds: 500));
    super.onInit();
  }

  Future<void> fetchTransactions() async {
    try {
      isLoading.value = true;
      var query = supabase
          .from('inventory_transactions')
          .select('*, products(name), from_branch_id(name), to_branch_id(name)');

      if (startDate.value != null) {
        query = query.gte('created_at', startDate.value!.toIso8601String());
      }
      if (endDate.value != null) {
        query = query.lte('created_at', endDate.value!.add(const Duration(days: 1)).toIso8601String());
      }

      // New: Apply free-text search filter
      if (searchQuery.value.isNotEmpty) {
        final String searchPattern = '%${searchQuery.value.toLowerCase()}%';
        query = query.or('product_name.ilike.$searchPattern,from_branch_name.ilike.$searchPattern,to_branch_name.ilike.$searchPattern');
      }

      final response = await query
          .order('created_at', ascending: false);

      transactions.value =
          (response as List).map((item) {
            final Map<String, dynamic> transactionData = Map.from(item);
            transactionData['product_name'] = item['products']?['name'];
            transactionData['from_branch_name'] =
                item['from_branch_id']?['name'];
            transactionData['to_branch_name'] = item['to_branch_id']?['name'];
            return InventoryTransaction.fromJson(transactionData);
          }).toList();
      debugPrint('Transactions fetched: ${transactions.length}');
    } catch (e) {
      debugPrint('Error fetching transactions: ${e.toString()}');
      Get.snackbar('Error', 'Failed to fetch transactions: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
}
