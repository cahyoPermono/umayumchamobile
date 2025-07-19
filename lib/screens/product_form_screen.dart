import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:umayumcha/controllers/inventory_controller.dart';
import 'package:umayumcha/controllers/branch_controller.dart'; // Import BranchController
import 'package:umayumcha/models/product_model.dart';
import 'package:umayumcha/models/branch_model.dart'; // Import Branch model

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final InventoryController inventoryController = Get.find();
  final BranchController branchController = Get.find();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController codeController =
      TextEditingController(); // Changed from skuController
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController merkController = TextEditingController(); // New
  final TextEditingController kondisiController =
      TextEditingController(); // New
  final TextEditingController tahunPerolehanController =
      TextEditingController(); // New
  final TextEditingController nilaiResiduController =
      TextEditingController(); // New
  final TextEditingController penggunaController =
      TextEditingController(); // New
  final TextEditingController priceController = TextEditingController();
  final TextEditingController initialQuantityController =
      TextEditingController();

  Rx<Branch?> umayumchaHQBranch = Rx<Branch?>(
    null,
  ); // To hold the UmayumchaHQ branch

  @override
  void initState() {
    super.initState();
    debugPrint('ProductFormScreen: initState called.');
    debugPrint(
      'ProductFormScreen: Initial branchController.branches: ${branchController.branches.length}',
    );
    debugPrint(
      'ProductFormScreen: Initial branchController.isLoading: ${branchController.isLoading.value}',
    );

    // Listen for changes in branches and set UmayumchaHQ
    ever(branchController.branches, (_) {
      debugPrint(
        'ProductFormScreen: branchController.branches changed. Current length: ${branchController.branches.length}',
      );
      _findAndSetUmayumchaHQBranch();
    });

    // Also check immediately in case branches are already loaded
    _findAndSetUmayumchaHQBranch();
  }

  void _findAndSetUmayumchaHQBranch() {
    debugPrint('ProductFormScreen: _findAndSetUmayumchaHQBranch called.');
    debugPrint(
      'ProductFormScreen: Current branches in controller: ${branchController.branches.map((b) => b.name).toList()}',
    ); // Add this line
    final foundBranch = branchController.branches.firstWhereOrNull(
      (branch) => branch.name == 'UmayumchaHQ',
    );
    if (foundBranch != null) {
      umayumchaHQBranch.value = foundBranch;
      debugPrint(
        'ProductFormScreen: UmayumchaHQ branch found and set: ${foundBranch.name}',
      );
    } else if (!branchController.isLoading.value) {
      // Only show error if not loading and branch not found
      Get.snackbar(
        'Error',
        'UmayumchaHQ branch not found. Please ensure it exists.',
      );
      debugPrint(
        'ProductFormScreen: UmayumchaHQ branch not found after branches loaded.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('ProductFormScreen: build called.');
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('Add New Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Product Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController, // Changed from skuController
              decoration: const InputDecoration(labelText: 'Code (Required)'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: merkController, // New
              decoration: const InputDecoration(labelText: 'Merk (Optional)'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: kondisiController, // New
              decoration: const InputDecoration(
                labelText: 'Kondisi (Optional)',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: tahunPerolehanController, // New
              decoration: const InputDecoration(
                labelText: 'Tahun Perolehan (Optional)',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nilaiResiduController, // New
              decoration: const InputDecoration(
                labelText: 'Nilai Residu (Optional)',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: penggunaController, // New
              decoration: const InputDecoration(
                labelText: 'Pengguna (Optional)',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Price (Optional)'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            // Display UmayumchaHQ as the fixed initial branch
            Obx(() {
              debugPrint('ProductFormScreen: Obx builder for branch called.');
              debugPrint(
                'ProductFormScreen: branchController.isLoading.value: ${branchController.isLoading.value}',
              );
              debugPrint(
                'ProductFormScreen: umayumchaHQBranch.value: ${umayumchaHQBranch.value?.name}',
              );

              if (branchController.isLoading.value) {
                return const CircularProgressIndicator();
              }
              final branchName = umayumchaHQBranch.value?.name ?? 'Loading...';
              return AbsorbPointer(
                // Make it non-interactive
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Initial Stock Branch',
                    border: const OutlineInputBorder(),
                  ),
                  controller: TextEditingController(text: branchName),
                  enabled: false, // Disable editing
                ),
              );
            }),
            const SizedBox(height: 16),
            TextField(
              controller: initialQuantityController,
              decoration: const InputDecoration(labelText: 'Initial Quantity'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            Obx(() {
              return inventoryController.isLoading.value
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty) {
                        Get.snackbar('Error', 'Product Name cannot be empty.');
                        return;
                      }
                      if (codeController.text.trim().isEmpty) {
                        // Code is now required
                        Get.snackbar('Error', 'Code cannot be empty.');
                        return;
                      }
                      if (umayumchaHQBranch.value == null) {
                        Get.snackbar(
                          'Error',
                          'UmayumchaHQ branch not found. Cannot save product.',
                        );
                        return;
                      }
                      final int? initialQuantity = int.tryParse(
                        initialQuantityController.text.trim(),
                      );
                      if (initialQuantity == null || initialQuantity < 0) {
                        Get.snackbar(
                          'Error',
                          'Please enter a valid initial quantity.',
                        );
                        return;
                      }

                      // 1. Add the master product
                      final newProduct = Product(
                        id: '', // ID will be generated by Supabase
                        name: nameController.text.trim(),
                        code: codeController.text.trim(), // Use codeController
                        description:
                            descriptionController.text.trim().isEmpty
                                ? null
                                : descriptionController.text.trim(),
                        merk:
                            merkController.text.trim().isEmpty
                                ? null
                                : merkController.text.trim(),
                        kondisi:
                            kondisiController.text.trim().isEmpty
                                ? null
                                : kondisiController.text.trim(),
                        tahunPerolehan:
                            tahunPerolehanController.text.trim().isEmpty
                                ? null
                                : tahunPerolehanController.text.trim(),
                        nilaiResidu: double.tryParse(
                          nilaiResiduController.text.trim(),
                        ),
                        pengguna:
                            penggunaController.text.trim().isEmpty
                                ? null
                                : penggunaController.text.trim(),
                        price: double.tryParse(priceController.text.trim()),
                        createdAt: DateTime.now(),
                      );

                      // Call addProduct and get the newly created product ID
                      final String? newProductId = await inventoryController
                          .addProductAndGetId(newProduct);

                      if (newProductId != null) {
                        // 2. Add initial stock transaction for UmayumchaHQ
                        await inventoryController.addTransaction(
                          productId: newProductId,
                          type: 'in',
                          quantityChange: initialQuantity,
                          reason: 'Initial stock for new product',
                          toBranchId:
                              umayumchaHQBranch
                                  .value!
                                  .id, // Use UmayumchaHQ branch ID
                        );
                        Get.back(); // Close the form screen
                        Get.snackbar(
                          'Success',
                          'Product and initial stock added successfully!',
                        );
                      } else {
                        Get.snackbar('Error', 'Failed to add product.');
                      }
                    },
                    child: const Text('Save Product'),
                  );
            }),
            SizedBox(
              height: MediaQuery.of(context).viewInsets.bottom > 0 ? 16.0 : 0.0,
            ), // Add extra space when keyboard is open
          ],
        ),
      ),
    );
  }
}
