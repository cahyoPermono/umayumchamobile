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
            '*, inventory_transactions(product_id, quantity_change, products(name))',
          )
          .order('created_at', ascending: false);

      deliveryNotes.value =
          (response as List)
              .map((item) => DeliveryNote.fromJson(item))
              .toList();
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch delivery notes: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createDeliveryNote({
    required String customerName,
    String? destinationAddress,
    required DateTime deliveryDate,
    required List<Map<String, dynamic>> items, // {productId, quantity}
  }) async {
    try {
      isLoading.value = true;

      // 1. Create the delivery note entry
      final response =
          await supabase
              .from('delivery_notes')
              .insert({
                'customer_name': customerName,
                'destination_address': destinationAddress,
                'delivery_date':
                    deliveryDate.toIso8601String().split('T').first,
              })
              .select('id')
              .single();

      final String deliveryNoteId = response['id'];

      // 2. Create inventory transactions for each item in the delivery note
      for (var item in items) {
        await inventoryController.addTransaction(
          productId: item['product_id'],
          type: 'out',
          quantityChange: item['quantity'],
          reason: 'Delivery Note: $customerName',
          deliveryNoteId: deliveryNoteId,
        );
      }

      fetchDeliveryNotes(); // Refresh the list
      Get.back(); // Close the form screen
      Get.snackbar('Success', 'Delivery note created successfully!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to create delivery note: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
}
