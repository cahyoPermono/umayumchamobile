
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:umayumcha/controllers/consumable_controller.dart';
import 'package:umayumcha/models/consumable_model.dart';

class ConsumableFormScreen extends StatefulWidget {
  final Consumable? consumable;

  const ConsumableFormScreen({super.key, this.consumable});

  @override
  State<ConsumableFormScreen> createState() => _ConsumableFormScreenState();
}

class _ConsumableFormScreenState extends State<ConsumableFormScreen> {
  final ConsumableController controller = Get.find();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _codeController;
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _descriptionController;
  final TextEditingController _locationController = TextEditingController(text: 'UmayumchaHQ');
  DateTime? _expiredDate;
  bool _isSubmitting = false; // New: State variable for submission status

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.consumable?.code ?? '');
    _nameController = TextEditingController(text: widget.consumable?.name ?? '');
    _quantityController =
        TextEditingController(text: widget.consumable?.quantity.toString() ?? '0');
    _descriptionController = TextEditingController(
        text: widget.consumable?.description ?? '');
    _expiredDate = widget.consumable?.expiredDate;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
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
        backgroundColor: Theme.of(context).primaryColor, // Use primary color for app bar
        iconTheme: const IconThemeData(color: Colors.white), // White back button
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0), // Increased padding
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch fields horizontally
            children: [
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Code',
                  hintText: 'e.g., C001',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 15.0),
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
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g., Kopi Bubuk',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 15.0),
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
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  hintText: 'e.g., 100',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 15.0),
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
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'e.g., Kopi robusta kualitas premium',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 15.0),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'e.g., Gudang Utama',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 15.0),
                ),
                enabled: false, // Disabled as requested
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Expiration Date (Optional)',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 15.0),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _expiredDate == null
                        ? 'Choose Expiration Date'
                        : DateFormat.yMd().format(_expiredDate!),
                    style: TextStyle(
                      color: _expiredDate == null ? Colors.grey[700] : Colors.black,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                  onPressed: _isSubmitting ? null : () async { // Disable button when submitting
                    if (_formKey.currentState!.validate()) {
                      setState(() {
                        _isSubmitting = true; // Set submitting state to true
                      });
                      try {
                        final newConsumable = Consumable(
                          id: widget.consumable?.id,
                          code: _codeController.text,
                          name: _nameController.text,
                          quantity: widget.consumable?.quantity ??
                              int.parse(_quantityController.text),
                          description: _descriptionController.text,
                          expiredDate: _expiredDate,
                        );
                        if (widget.consumable == null) {
                          await controller.addConsumable(newConsumable);
                        } else {
                          await controller.updateConsumable(newConsumable);
                        }
                      } finally {
                        setState(() {
                          _isSubmitting = false; // Reset submitting state
                        });
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15.0), // Larger button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0), // Rounded corners
                    ),
                    backgroundColor: Theme.of(context).primaryColor, // Use primary color
                    foregroundColor: Colors.white, // White text
                    elevation: 5, // Add shadow
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          widget.consumable == null ? 'Add' : 'Update',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), // Bold text
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
