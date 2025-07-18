import 'package:get/get.dart';
import 'package:umayumcha/controllers/inventory_controller.dart';
import 'package:umayumcha/controllers/consumable_controller.dart';
import 'package:umayumcha/controllers/delivery_note_controller.dart';
import 'package:umayumcha/controllers/consumable_transaction_log_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InventoryController>(() => InventoryController());
    Get.lazyPut<DeliveryNoteController>(() => DeliveryNoteController());
    Get.lazyPut<ConsumableController>(() => ConsumableController());
    Get.lazyPut<ConsumableTransactionLogController>(
      () => ConsumableTransactionLogController(),
    );
  }
}
