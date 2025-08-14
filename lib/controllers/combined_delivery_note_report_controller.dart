
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:umayumcha_ims/models/combined_delivery_note_model.dart';

class CombinedDeliveryNoteReportController extends GetxController {
  final _supabase = Supabase.instance.client;
  final RxList<CombinedDeliveryNote> reportData = <CombinedDeliveryNote>[].obs;
  final RxBool isLoading = false.obs;
  final RxList<String> itemNames = <String>[].obs;

  final RxNum totalIn = RxNum(0);
  final RxNum totalOut = RxNum(0);
  final RxNum netTotal = RxNum(0);

  var selectedItemName = Rx<String?>(null);
  var selectedFromDate = Rx<DateTime?>(null);
  var selectedToDate = Rx<DateTime?>(null);

  @override
  void onInit() {
    super.onInit();
    _initializeFiltersAndFetch();
    fetchDistinctItemNames();
  }

  void _initializeFiltersAndFetch() {
    selectedFromDate.value = DateTime.now().subtract(const Duration(days: 7));
    selectedToDate.value = DateTime.now();
    fetchReportData();
  }

  Future<void> fetchDistinctItemNames() async {
    try {
      final productResponse = await _supabase.from('products').select('name');
      final consumableResponse = await _supabase.from('consumables').select('name');

      final productNames = (productResponse as List).map((e) => e['name'] as String).toList();
      final consumableNames = (consumableResponse as List).map((e) => e['name'] as String).toList();

      itemNames.value = {...productNames, ...consumableNames}.toList()..sort();
    } catch (e) {
      debugPrint('Error fetching distinct item names: $e');
    }
  }

  Future<void> fetchReportData() async {
    try {
      isLoading.value = true;

      final response = await _supabase.rpc(
        'get_combined_report',
        params: {
          'start_date': selectedFromDate.value!.toIso8601String(),
          'end_date': selectedToDate.value!.toIso8601String(),
          'item_name_filter': selectedItemName.value,
        },
      );

      final List<CombinedDeliveryNote> notes = (response as List).map((item) {
        return CombinedDeliveryNote(
          date: DateTime.parse(item['date']),
          itemName: item['itemName'] ?? 'N/A',
          quantity: item['quantity'] as num,
          fromVendor: item['fromVendor'],
          toBranch: item['toBranch'],
          type: item['note_type'] ?? 'N/A',
          keterangan: item['keterangan'],
        );
      }).toList();

      reportData.assignAll(notes);

      // Calculate totals
      num calculatedIn = 0;
      num calculatedOut = 0;
      for (var note in notes) {
        if (note.type == 'In') {
          calculatedIn += note.quantity;
        } else {
          calculatedOut += note.quantity.abs(); // Use absolute for summation
        }
      }
      totalIn.value = calculatedIn;
      totalOut.value = calculatedOut;
      netTotal.value = calculatedIn - calculatedOut;

    } catch (e) {
      debugPrint('Error fetching report data via RPC: $e');
      Get.snackbar('Error', 'Failed to fetch report data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  
}
