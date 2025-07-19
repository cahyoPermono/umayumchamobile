import 'dart:developer';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:umayumcha/controllers/auth_controller.dart';
import 'package:umayumcha/models/consumable_model.dart';

class ConsumableController extends GetxController {
  final _supabase = Supabase.instance.client;
  var consumables = <Consumable>[].obs;
  var expiringConsumables = <Consumable>[].obs;
  var isLoading = false.obs;
  var searchQuery = ''.obs; // New: Search query observable
  String? umayumchaHQBranchId;

  // New: Filtered consumables list
  RxList<Consumable> get filteredConsumables =>
      consumables
          .where((consumable) {
            if (searchQuery.isEmpty) {
              return true;
            }
            final lowerCaseQuery = searchQuery.toLowerCase();
            return consumable.name.toLowerCase().contains(lowerCaseQuery) ||
                consumable.code.toLowerCase().contains(lowerCaseQuery) ||
                (consumable.description != null &&
                    consumable.description!.toLowerCase().contains(
                      lowerCaseQuery,
                    ));
          })
          .toList()
          .obs;

  @override
  void onInit() {
    super.onInit();
    fetchConsumables();
    _fetchUmayumchaHQBranchId();
  }

  Future<void> _fetchUmayumchaHQBranchId() async {
    try {
      final response =
          await _supabase
              .from('branches')
              .select('id')
              .eq('name', 'UmayumchaHQ')
              .single();
      umayumchaHQBranchId = response['id'] as String;
    } catch (e) {
      log('Error fetching UmayumchaHQ branch ID: $e');
    }
  }

  Future<void> fetchConsumables() async {
    try {
      isLoading.value = true;
      final response = await _supabase.from('consumables').select();
      consumables.value =
          (response as List).map((item) => Consumable.fromJson(item)).toList();

      // Sort consumables by name
      consumables.sort((a, b) => a.name.compareTo(b.name));

      // Filter expiring consumables
      final now = DateTime.now();
      expiringConsumables.value =
          consumables.where((c) {
            if (c.expiredDate == null) return false;
            final difference = c.expiredDate!.difference(now).inDays;
            return difference >= 0 && difference <= 60;
          }).toList();
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch consumables: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addConsumable(Consumable consumable) async {
    try {
      isLoading.value = true;
      await _supabase.from('consumables').insert([consumable.toJson()]);
      fetchConsumables(); // Refresh the list
      Get.back(); // Close the form screen
      Get.snackbar(
        'Success',
        'Consumable added successfully!',
      ); // Success snackbar
    } catch (e) {
      log('Error adding consumable: $e'); // Add this line
      Get.snackbar('Error', 'Failed to add consumable: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateConsumable(Consumable consumable) async {
    try {
      isLoading.value = true;
      final consumableMap = consumable.toJson();
      consumableMap.remove('created_at'); // Ensure created_at is not updated
      consumableMap.remove('id'); // Ensure id is not in the update payload

      // Add updated_by
      final authController = Get.find<AuthController>();
      consumableMap['updated_by'] = authController.currentUser.value?.id; // Assuming currentUser is Rx<User?>

      await _supabase
          .from('consumables')
          .update(consumableMap)
          .eq('id', consumable.id!);
      fetchConsumables(); // Refresh the list
      Get.back(); // Close the form screen
      Get.snackbar(
        'Success',
        'Consumable updated successfully!',
      ); // Success snackbar
    } catch (e) {
      log('Error updating consumable: $e');
      Get.snackbar('Error', 'Failed to update consumable: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteConsumable(int id) async {
    try {
      isLoading.value = true;
      await _supabase.from('consumables').delete().eq('id', id);
      fetchConsumables(); // Refresh the list
      Get.snackbar(
        'Success',
        'Consumable deleted successfully!',
      ); // Success snackbar
    } catch (e) {
      log('Error deleting consumable: $e');
      Get.snackbar('Error', 'Failed to delete consumable: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _logTransaction({
    required int consumableId,
    required String consumableName,
    required int quantityChange,
    required String type,
    String? reason,
    String? branchSourceId,
    String? branchSourceName,
    String? branchDestinationId,
    String? branchDestinationName,
  }) async {
    try {
      await _supabase.from('consumable_transactions').insert({
        'consumable_id': consumableId,
        'consumable_name': consumableName,
        'quantity_change': quantityChange,
        'type': type,
        'reason': reason,
        'branch_source_id': branchSourceId,
        'branch_source_name': branchSourceName,
        'branch_destination_id': branchDestinationId,
        'branch_destination_name': branchDestinationName,
      });
    } catch (e) {
      log('Error logging consumable transaction: $e');
      Get.snackbar(
        'Error',
        'Failed to log consumable transaction: ${e.toString()}',
      );
    }
  }

  Future<void> addConsumableQuantity(
    int id,
    int quantity,
    String reason,
  ) async {
    try {
      final consumable = consumables.firstWhere((c) => c.id == id);
      await _logTransaction(
        consumableId: id,
        consumableName: consumable.name,
        quantityChange: quantity,
        type: 'in',
        reason: reason,
        branchSourceId: umayumchaHQBranchId,
        branchSourceName: 'UmayumchaHQ',
        branchDestinationId: umayumchaHQBranchId,
        branchDestinationName: 'UmayumchaHQ',
      );
      fetchConsumables();
      Get.snackbar('Success', 'Consumable quantity added successfully!');
    } catch (e) {
      log('Error adding consumable quantity: $e');
      Get.snackbar(
        'Error',
        'Failed to add consumable quantity: ${e.toString()}',
      );
    }
  }

  Future<void> removeConsumableQuantity(
    int id,
    int quantity,
    String reason,
  ) async {
    try {
      final consumable = consumables.firstWhere((c) => c.id == id);
      await _logTransaction(
        consumableId: id,
        consumableName: consumable.name,
        quantityChange: -quantity,
        type: 'out',
        reason: reason,
        branchSourceId: umayumchaHQBranchId,
        branchSourceName: 'UmayumchaHQ',
        branchDestinationId: umayumchaHQBranchId,
        branchDestinationName: 'UmayumchaHQ',
      );
      fetchConsumables();
      Get.snackbar('Success', 'Consumable quantity removed successfully!');
    } catch (e) {
      log('Error removing consumable quantity: $e');
      Get.snackbar(
        'Error',
        'Failed to remove consumable quantity: ${e.toString()}',
      );
    }
  }
}
