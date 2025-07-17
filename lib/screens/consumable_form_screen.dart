
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
  DateTime? _expiredDate;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.consumable?.code ?? '');
    _nameController = TextEditingController(text: widget.consumable?.name ?? '');
    _quantityController = TextEditingController(
        text: widget.consumable?.quantity.toString() ?? '0');
    _expiredDate = widget.consumable?.expiredDate;
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
        title: Text(widget.consumable == null ? 'Add Consumable' : 'Edit Consumable'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: 'Code'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a code';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                enabled: widget.consumable == null, // Disable when editing
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
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(_expiredDate == null
                        ? 'No expiration date chosen!'
                        : 'Expired Date: ${DateFormat.yMd().format(_expiredDate!)}'),
                  ),
                  TextButton(
                    onPressed: () => _selectDate(context),
                    child: const Text('Choose Date'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final newConsumable = Consumable(
                      id: widget.consumable?.id,
                      code: _codeController.text,
                      name: _nameController.text,
                      quantity: widget.consumable?.quantity ?? int.parse(_quantityController.text),
                      expiredDate: _expiredDate,
                    );
                    if (widget.consumable == null) {
                      controller.addConsumable(newConsumable);
                    } else {
                      controller.updateConsumable(newConsumable);
                    }
                  }
                },
                child: Text(widget.consumable == null ? 'Add' : 'Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
