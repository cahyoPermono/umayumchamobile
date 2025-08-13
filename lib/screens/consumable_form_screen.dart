import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:umayumcha_ims/controllers/consumable_controller.dart';
import 'package:umayumcha_ims/models/consumable_model.dart';
import 'package:umayumcha_ims/controllers/auth_controller.dart';

class ConsumableFormScreen extends StatefulWidget {
  final Consumable? consumable;

  const ConsumableFormScreen({super.key, this.consumable});

  @override
  State<ConsumableFormScreen> createState() => _ConsumableFormScreenState();
}

class _ConsumableFormScreenState extends State<ConsumableFormScreen> {
  final ConsumableController controller = Get.find();
  final AuthController authController = Get.find(); // ADDED
  final _formKey = GlobalKey<FormState>();
  final SupabaseClient supabase = Supabase.instance.client;

  late TextEditingController _codeController;
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController; // ADDED
  late TextEditingController _lowStockController; // New: Low Stock Controller
  late TextEditingController _fromController; // New: From Controller
  final TextEditingController _locationController = TextEditingController();
  DateTime? _expiredDate;
  bool _isSubmitting = false;
  bool isFinanceUser = false;
  String umayumchaHQBranchId = '2e109b1a-12c6-4572-87ab-6c96add8a603';

  @override
  void initState() {
    super.initState();
    isFinanceUser = authController.userRole.value == 'finance';

    // ADDED: Prevent finance user from accessing the 'add new' form
    if (isFinanceUser && widget.consumable == null) {
      // Use addPostFrameCallback to safely navigate back after the build cycle.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.back();
        Get.snackbar(
          'Access Denied',
          'You do not have permission to create a new consumable.',
          snackPosition: SnackPosition.BOTTOM,
        );
      });
    }

    _codeController = TextEditingController(
      text: widget.consumable?.code ?? '',
    );
    _nameController = TextEditingController(
      text: widget.consumable?.name ?? '',
    );
    _quantityController = TextEditingController(
      text: widget.consumable?.quantity.toString() ?? '0',
    );
    _descriptionController = TextEditingController(
      text: widget.consumable?.description ?? '',
    );
    _priceController = TextEditingController(
      text: widget.consumable?.price?.toString() ?? '',
    );
    _lowStockController = TextEditingController(
      text: widget.consumable?.lowStock.toString() ?? '50',
    );
    _fromController = TextEditingController(
      text: widget.consumable?.from ?? '',
    );
    _expiredDate = widget.consumable?.expiredDate;
    fetchBranch();
  }

  void fetchBranch() async {
    //get branch by id
    final branch =
        await supabase
            .from('branches')
            .select()
            .eq('id', umayumchaHQBranchId)
            .single();

    _locationController.text =
        branch['name'] ?? 'Headquarter'; // Set location to branch name
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    _lowStockController.dispose(); // Dispose low stock controller
    _fromController.dispose(); // Dispose from controller
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiredDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _expiredDate) {
      setState(() {
        _expiredDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.consumable == null ? 'Add Consumable' : 'Edit Consumable',
          style: const TextStyle(color: Colors.white), // Ensure title is white
        ),
        backgroundColor:
            Theme.of(context).primaryColor, // Use primary color for app bar
        iconTheme: const IconThemeData(
          color: Colors.white,
        ), // White back button
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0), // Increased padding
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch, // Stretch fields horizontally
            children: [
              TextFormField(
                readOnly: isFinanceUser,
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Code',
                  hintText: 'e.g., C001',
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
                readOnly: isFinanceUser,
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g., Kopi Bubuk',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 15.0,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                readOnly: isFinanceUser,
                controller: _fromController,
                decoration: const InputDecoration(
                  labelText: 'From (Vendor Name)',
                  hintText: 'e.g., Toko ABC, Supplier XYZ',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 15.0,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter vendor name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  hintText: 'e.g., 100',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 15.0,
                  ),
                ),
                keyboardType: TextInputType.number,
                enabled: widget.consumable == null,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a quantity';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                readOnly: isFinanceUser,
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'e.g., Kopi robusta kualitas premium',
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
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (Optional)',
                  hintText: 'e.g., 25000',
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
                readOnly: isFinanceUser,
                controller: _lowStockController,
                decoration: const InputDecoration(
                  labelText: 'Low Stock Threshold',
                  hintText: 'e.g., 50',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 15.0,
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a low stock threshold';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'e.g., Gudang Utama',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 15.0,
                  ),
                ),
                enabled: false, // Disabled as requested
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: isFinanceUser ? null : () => _selectDate(context), // Make read-only for finance user
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Expiration Date (Optional)',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 15.0,
                    ),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _expiredDate == null
                        ? 'Choose Expiration Date'
                        : DateFormat.yMd().format(_expiredDate!),
                    style: TextStyle(
                      color:
                          _expiredDate == null
                              ? Colors.grey[700]
                              : Colors.black,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed:
                    _isSubmitting
                        ? null
                        : () async {
                          // Disable button when submitting
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              _isSubmitting =
                                  true; // Set submitting state to true
                            });
                            try {
                              final newConsumable = Consumable(
                                id: widget.consumable?.id,
                                code: _codeController.text,
                                name: _nameController.text,
                                quantity:
                                    widget.consumable?.quantity ??
                                    int.parse(_quantityController.text),
                                description: _descriptionController.text,
                                expiredDate: _expiredDate,
                                price: double.tryParse(_priceController.text),
                                lowStock: int.parse(_lowStockController.text),
                                from: _fromController.text, // Save 'from' field
                              );
                              if (widget.consumable == null) {
                                await controller.addConsumable(newConsumable);
                              } else {
                                if (isFinanceUser) {
                                  await controller.updateConsumablePrice(
                                    consumableId: widget.consumable!.id!,
                                    price: double.parse(_priceController.text),
                                  );
                                } else {
                                  await controller.updateConsumable(
                                    newConsumable,
                                  );
                                }
                              }
                            } finally {
                              setState(() {
                                _isSubmitting = false; // Reset submitting state
                              });
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
                child:
                    _isSubmitting
                        ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : Text(
                          widget.consumable == null ? 'Add' : 'Update',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ), // Bold text
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
