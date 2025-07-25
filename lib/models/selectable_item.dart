class SelectableItem {
  final String id;
  final String name;
  final int quantity;
  final String type; // 'product' or 'consumable'

  SelectableItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.type,
  });
}
