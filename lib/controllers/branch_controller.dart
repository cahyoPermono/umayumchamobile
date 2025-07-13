import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:umayumcha/models/branch_model.dart';

class BranchController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;

  var branches = <Branch>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    fetchBranches();
    super.onInit();
  }

  Future<void> fetchBranches() async {
    try {
      isLoading.value = true;
      final response = await supabase
          .from('branches')
          .select()
          .order('name', ascending: true);

      branches.value =
          (response as List).map((item) => Branch.fromJson(item)).toList();
      debugPrint('Branches fetched: ${branches.length}');
    } catch (e) {
      debugPrint('Error fetching branches: ${e.toString()}');
      Get.snackbar('Error', 'Failed to fetch branches: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // You might add methods for adding/editing branches here later
}
