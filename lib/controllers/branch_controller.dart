import 'package:umayumcha/controllers/auth_controller.dart'; // Import AuthController
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
    final AuthController authController = Get.find();

    // Listen to changes in user role or branch ID to refetch branches with debounce
    debounce(
      authController.userRole,
      (_) => fetchBranches(),
      time: const Duration(milliseconds: 300),
    );
    debounce(
      authController.userBranchId,
      (_) => fetchBranches(),
      time: const Duration(milliseconds: 300),
    );

    super.onInit();
  }

  Future<void> fetchBranches() async {
    try {
      isLoading.value = true;
      String selectQuery = '*';
      List<String> conditions = [];

      final authController = Get.find<AuthController>();
      if (authController.userRole.value != 'admin' &&
          authController.userBranchId.value != null) {
        conditions.add('id.eq.${authController.userBranchId.value!}');
      }

      if (conditions.isNotEmpty) {
        selectQuery += '.filter(${conditions.join(',')})';
      }

      final response = await supabase
          .from('branches')
          .select(selectQuery)
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
