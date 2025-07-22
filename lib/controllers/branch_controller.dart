import 'package:umayumcha_ims/controllers/auth_controller.dart'; // Import AuthController
import 'package:flutter/foundation.dart'; // For debugPrint
import 'dart:developer';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:umayumcha_ims/models/branch_model.dart';

class BranchController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;

  var branches = <Branch>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    final AuthController authController = Get.find();

    // Fetch branches immediately on init
    fetchBranches();

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
      final response = await supabase
          .from('branches')
          .select('*')
          .order('name', ascending: true);

      branches.value =
          (response as List).map((item) => Branch.fromJson(item)).toList();
      debugPrint('Branches fetched: ${branches.length}');
      debugPrint(
        'Fetched branch names: ${branches.map((b) => b.name).toList()}',
      );
    } catch (e) {
      log('Error fetching branches: ${e.toString()}');
      Get.snackbar('Error', 'Failed to fetch branches: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addBranch(Branch branch) async {
    try {
      isLoading.value = true;
      await supabase.from('branches').insert(branch.toJson());
      fetchBranches();
      Get.back();
      Get.snackbar('Success', 'Branch added successfully!');
    } catch (e) {
      log('Error adding branch: ${e.toString()}');
      Get.snackbar('Error', 'Failed to add branch: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateBranch(Branch branch) async {
    if (branch.id == null) {
      Get.snackbar('Error', 'Cannot update branch without an ID.');
      return;
    }
    try {
      isLoading.value = true;
      await supabase
          .from('branches')
          .update(branch.toJson())
          .eq('id', branch.id!);

      // Find the index of the updated branch and replace it in the local list
      int index = branches.indexWhere((b) => b.id == branch.id);
      if (index != -1) {
        branches[index] = branch;
        branches.refresh(); // Notify listeners of the change
      } else {
        fetchBranches(); // Fallback to fetching all if not found
      }

      Get.back();
      Get.snackbar('Success', 'Branch updated successfully!');
    } catch (e) {
      log('Error updating branch: ${e.toString()}');
      Get.snackbar('Error', 'Failed to update branch: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteBranch(String? id) async {
    if (id == null) {
      Get.snackbar('Error', 'Tidak dapat menghapus cabang tanpa ID.');
      return;
    }
    try {
      isLoading.value = true;

      // Fetch the branch to check its name
      final branchData =
          await supabase.from('branches').select('name').eq('id', id).single();

      if (branchData['name'] == 'UmayumchaHQ') {
        Get.snackbar(
          'Peringatan',
          'Cabang UmayumchaHQ tidak dapat dihapus.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      await supabase.from('branches').delete().eq('id', id);
      branches.removeWhere((b) => b.id == id);
      Get.snackbar('Sukses', 'Cabang berhasil dihapus!');
    } catch (e) {
      log('Error deleting branch: ${e.toString()}');
      Get.snackbar('Error', 'Gagal menghapus cabang: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
}
