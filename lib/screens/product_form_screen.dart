import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:umayumcha_ims/controllers/inventory_controller.dart';
import 'package:umayumcha_ims/controllers/branch_controller.dart'; // Import BranchController
import 'package:umayumcha_ims/models/product_model.dart';
import 'package:umayumcha_ims/models/branch_model.dart'; // Import Branch model

class ProductFormScreen extends StatefulWidget {
  final Product? product;
  final String? locationName;
  const ProductFormScreen({super.key, this.product, this.locationName});

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

  bool _showOptionalFields = false; // New state variable

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

    if (widget.product == null) {
      initialQuantityController.text = '1';
    } else {
      // If editing an existing product, check if any optional fields have data
      if (widget.product!.merk != null ||
          widget.product!.kondisi != null ||
          widget.product!.tahunPerolehan != null ||
          widget.product!.nilaiResidu != null ||
          widget.product!.pengguna != null ||
          widget.product!.price != null) {
        _showOptionalFields = true;
      }
    }

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
          style: const TextStyle(color: Colors.white), // Ensure title is white
        ),
        backgroundColor:
            Theme.of(context).primaryColor, // Use primary color for app bar
        iconTheme: const IconThemeData(
          color: Colors.white,
        ), // White back button
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(
          20.0,
        ), // Increased padding for more breathing room
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch, // Stretch fields horizontally
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  hintText: 'e.g., Dimsum Ayam',
                  border: OutlineInputBorder(), // Clean outline border
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 15.0,
                  ),
                ),
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
                decoration: const InputDecoration(
                  labelText: 'Code (Required)',
                  hintText: 'e.g., DM001',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 15.0,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: kondisiController,
                decoration: const InputDecoration(
                  labelText: 'Kondisi (Required)',
                  hintText: 'e.g., Baik, Rusak',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 15.0,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a condition';
                  }
                  return null;
                },
              ),
              if (widget.product != null && widget.locationName != null) ...[
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: widget.locationName,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 15.0,
                    ),
                  ),
                  enabled: false,
                ),
              ],
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Show Optional Fields'),
                value: _showOptionalFields,
                onChanged: (bool value) {
                  setState(() {
                    _showOptionalFields = value;
                  });
                },
                contentPadding: EdgeInsets.zero, // Remove default padding
              ),
              if (_showOptionalFields) ...[
                TextFormField(
                  controller: merkController,
                  decoration: const InputDecoration(
                    labelText: 'Merk (Optional)',
                    hintText: 'e.g., ABC Food',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 15.0,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'e.g., Dimsum dengan isian daging ayam cincang',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 15.0,
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: tahunPerolehanController,
                  decoration: const InputDecoration(
                    labelText: 'Tahun Perolehan (Optional)',
                    hintText: 'e.g., 2023',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 15.0,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nilaiResiduController,
                  decoration: const InputDecoration(
                    labelText: 'Nilai Residu (Optional)',
                    hintText: 'e.g., 50000',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 15.0,
                    ),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: penggunaController,
                  decoration: const InputDecoration(
                    labelText: 'Pengguna (Optional)',
                    hintText: 'e.g., Departemen Produksi',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 15.0,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price (Optional)',
                    hintText: 'e.g., 15000.00',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 15.0,
                    ),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ],
              const SizedBox(height: 16),
              if (widget.product == null) ...[
                const SizedBox(
                  height: 24,
                ), // More space before initial quantity section
                Obx(() {
                  if (branchController.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    ); // Center loading indicator
                  }
                  final branchName =
                      umayumchaHQBranch.value?.name ?? 'Loading...';
                  return AbsorbPointer(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Location',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12.0,
                          horizontal: 15.0,
                        ),
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
                    hintText: 'e.g., 100',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 15.0,
                    ),
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
              const SizedBox(height: 30), // More space before the button
              Obx(() {
                return inventoryController.isLoading.value
                    ? const Center(
                      child: CircularProgressIndicator(),
                    ) // Center loading indicator
                    : ElevatedButton(
                      onPressed: () async {
                        final isValid = _formKey.currentState!.validate();
                        debugPrint('Form validation result: $isValid');
                        debugPrint('Name: ${nameController.text}');
                        debugPrint('Code: ${codeController.text}');
                        debugPrint(
                          'Description: ${descriptionController.text}',
                        );
                        debugPrint('Merk: ${merkController.text}');
                        debugPrint('Kondisi: ${kondisiController.text}');
                        debugPrint(
                          'Tahun Perolehan: ${tahunPerolehanController.text}',
                        );
                        debugPrint(
                          'Nilai Residu: ${nilaiResiduController.text}',
                        );
                        debugPrint('Pengguna: ${penggunaController.text}');
                        debugPrint('Price: ${priceController.text}');

                        if (isValid) {
                          final product = Product(
                            id: widget.product?.id, // Now nullable
                            name: nameController.text.trim(),
                            code: codeController.text.trim(),
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
                                await inventoryController.addProductAndGetId(
                                  product,
                                );

                            if (newProductId != null) {
                              final transactionSuccess =
                                  await inventoryController.addTransaction(
                                    productId: newProductId,
                                    type: 'in',
                                    quantityChange: initialQuantity,
                                    reason: 'Initial stock for new product',
                                    toBranchId: umayumchaHQBranch.value!.id,
                                    toBranchName:
                                        'UmayumchaHQ', // Set destination name
                                  );
                              if (transactionSuccess) {
                                Get.back();
                                Get.snackbar(
                                  'Success',
                                  'Product and initial stock added successfully!',
                                );
                              } else {
                                Get.snackbar(
                                  'Error',
                                  'Failed to add initial stock.',
                                );
                              }
                            } else {
                              Get.snackbar('Error', 'Failed to add product.');
                            }
                          } else {
                            final success = await inventoryController
                                .updateProduct(product);
                            if (success) {
                              Get.back();
                              Get.snackbar(
                                'Success',
                                'Product updated successfully!',
                              );
                            } else {
                              Get.snackbar(
                                'Error',
                                'Failed to update product.',
                                margin: EdgeInsets.all(10),
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                              );
                            }
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 15.0,
                        ), // Larger button
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            10.0,
                          ), // Rounded corners
                        ),
                        backgroundColor:
                            Theme.of(context).primaryColor, // Use primary color
                        foregroundColor: Colors.white, // White text
                        elevation: 5, // Add shadow
                      ),
                      child: Text(
                        widget.product == null
                            ? 'Save Product'
                            : 'Update Product',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ), // Bold text
                      ),
                    );
              }),
              SizedBox(
                height:
                    MediaQuery.of(context).viewInsets.bottom > 0
                        ? 20.0
                        : 0.0, // Adjust space for keyboard
              ),
            ],
          ),
        ),
      ),
    );
  }
}
