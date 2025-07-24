import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:umayumcha_ims/controllers/auth_controller.dart';
import 'package:umayumcha_ims/controllers/inventory_controller.dart';
import 'package:umayumcha_ims/controllers/branch_controller.dart';
import 'package:umayumcha_ims/models/branch_product_model.dart';
import 'package:umayumcha_ims/screens/product_form_screen.dart';
import 'package:umayumcha_ims/widgets/delete_confirmation_dialog.dart';

void _showTransactionDialog(
  BuildContext context,
  BranchProduct branchProduct,
  String type,
) {
  final InventoryController controller = Get.find();
  final BranchController branchController = Get.find(); // Get BranchController
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();
  final formKey = GlobalKey<FormState>(); // Declare GlobalKey here

  // Find UmayumchaHQ branch details
  final umayumchaHQBranch = branchController.branches.firstWhereOrNull(
    (branch) => branch.id == '2e109b1a-12c6-4572-87ab-6c96add8a603',
  );
  final String? umayumchaHQBranchId = umayumchaHQBranch?.id;
  final String? umayumchaHQBranchName = umayumchaHQBranch?.name;

  Get.dialog(
    AlertDialog(
      title: Text(
        '${type == 'in' ? 'Add' : 'Remove'} Stock for ${branchProduct.product?.name ?? 'N/A'}',
      ),
      content: Form(
        key: formKey, // Assign the key to the Form
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null ||
                    int.tryParse(value) == null ||
                    int.parse(value) <= 0) {
                  return 'Please enter a valid quantity.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText:
                    'Reason ${type == 'out' ? '(Required)' : '(Optional)'}',
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (type == 'out' && (value == null || value.isEmpty)) {
                  return 'Reason is required for OUT transactions.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            // Added async here
            if (formKey.currentState!.validate()) {
              // Use the key to validate
              final int quantity = int.parse(quantityController.text);

              String? fromBranchId;
              String? toBranchId;
              String? fromBranchName;
              String? toBranchName;
              toBranchId = umayumchaHQBranchId;
              toBranchName = umayumchaHQBranchName;
              fromBranchId = umayumchaHQBranchId;
              fromBranchName = umayumchaHQBranchName;

              final success = await controller.addTransaction(
                productId: branchProduct.productId,
                type: type,
                quantityChange: quantity,
                reason: reasonController.text.trim(),
                fromBranchId: fromBranchId,
                toBranchId: toBranchId,
                fromBranchName: fromBranchName,
                toBranchName: toBranchName,
              );
              Get.back(); // Close dialog
              if (success) {
                Get.snackbar('Success', 'Stock updated successfully!');
              } else {
                Get.snackbar(
                  'Error',
                  'Failed to update stock.',
                  margin: EdgeInsets.all(10),
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            }
          },
          child: Text(type == 'in' ? 'Add' : 'Remove'),
        ),
      ],
    ),
  );
}

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final InventoryController inventoryController = Get.find();
  final BranchController branchController = Get.find();
  final AuthController authController = Get.find();

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      inventoryController.searchQuery.value = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            _isSearching
                ? Colors.white
                : Theme.of(context).primaryColor, // Dynamic background color
        iconTheme: IconThemeData(
          color: _isSearching ? Colors.black : Colors.white,
        ), // Dynamic icon color
        title:
            _isSearching
                ? Container(
                  height: 40, // Adjust height as needed
                  decoration: BoxDecoration(
                    color:
                        Colors
                            .white, // Solid white background for clear visibility
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search products...',
                      hintStyle: TextStyle(
                        color: Colors.grey,
                      ), // Grey hint text
                      border: InputBorder.none, // Remove default border
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey,
                      ), // Grey search icon
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 10.0,
                      ), // Adjust padding
                    ),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                    ), // Black text for contrast
                    cursorColor: Colors.black,
                  ),
                )
                : const Text(
                  'Master Inventory',
                  style: TextStyle(color: Colors.white),
                ), // Ensure title is white when not searching
        elevation: 4,
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: _isSearching ? Colors.black : Colors.white,
            ), // Dynamic icon color
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  inventoryController.searchQuery.value = '';
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Directly set UmayumchaHQ as the selected branch after the build is complete
          Obx(() {
            if (branchController.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final umayumchaHQBranch = branchController.branches
                  .firstWhereOrNull(
                    (branch) =>
                        branch.id == '2e109b1a-12c6-4572-87ab-6c96add8a603',
                  );
              if (umayumchaHQBranch != null &&
                  inventoryController.selectedBranch.value == null) {
                inventoryController.selectedBranch.value = umayumchaHQBranch;
              }
            });
            return const SizedBox.shrink(); // No UI for branch selection
          }),
          Expanded(
            child: Obx(() {
              if (inventoryController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (inventoryController.selectedBranch.value == null) {
                return const Center(
                  child: Text('Please select a branch to view inventory.'),
                );
              }
              if (inventoryController.filteredBranchProducts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 80, color: Colors.grey),
                      SizedBox(height: 20),
                      Text(
                        inventoryController.searchQuery.isEmpty
                            ? 'No products in this branch.'
                            : 'No matching products found.',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () => inventoryController.fetchBranchProducts(),
                child: ListView.builder(
                  itemCount: inventoryController.filteredBranchProducts.length,
                  itemBuilder: (context, index) {
                    final branchProduct =
                        inventoryController.filteredBranchProducts[index];
                    final product =
                        branchProduct.product; // Get the nested product details
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () {
                          // No direct edit for master products from here,
                          // but could navigate to a product detail screen if needed.
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      product?.name ?? 'N/A',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Qty: ${branchProduct.quantity}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium?.copyWith(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Code: ${product?.code ?? 'No Code'}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                'Description: ${product?.description ?? 'No Description'}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      Get.to(
                                        () => ProductFormScreen(
                                          product: product,
                                          locationName:
                                              inventoryController
                                                  .selectedBranch
                                                  .value
                                                  ?.name,
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () {
                                      showDeleteConfirmationDialog(
                                        title: 'Delete Product',
                                        content:
                                            'Are you sure you want to delete ${product?.name ?? 'this product'}?',
                                        onConfirm: () {
                                          if (product != null &&
                                              product.id != null) {
                                            final productId = product.id!;
                                            inventoryController.deleteProduct(
                                              productId,
                                            );
                                          }
                                        },
                                      );
                                    },
                                  ),
                                  ElevatedButton.icon(
                                    onPressed:
                                        () => _showTransactionDialog(
                                          context,
                                          branchProduct,
                                          'in',
                                        ),
                                    icon: const Icon(Icons.add),
                                    label: const Text('In'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed:
                                        () => _showTransactionDialog(
                                          context,
                                          branchProduct,
                                          'out',
                                        ),
                                    icon: const Icon(Icons.remove),
                                    label: const Text('Out'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => const ProductFormScreen());
        },
        tooltip: 'Add New Master Product',
        child: const Icon(Icons.add),
      ),
    );
  }
}
