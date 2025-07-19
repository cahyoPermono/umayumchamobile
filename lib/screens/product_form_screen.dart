import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:umayumcha/controllers/inventory_controller.dart';
import 'package:umayumcha/controllers/branch_controller.dart'; // Import BranchController
import 'package:umayumcha/models/product_model.dart';
import 'package:umayumcha/models/branch_model.dart'; // Import Branch model

class ProductFormScreen extends StatefulWidget {
  final Product? product;
  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final InventoryController inventoryController = Get.find();
  final BranchController branchController = Get.find();

  final _formKey = GlobalKey<FormState>();

  TextEditingController nameController = TextEditingController();
  TextEditingController codeController =
      TextEditingController(); // Changed from skuController
  TextEditingController descriptionController = TextEditingController();
  TextEditingController merkController = TextEditingController(); // New
  TextEditingController kondisiController = TextEditingController(); // New
  TextEditingController tahunPerolehanController =
      TextEditingController(); // New
  TextEditingController nilaiResiduController = TextEditingController(); // New
  TextEditingController penggunaController = TextEditingController(); // New
  TextEditingController priceController = TextEditingController();
  TextEditingController initialQuantityController = TextEditingController();

  Rx<Branch?> umayumchaHQBranch = Rx<Branch?>(
    null,
  ); // To hold the UmayumchaHQ branch

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.product?.name ?? '');
    codeController = TextEditingController(text: widget.product?.code ?? '');
    descriptionController = TextEditingController(
      text: widget.product?.description ?? '',
    );
    merkController = TextEditingController(text: widget.product?.merk ?? '');
    kondisiController = TextEditingController(
      text: widget.product?.kondisi ?? '',
    );
    tahunPerolehanController = TextEditingController(
      text: widget.product?.tahunPerolehan ?? '',
    );
    nilaiResiduController = TextEditingController(
      text: widget.product?.nilaiResidu?.toString() ?? '',
    );
    penggunaController = TextEditingController(
      text: widget.product?.pengguna ?? '',
    );
    priceController = TextEditingController(
      text: widget.product?.price?.toString() ?? '',
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
      appBar: AppBar(
        title: Text(
          widget.product == null ? 'Add New Product' : 'Edit Product',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: codeController,
                decoration: const InputDecoration(labelText: 'Code (Required)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: merkController,
                decoration: const InputDecoration(labelText: 'Merk (Optional)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: kondisiController,
                decoration: const InputDecoration(
                  labelText: 'Kondisi (Optional)',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: tahunPerolehanController,
                decoration: const InputDecoration(
                  labelText: 'Tahun Perolehan (Optional)',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nilaiResiduController,
                decoration: const InputDecoration(
                  labelText: 'Nilai Residu (Optional)',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: penggunaController,
                decoration: const InputDecoration(
                  labelText: 'Pengguna (Optional)',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price (Optional)'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              if (widget.product == null) ...[
                const SizedBox(height: 16),
                Obx(() {
                  if (branchController.isLoading.value) {
                    return const CircularProgressIndicator();
                  }
                  final branchName =
                      umayumchaHQBranch.value?.name ?? 'Loading...';
                  return AbsorbPointer(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Initial Stock Branch',
                        border: const OutlineInputBorder(),
                      ),
                      controller: TextEditingController(text: branchName),
                      enabled: false,
                    ),
                  );
                }),
                const SizedBox(height: 16),
                TextFormField(
                  controller: initialQuantityController,
                  decoration: const InputDecoration(
                    labelText: 'Initial Quantity',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (widget.product == null) {
                      if (value == null ||
                          value.isEmpty ||
                          int.tryParse(value) == null ||
                          int.parse(value) < 0) {
                        return 'Please enter a valid initial quantity.';
                      }
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 24),
              Obx(() {
                return inventoryController.isLoading.value
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: () async {
                          final isValid = _formKey.currentState!.validate();
                          debugPrint('Form validation result: $isValid');
                          debugPrint('Name: ${nameController.text}');
                          debugPrint('Code: ${codeController.text}');
                          debugPrint('Description: ${descriptionController.text}');
                          debugPrint('Merk: ${merkController.text}');
                          debugPrint('Kondisi: ${kondisiController.text}');
                          debugPrint('Tahun Perolehan: ${tahunPerolehanController.text}');
                          debugPrint('Nilai Residu: ${nilaiResiduController.text}');
                          debugPrint('Pengguna: ${penggunaController.text}');
                          debugPrint('Price: ${priceController.text}');

                          if (isValid) {
                            final product = Product(
                              id: widget.product?.id ?? '',
                              name: nameController.text.trim(),
                              code: codeController.text.trim(),
                              description:
                                  descriptionController.text.trim().isEmpty
                                      ? null
                                      : descriptionController.text.trim(),
                              merk: merkController.text.trim().isEmpty
                                  ? null
                                  : merkController.text.trim(),
                              kondisi: kondisiController.text.trim().isEmpty
                                  ? null
                                  : kondisiController.text.trim(),
                              tahunPerolehan:
                                  tahunPerolehanController.text.trim().isEmpty
                                      ? null
                                      : tahunPerolehanController.text.trim(),
                              nilaiResidu: double.tryParse(
                                nilaiResiduController.text.trim(),
                              ),
                              pengguna: penggunaController.text.trim().isEmpty
                                  ? null
                                  : penggunaController.text.trim(),
                              price:
                                  double.tryParse(priceController.text.trim()),
                              createdAt:
                                  widget.product?.createdAt ?? DateTime.now(),
                            );

                            if (widget.product == null) {
                              if (umayumchaHQBranch.value == null) {
                                Get.snackbar(
                                  'Error',
                                  'UmayumchaHQ branch not found. Cannot save product.',
                                );
                                return;
                              }
                              final int initialQuantity = int.parse(
                                initialQuantityController.text.trim(),
                              );

                              final String? newProductId =
                                  await inventoryController
                                      .addProductAndGetId(product);

                              if (newProductId != null) {
                                final transactionSuccess = await inventoryController.addTransaction(
                                  productId: newProductId,
                                  type: 'in',
                                  quantityChange: initialQuantity,
                                  reason: 'Initial stock for new product',
                                  toBranchId: umayumchaHQBranch.value!.id,
                                );
                                if (transactionSuccess) {
                                  Get.back();
                                  Get.snackbar(
                                    'Success',
                                    'Product and initial stock added successfully!',
                                  );
                                } else {
                                  Get.snackbar('Error', 'Failed to add initial stock.');
                                }
                              } else {
                                Get.snackbar('Error', 'Failed to add product.');
                              }
                            } else {
                              final success = await inventoryController.updateProduct(product);
                              if (success) {
                                Get.back();
                                Get.snackbar(
                                  'Success',
                                  'Product updated successfully!',
                                );
                              }
                            }
                          }
                        },
                        child: Text(
                          widget.product == null
                              ? 'Save Product'
                              : 'Update Product',
                        ),
                      );
              }),
              SizedBox(
                height:
                    MediaQuery.of(context).viewInsets.bottom > 0 ? 16.0 : 0.0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
