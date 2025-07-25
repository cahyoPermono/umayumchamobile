import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:umayumcha_ims/models/selectable_item.dart'; // Import SelectableItem

class ItemSelectionDialog extends StatefulWidget {
  final List<SelectableItem> items;

  const ItemSelectionDialog({super.key, required this.items});

  @override
  State<ItemSelectionDialog> createState() => _ItemSelectionDialogState();
}

class _ItemSelectionDialogState extends State<ItemSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<SelectableItem> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterItems);
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems =
          widget.items.where((item) {
            return item.name.toLowerCase().contains(query);
          }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Item'),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6, // Adjust height as needed
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search Item',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _filteredItems.isEmpty
                ? const Center(child: Text('No items found'))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      return ListTile(
                        title: Text(
                          '${item.name} (Stock: ${item.quantity}) [${item.type.capitalizeFirst}]',
                        ),
                        onTap: () {
                          Get.back(result: item); // Return selected item
                        },
                      );
                    },
                  ),
          ),
        ],
      ), // This closes the Column widget
    ), // This closes the SizedBox widget
      actions: [
        TextButton(
          onPressed: () {
            Get.back(); // Close dialog without selection
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
