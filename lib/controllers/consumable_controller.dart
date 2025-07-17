
import 'dart:developer';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:umayumcha/models/consumable_model.dart';

class ConsumableController extends GetxController {
  final _supabase = Supabase.instance.client;
  var consumables = <Consumable>[].obs;
  var expiringConsumables = <Consumable>[].obs; // New: List for expiring consumables
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchConsumables();
  }

  Future<void> fetchConsumables() async {
    try {
      isLoading.value = true;
      final response = await _supabase.from('consumables').select();
      consumables.value = (response as List)
          .map((item) => Consumable.fromJson(item))
          .toList();

      // Filter expiring consumables
      final now = DateTime.now();
      expiringConsumables.value = consumables.where((c) {
        if (c.expiredDate == null) return false;
        final difference = c.expiredDate!.difference(now).inDays;
        return difference >= 0 && difference <= 30;
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
      await _supabase
          .from('consumables')
          .update(consumable.toJson())
          .eq('id', consumable.id!);
      fetchConsumables(); // Refresh the list
      Get.back(); // Close the form screen
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
    } catch (e) {
      log('Error deleting consumable: $e');
      Get.snackbar('Error', 'Failed to delete consumable: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _logTransaction({
    required int consumableId,
    required int quantityChange,
    required String type,
    String? reason,
  }) async {
    try {
      await _supabase.from('consumable_transactions').insert({
        'consumable_id': consumableId,
        'quantity_change': quantityChange,
        'type': type,
        'reason': reason,
      });
    } catch (e) {
      log('Error logging consumable transaction: $e');
      Get.snackbar('Error', 'Failed to log consumable transaction: ${e.toString()}');
    }
  }

  Future<void> addConsumableQuantity(int id, int quantity, String reason) async {
    try {
      await _logTransaction(consumableId: id, quantityChange: quantity, type: 'in', reason: reason);
      fetchConsumables();
    } catch (e) {
      log('Error adding consumable quantity: $e');
      Get.snackbar('Error', 'Failed to add consumable quantity: ${e.toString()}');
    }
  }

  Future<void> removeConsumableQuantity(int id, int quantity, String reason) async {
    try {
      await _logTransaction(consumableId: id, quantityChange: -quantity, type: 'out', reason: reason);
      fetchConsumables();
    } catch (e) {
      log('Error removing consumable quantity: $e');
      Get.snackbar('Error', 'Failed to remove consumable quantity: ${e.toString()}');
    }
  }
}
