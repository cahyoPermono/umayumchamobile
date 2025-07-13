import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:umayumcha/controllers/inventory_controller.dart';
import 'package:umayumcha/models/delivery_note_model.dart';

class DeliveryNoteController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;
  final InventoryController inventoryController = Get.find();

  var deliveryNotes = <DeliveryNote>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    fetchDeliveryNotes();
    super.onInit();
  }

  Future<void> fetchDeliveryNotes() async {
    try {
      isLoading.value = true;
      final response = await supabase
          .from('delivery_notes')
          .select(
            '*, inventory_transactions(product_id, quantity_change, products(name)), from_branch_id(name), to_branch_id(name)',
          )
          .order('created_at', ascending: false);

      deliveryNotes.value =
          (response as List)
              .map((item) => DeliveryNote.fromJson(item))
              .toList();
      debugPrint('Delivery notes fetched: ${deliveryNotes.length}');
    } catch (e) {
      debugPrint('Error fetching delivery notes: ${e.toString()}');
      Get.snackbar('Error', 'Failed to fetch delivery notes: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createDeliveryNote({
    String? customerName,
    String? destinationAddress,
    required DateTime deliveryDate,
    required String fromBranchId,
    required String toBranchId,
    required List<Map<String, dynamic>> items, // {productId, quantity}
  }) async {
    try {
      isLoading.value = true;

      // 1. Create the delivery note entry
      final response =
          await supabase
              .from('delivery_notes')
              .insert({
                'customer_name': customerName ?? 'Internal Transfer',
                'destination_address': destinationAddress ?? 'Internal Transfer',
                'delivery_date':
                    deliveryDate.toIso8601String().split('T').first,
                'from_branch_id': fromBranchId,
                'to_branch_id': toBranchId,
              })
              .select('id')
              .single();

      final String deliveryNoteId = response['id'];
      debugPrint('Delivery note created with ID: $deliveryNoteId');

      // 2. Create inventory transactions for each item in the delivery note
      for (var item in items) {
        await inventoryController.addTransaction(
          productId: item['product_id'],
          type: 'out',
          quantityChange: item['quantity'],
          reason: 'Delivery Note: $customerName',
          deliveryNoteId: deliveryNoteId,
          fromBranchId: fromBranchId,
          toBranchId:
              toBranchId, // For inter-branch transfer, toBranchId is also relevant for the transaction
        );
        debugPrint('Transaction added for product ${item['product_id']}');
      }

      fetchDeliveryNotes(); // Refresh the list
      Get.back(); // Close the form screen
      Get.snackbar('Success', 'Delivery note created successfully!');
    } catch (e) {
      debugPrint('Error creating delivery note: ${e.toString()}');
      Get.snackbar('Error', 'Failed to create delivery note: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
}
