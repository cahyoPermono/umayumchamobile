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
          .select('*, products(name)') // Select product name for display
          .order('created_at', ascending: false);

      transactions.value =
          (response as List).map((item) {
            // Attach product name to the transaction for display
            final Map<String, dynamic> transactionData = Map.from(item);
            transactionData['product_name'] = item['products']['name'];
            return InventoryTransaction.fromJson(transactionData);
          }).toList();
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch transactions: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
}
