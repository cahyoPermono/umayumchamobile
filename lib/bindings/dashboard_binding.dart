
import 'package:get/get.dart';
import 'package:umayumcha/controllers/auth_controller.dart';
import 'package:umayumcha/controllers/inventory_controller.dart';
import 'package:umayumcha/controllers/consumable_controller.dart';
import 'package:umayumcha/controllers/delivery_note_controller.dart';
import 'package:umayumcha/controllers/branch_controller.dart';
import 'package:umayumcha/controllers/consumable_transaction_log_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(() => AuthController());
    Get.lazyPut<InventoryController>(() => InventoryController());
    Get.lazyPut<DeliveryNoteController>(() => DeliveryNoteController());
    Get.lazyPut<BranchController>(() => BranchController());
    Get.lazyPut<ConsumableController>(() => ConsumableController());
    Get.lazyPut<ConsumableTransactionLogController>(() => ConsumableTransactionLogController());
  }
}
