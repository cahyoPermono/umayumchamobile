import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:umayumcha_ims/models/incoming_delivery_note_model.dart';
import 'package:umayumcha_ims/controllers/inventory_controller.dart';
import 'package:umayumcha_ims/controllers/consumable_controller.dart';

class IncomingDeliveryNoteController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;
  final InventoryController inventoryController = Get.find();
  final ConsumableController consumableController = Get.find();

  var incomingDeliveryNotes = <IncomingDeliveryNote>[].obs;
  var isLoading = false.obs;
  var distinctToBranchNames = <String>[].obs;
  var selectedToBranchName = Rx<String?>(null);
  var selectedFromDate = Rx<DateTime?>(null);
  var selectedToDate = Rx<DateTime?>(null);

  @override
  void onInit() {
    _initializeFiltersAndFetch();
    fetchDistinctToBranchNames();
    super.onInit();
  }

  void _initializeFiltersAndFetch() {
    selectedFromDate.value = DateTime.now().subtract(const Duration(days: 1));
    selectedToDate.value = DateTime.now();
    fetchIncomingDeliveryNotes();
  }

  Future<void> fetchDistinctToBranchNames() async {
    try {
      // This view might need to be created in Supabase if it doesn't exist
      // For incoming notes, we are interested in 'to_branch_name'
      final response = await supabase
          .from('branches') // Assuming we fetch all branch names
          .select('name');
      distinctToBranchNames.value =
          (response as List).map((e) => e['name'] as String).toList();
    } catch (e) {
      debugPrint('Error fetching distinct branch names: ${e.toString()}');
    }
  }

  Future<void> fetchIncomingDeliveryNotes() async {
    try {
      isLoading.value = true;
      var query = supabase
          .from('incoming_delivery_notes')
          .select(
            '*, inventory_transactions(product_id, product_name, quantity_change, reason), consumable_transactions(consumable_id, consumable_name, quantity_change, reason)',
          );

      if (selectedToBranchName.value != null) {
        query = query.eq('to_branch_name', selectedToBranchName.value!);
      }
      if (selectedFromDate.value != null) {
        query = query.gte(
          'delivery_date',
          selectedFromDate.value!.toIso8601String().split('T').first,
        );
      }
      if (selectedToDate.value != null) {
        query = query.lte(
          'delivery_date',
          selectedToDate.value!
              .add(Duration(days: 1))
              .toIso8601String()
              .split('T')
              .first,
        );
      }

      final response = await query.order('created_at', ascending: false);
      debugPrint(response.toString());

      incomingDeliveryNotes.value =
          (response as List)
              .map((item) => IncomingDeliveryNote.fromJson(item))
              .toList();
      debugPrint(
          'Incoming delivery notes fetched: ${incomingDeliveryNotes.length}');
    } catch (e) {
      debugPrint(
          'Error fetching incoming delivery notes: ${e.toString()}');
      Get.snackbar('Error',
          'Failed to fetch incoming delivery notes: ${e.toString()}');
    } finally {
      isLoading(false);
    }
  }

  Future<void> createIncomingDeliveryNote({
    String? fromVendorName,
    required DateTime deliveryDate,
    required String toBranchId,
    required String toBranchName,
    required List<Map<String, dynamic>> items,
    String? keterangan,
  }) async {
    try {
      isLoading.value = true;

      await supabase.rpc(
        'create_incoming_delivery_note_and_transactions',
        params: {
          'p_from_vendor_name': fromVendorName,
          'p_delivery_date': deliveryDate.toUtc().toIso8601String(),
          'p_to_branch_id': toBranchId,
          'p_to_branch_name': toBranchName,
          'p_keterangan': keterangan,
          'p_items': items,
        },
      );

      fetchIncomingDeliveryNotes();
      Get.back();
      Get.snackbar('Success', 'Incoming delivery note created successfully!');
    } catch (e) {
      debugPrint('Error creating incoming delivery note: ${e.toString()}');
      Get.snackbar('Error',
          'Failed to create incoming delivery note: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteIncomingDeliveryNote(String incomingDeliveryNoteId) async {
    try {
      isLoading(true);
      await supabase.rpc(
        'delete_incoming_delivery_note_and_reverse_stock',
        params: {'p_incoming_delivery_note_id': incomingDeliveryNoteId},
      );
      Get.snackbar('Success', 'Incoming Delivery Note deleted and stock reversed');
      fetchIncomingDeliveryNotes();
    } catch (e) {
      Get.snackbar('Error', 'Error deleting Incoming Delivery Note: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> updateIncomingDeliveryNote({
    required String incomingDeliveryNoteId,
    String? fromVendorName,
    required DateTime deliveryDate,
    required String toBranchId,
    required String toBranchName,
    required List<Map<String, dynamic>> newItems,
    required List<Map<String, dynamic>> originalItems,
    String? keterangan,
  }) async {
    try {
      isLoading.value = true;

      await supabase.rpc(
        'update_incoming_delivery_note_and_transactions',
        params: {
          'p_incoming_delivery_note_id': incomingDeliveryNoteId,
          'p_from_vendor_name': fromVendorName,
          'p_delivery_date': deliveryDate.toUtc().toIso8601String(),
          'p_to_branch_id': toBranchId,
          'p_to_branch_name': toBranchName,
          'p_keterangan': keterangan,
          'p_new_items': newItems,
          'p_original_items': originalItems,
        },
      );

      fetchIncomingDeliveryNotes();
      Get.back();
      Get.snackbar('Success', 'Incoming delivery note updated successfully!');
    } catch (e) {
      debugPrint('Error updating incoming delivery note: ${e.toString()}');
      Get.snackbar('Error',
          'Failed to update incoming delivery note: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
}
