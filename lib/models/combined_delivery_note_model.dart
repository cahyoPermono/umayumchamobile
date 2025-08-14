
class CombinedDeliveryNote {
  final DateTime date;
  final String itemName;
  final num quantity;
  final String? fromVendor;
  final String? toBranch;
  final String type;

  CombinedDeliveryNote({
    required this.date,
    required this.itemName,
    required this.quantity,
    this.fromVendor,
    this.toBranch,
    required this.type,
  });
}
