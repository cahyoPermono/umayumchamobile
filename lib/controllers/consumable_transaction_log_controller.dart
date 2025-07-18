
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:umayumcha/models/consumable_transaction_model.dart';

class ConsumableTransactionLogController extends GetxController {
  final _supabase = Supabase.instance.client;
  var transactions = <ConsumableTransaction>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    try {
      isLoading.value = true;
      final response = await _supabase
          .from('consumable_transactions_with_user_email_view')
          .select('*, consumables(name)')
          .order('created_at', ascending: false);

      transactions.value = (response as List)
          .map((item) => ConsumableTransaction.fromJson(item))
          .toList();
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch consumable transactions: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
}
