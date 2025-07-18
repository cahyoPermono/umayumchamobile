
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
            widget.consumable == null ? 'Add Consumable' : 'Edit Consumable'),
        elevation: 4,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _codeController,
                          decoration: const InputDecoration(
                            labelText: 'Code',
                            prefixIcon: Icon(Icons.qr_code),
                            border: OutlineInputBorder(),
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
                            prefixIcon: Icon(Icons.label),
                            border: OutlineInputBorder(),
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
                            prefixIcon: Icon(Icons.format_list_numbered),
                            border: OutlineInputBorder(),
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
                            prefixIcon: Icon(Icons.description),
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            labelText: 'Location',
                            prefixIcon: Icon(Icons.location_on),
                            border: OutlineInputBorder(),
                          ),
                          enabled: false, // Disabled as requested
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey.shade400),
                          ),
                          leading: const Icon(Icons.calendar_today),
                          title: Text(_expiredDate == null
                              ? 'Choose Expiration Date'
                              : DateFormat.yMd().format(_expiredDate!)),
                          trailing: const Icon(Icons.arrow_drop_down),
                          onTap: () => _selectDate(context),
                        ),
                      ],
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          widget.consumable == null ? 'Add' : 'Update',
                          style: const TextStyle(fontSize: 18),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
