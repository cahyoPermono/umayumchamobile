import 'package:get/get.dart';
import 'package:umayumcha_ims/controllers/delivery_note_controller.dart';
import 'package:umayumcha_ims/controllers/consumable_transaction_log_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DeliveryNoteController>(() => DeliveryNoteController());
    Get.lazyPut<ConsumableTransactionLogController>(
      () => ConsumableTransactionLogController(),
    );
  }
}
