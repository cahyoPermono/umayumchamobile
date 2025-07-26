
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:umayumcha_ims/models/consumable_transaction_model.dart';

class ConsumableTransactionLogController extends GetxController {
  final _supabase = Supabase.instance.client;
  var transactions = <ConsumableTransaction>[].obs;
  var isLoading = false.obs;
  var fromDate = Rx<DateTime?>(null);
  var toDate = Rx<DateTime?>(null);
  var selectedBranchDestination = Rx<String?>(null);
  var searchQuery = ''.obs; // New: For free-text search

  @override
  void onInit() {
    super.onInit();
    // Set default date range (e.g., last 30 days)
    toDate.value = DateTime.now();
    fromDate.value = toDate.value!.subtract(const Duration(days: 30));
    // Listen to date range changes
    ever(fromDate, (_) => fetchTransactions());
    ever(toDate, (_) => fetchTransactions());
    // New: Listen to search query changes with debounce
    debounce(searchQuery, (_) => fetchTransactions(), time: const Duration(milliseconds: 500));
    fetchTransactions();
  }

  void setFromDate(DateTime date) {
    fromDate.value = date;
    filterTransactions();
  }

  void setToDate(DateTime date) {
    toDate.value = date;
    filterTransactions();
  }

  void setSelectedBranchDestination(String? branchName) {
    // This method is no longer needed as the filter is removed
  }

  Future<void> fetchTransactions() async {
    try {
      isLoading.value = true;
      var query = _supabase
          .from('consumable_transactions_with_user_email_view')
          .select('*, consumable_name, branch_source_name, branch_destination_name');

      if (fromDate.value != null) {
        query = query.gte('created_at', fromDate.value!.toIso8601String());
      }
      if (toDate.value != null) {
        query = query.lte(
            'created_at', toDate.value!.add(const Duration(days: 1)).toIso8601String());
      }

      // New: Apply free-text search filter
      if (searchQuery.value.isNotEmpty) {
        final String searchPattern = '%${searchQuery.value.toLowerCase()}%';
        query = query.or('consumable_name.ilike.$searchPattern,branch_source_name.ilike.$searchPattern,branch_destination_name.ilike.$searchPattern');
      }

      final response = await query.order('created_at', ascending: false);

      transactions.value = (response as List)
          .map((item) => ConsumableTransaction.fromJson(item))
          .toList();
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch consumable transactions: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  void filterTransactions() {
    fetchTransactions();
  }
}
