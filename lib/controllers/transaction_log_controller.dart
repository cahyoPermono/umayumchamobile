import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:umayumcha/models/inventory_transaction_model.dart';

class TransactionLogController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;

  var transactions = <InventoryTransaction>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    fetchTransactions();
    super.onInit();
  }

  Future<void> fetchTransactions() async {
    try {
      isLoading.value = true;
      final response = await supabase
          .from('inventory_transactions')
          .select(
            '*, products(name), from_branch_id(name), to_branch_id(name)',
          ) // Select product and branch names
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
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch transactions: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
}
