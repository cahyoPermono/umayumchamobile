import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:umayumcha/controllers/consumable_controller.dart';
import 'package:umayumcha/controllers/inventory_controller.dart';
import 'package:umayumcha/models/delivery_note_model.dart';

class DeliveryNoteController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;
  final InventoryController inventoryController = Get.find();
  final ConsumableController consumableController =
      Get.find(); // New: Get ConsumableController

  var deliveryNotes = <DeliveryNote>[].obs;
  var isLoading = false.obs;
  var distinctToBranchNames = <String>[].obs; // New: For filter dropdown
  var selectedToBranchName = Rx<String?>(null); // New: Selected filter
  var selectedFromDate = Rx<DateTime?>(null); // New: Selected filter
  var selectedToDate = Rx<DateTime?>(null); // New: Selected filter

  @override
  void onInit() {
    _initializeFiltersAndFetch();
    fetchDistinctToBranchNames(); // Fetch distinct branch names on init
    super.onInit();
  }

  void _initializeFiltersAndFetch() {
    // Set default fromDate to yesterday
    selectedFromDate.value = DateTime.now().subtract(const Duration(days: 1));
    // Set default toDate to today
    selectedToDate.value = DateTime.now();
    fetchDeliveryNotes(); // Fetch notes with initial filters
  }

  Future<void> fetchDistinctToBranchNames() async {
    try {
      final response = await supabase
          .from('distinct_to_branch_names') // Query the new view
          .select('to_branch_name');
      distinctToBranchNames.value = (response as List)
          .map((e) => e['to_branch_name'] as String)
          .toList();
    } catch (e) {
      debugPrint('Error fetching distinct branch names: ${e.toString()}');
    }
  }

  Future<void> fetchDeliveryNotes() async {
    try {
      isLoading.value = true;
      var query = supabase
          .from('delivery_notes')
          .select(
            '*, inventory_transactions(product_id, quantity_change, products(name)), consumable_transactions(consumable_id, quantity_change, consumable_name)',
          );

      // Apply filters
      if (selectedToBranchName.value != null) {
        query = query.eq('to_branch_name', selectedToBranchName.value!);
      }
      if (selectedFromDate.value != null) {
        query = query.gte('delivery_date', selectedFromDate.value!.toIso8601String().split('T').first);
      }
      if (selectedToDate.value != null) {
        query = query.lte('delivery_date', selectedToDate.value!.toIso8601String().split('T').first);
      }
      final response = await query.order('created_at', ascending: false);

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
    required List<Map<String, dynamic>> items, // {id, name, quantity, type}
  }) async {
    try {
      isLoading.value = true;

      // Fetch branch names before inserting into delivery_notes
      final fromBranchResponse = await supabase
          .from('branches')
          .select('name')
          .eq('id', fromBranchId)
          .single();
      final String fromBranchName = fromBranchResponse['name'] as String;

      final toBranchResponse = await supabase
          .from('branches')
          .select('name')
          .eq('id', toBranchId)
          .single();
      final String toBranchName = toBranchResponse['name'] as String;

      // 1. Create the delivery note entry
      final response =
          await supabase
              .from('delivery_notes')
              .insert({
                'customer_name': customerName ?? 'Internal Transfer',
                'destination_address':
                    destinationAddress ?? 'Internal Transfer',
                'delivery_date':
                    deliveryDate.toIso8601String().split('T').first,
                'from_branch_id': fromBranchId,
                'to_branch_id': toBranchId,
                'from_branch_name': fromBranchName, // Save branch name
                'to_branch_name': toBranchName, // Save branch name
              })
              .select('id') // Only select ID now, names are already saved
              .single();

      final String deliveryNoteId = response['id'];
      debugPrint('Delivery note created with ID: $deliveryNoteId');

      // 2. Create transactions for each item in the delivery note
      for (var item in items) {
        final String itemType = item['type'];
        final String itemId = item['id'];
        final String itemName = item['name'];
        final int quantity = item['quantity'];

        if (itemType == 'product') {
          await inventoryController.addTransaction(
            productId: itemId,
            type: 'out',
            quantityChange: quantity,
            reason: 'Delivery Note: $customerName',
            deliveryNoteId: deliveryNoteId,
            fromBranchId: fromBranchId,
            toBranchId: toBranchId,
            fromBranchName: fromBranchName,
            toBranchName: toBranchName,
          );
          debugPrint('Transaction added for product $itemName');
        } else if (itemType == 'consumable') {
          await consumableController.addConsumableTransactionFromDeliveryNote(
            consumableId: int.parse(itemId),
            consumableName: itemName,
            quantityChange: quantity,
            reason: 'Delivery Note: $customerName',
            deliveryNoteId: deliveryNoteId,
            fromBranchId: fromBranchId,
            toBranchId: toBranchId,
            fromBranchName: fromBranchName, // Pass branch names
            toBranchName: toBranchName, // Pass branch names
          );
          debugPrint('Transaction added for consumable $itemName');
        }
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
