
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:umayumcha/models/consumable_transaction_model.dart';

class ConsumableTransactionLogController extends GetxController {
  final _supabase = Supabase.instance.client;
  var transactions = <ConsumableTransaction>[].obs;
  var isLoading = false.obs;
  var fromDate = Rx<DateTime?>(null);
  var toDate = Rx<DateTime?>(null);
  var selectedBranchDestination = Rx<String?>(null);
  var distinctBranchDestinations = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchDistinctBranchDestinations();
    fetchTransactions();
  }

  void setFromDate(DateTime date) {
    fromDate.value = date;
  }

  void setToDate(DateTime date) {
    toDate.value = date;
  }

  void setSelectedBranchDestination(String? branchName) {
    selectedBranchDestination.value = branchName;
    filterTransactions();
  }

  Future<void> fetchDistinctBranchDestinations() async {
    try {
      final response = await _supabase
          .from('consumable_transactions_with_user_email_view')
          .select('branch_destination_name')
          .neq('branch_destination_name', '')
          .order('branch_destination_name', ascending: true);

      distinctBranchDestinations.value = (response as List)
          .map((item) => item['branch_destination_name'] as String)
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList();
      distinctBranchDestinations.sort();
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch distinct branch destinations: ${e.toString()}');
    }
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
      if (selectedBranchDestination.value != null &&
          selectedBranchDestination.value!.isNotEmpty) {
        query = query.eq('branch_destination_name', selectedBranchDestination.value!);
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
