import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:umayumcha_ims/controllers/auth_controller.dart';

class IncomingDeliveryNoteReportController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;
  final AuthController authController = Get.find();

  var isLoading = false.obs;
  var reportItems = <Map<String, dynamic>>[].obs;
  var distinctFromBranchNames = <String>[].obs;
  var distinctProductConsumableNames = <String>[].obs;

  var selectedFromBranchName = Rx<String?>(null);
  var selectedItemName = Rx<String?>(null);
  var selectedFromDate = Rx<DateTime?>(null);
  var selectedToDate = Rx<DateTime?>(null);

  var totalOverallCost = 0.0.obs;
  var totalOverallQuantity = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    if (authController.userRole.value == 'finance') {
      _initializeFiltersAndFetch();
      fetchDistinctFromBranchNames();
      fetchDistinctProductConsumableNames();
    }
  }

  void _initializeFiltersAndFetch() {
    selectedFromDate.value = DateTime.now().subtract(const Duration(days: 30));
    selectedToDate.value = DateTime.now();
    fetchReportData();
  }

  Future<void> fetchDistinctFromBranchNames() async {
    try {
      final response = await supabase
          .from('incoming_delivery_notes')
          .select('from_vendor_name');
      distinctFromBranchNames.value =
          (response as List)
              .map((e) => (e['from_vendor_name'] as String).trim()) // Trim here
              .toSet()
              .toList();
    } catch (e) {
      debugPrint('Error fetching distinct branch names: ${e.toString()}');
    }
  }

  Future<void> fetchDistinctProductConsumableNames() async {
    try {
      // Fetch product names
      final productResponse = await supabase.from('products').select('name');
      final List<String> productNames =
          (productResponse as List).map((e) => e['name'] as String).toList();

      // Fetch consumable names
      final consumableResponse = await supabase
          .from('consumables')
          .select('name');
      final List<String> consumableNames =
          (consumableResponse as List).map((e) => e['name'] as String).toList();

      // Combine and make distinct
      distinctProductConsumableNames.value =
          (
          // ignore: prefer_collection_literals
          [...productNames, ...consumableNames].toSet().toList()..sort());
    } catch (e) {
      debugPrint(
        'Error fetching distinct product/consumable names: ${e.toString()}',
      );
    }
  }

  Future<void> fetchReportData() async {
    if (authController.userRole.value != 'finance' && authController.userRole.value != 'admin') {
      reportItems.clear();
      Get.snackbar(
        'Permission Denied',
        'You do not have permission to view this report.',
      );
      return;
    }

    try {
      isLoading.value = true;
      List<Map<String, dynamic>> allItems = [];

      List<String> incomingDeliveryNoteIds = [];
      if (selectedFromBranchName.value != null) {
        try {
          final matchingNotes = await supabase
              .from('incoming_delivery_notes')
              .select('id')
              .eq('from_vendor_name', selectedFromBranchName.value!.trim());
          incomingDeliveryNoteIds =
              (matchingNotes as List).map((e) => e['id'] as String).toList();

          if (incomingDeliveryNoteIds.isEmpty) {
            reportItems.clear();
            isLoading(false);
            return; // No matching notes, so no report items
          }
        } catch (e) {
          debugPrint(
            'Error fetching matching incoming delivery note IDs: ${e.toString()}',
          );
          Get.snackbar('Error', 'Failed to filter by vendor: ${e.toString()}');
          isLoading(false);
          return;
        }
      }

      // Fetch product transactions
      var productQuery = supabase
          .from('inventory_transactions')
          .select(
            '*, incoming_delivery_note:incoming_delivery_notes(from_vendor_name), product:products(price)',
          )
          .not('incoming_delivery_note_id', 'is', null)
          .eq('type', 'in');

      if (selectedFromBranchName.value != null) {
        debugPrint(
          'Filtering productQuery by incomingDeliveryNoteIds: $incomingDeliveryNoteIds',
        ); // Updated debugPrint
        productQuery = productQuery.inFilter(
          'incoming_delivery_note_id',
          incomingDeliveryNoteIds,
        );
      }
      if (selectedItemName.value != null) {
        productQuery = productQuery.eq('product_name', selectedItemName.value!);
      }
      if (selectedFromDate.value != null) {
        productQuery = productQuery.gte(
          'created_at',
          selectedFromDate.value!.toIso8601String().split('T').first,
        );
      }
      if (selectedToDate.value != null) {
        productQuery = productQuery.lte(
          'created_at',
          selectedToDate.value!
              .add(const Duration(days: 1))
              .toIso8601String()
              .split('T')
              .first,
        );
      }

      final productResponse = await productQuery;
      for (var item in productResponse) {
        final double price =
            (item['product']?['price'] as num?)?.toDouble() ?? 0.0;
        final int quantity = (item['quantity_change'] as int).abs();
        allItems.add({
          'item_name': item['product_name'] ?? 'N/A',
          'from_branch_name':
              item['incoming_delivery_note']?['from_vendor_name'] ?? 'N/A',
          'keterangan': item['reason'] ?? '',
          'delivery_date':
              item['incoming_delivery_note']?['delivery_date'] != null
                  ? DateTime.parse(
                    item['incoming_delivery_note']!['delivery_date'] as String,
                  ).toLocal()
                  : DateTime.now(),
          'quantity': quantity,
          'price_per_unit': price,
          'total_price': price * quantity,
          'type': 'product',
        });
      }

      // Fetch consumable transactions
      var consumableQuery = supabase
          .from('consumable_transactions')
          .select(
            '*, incoming_delivery_note:incoming_delivery_notes(from_vendor_name), consumable:consumables(price)',
          )
          .not('incoming_delivery_note_id', 'is', null)
          .eq('type', 'in');

      if (selectedFromBranchName.value != null) {
        debugPrint(
          'Filtering consumableQuery by incomingDeliveryNoteIds: $incomingDeliveryNoteIds',
        ); // Updated debugPrint
        consumableQuery = consumableQuery.inFilter(
          'incoming_delivery_note_id',
          incomingDeliveryNoteIds,
        );
      }
      if (selectedItemName.value != null) {
        consumableQuery = consumableQuery.eq(
          'consumable_name',
          selectedItemName.value!,
        );
      }
      if (selectedFromDate.value != null) {
        consumableQuery = consumableQuery.gte(
          'created_at',
          selectedFromDate.value!.toIso8601String().split('T').first,
        );
      }
      if (selectedToDate.value != null) {
        consumableQuery = consumableQuery.lte(
          'created_at',
          selectedToDate.value!
              .add(const Duration(days: 1))
              .toIso8601String()
              .split('T')
              .first,
        );
      }

      final consumableResponse = await consumableQuery;
      for (var item in consumableResponse) {
        final double price =
            (item['consumable']?['price'] as num?)?.toDouble() ?? 0.0;
        final int quantity = (item['quantity_change'] as int).abs();
        allItems.add({
          'item_name': item['consumable_name'] ?? 'N/A',
          'from_branch_name':
              item['incoming_delivery_note']?['from_vendor_name'] ?? 'N/A',
          'keterangan': item['reason'] ?? '',
          'delivery_date':
              item['incoming_delivery_note']?['delivery_date'] != null
                  ? DateTime.parse(
                    item['incoming_delivery_note']!['delivery_date'] as String,
                  ).toLocal()
                  : DateTime.now(),
          'quantity': quantity,
          'price_per_unit': price,
          'total_price': price * quantity,
          'type': 'consumable',
        });
      }

      // Sort by delivery date
      allItems.sort(
        (a, b) => (b['delivery_date'] as DateTime).compareTo(
          a['delivery_date'] as DateTime,
        ),
      );

      reportItems.assignAll(allItems);

      // Calculate totals
      double calculatedTotalCost = 0.0;
      double calculatedTotalQuantity = 0.0;

      for (var item in allItems) {
        calculatedTotalCost += (item['total_price'] as double);
        calculatedTotalQuantity += (item['quantity'] as int);
      }

      totalOverallCost.value = calculatedTotalCost;
      totalOverallQuantity.value = calculatedTotalQuantity;

      debugPrint('Report items fetched: ${reportItems.length}');
    } catch (e) {
      debugPrint('Error fetching report data: ${e.toString()}');
      Get.snackbar('Error', 'Failed to fetch report data: ${e.toString()}');
    } finally {
      isLoading(false);
    }
  }
}
