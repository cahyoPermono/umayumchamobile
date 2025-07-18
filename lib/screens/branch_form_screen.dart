import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:umayumcha/controllers/branch_controller.dart';
import 'package:umayumcha/models/branch_model.dart';

class BranchFormScreen extends StatefulWidget {
  final Branch? branch;

  const BranchFormScreen({super.key, this.branch});

  @override
  State<BranchFormScreen> createState() => _BranchFormScreenState();
}

class _BranchFormScreenState extends State<BranchFormScreen> {
  final BranchController branchController = Get.find();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.branch?.name ?? '');
    _addressController = TextEditingController(
      text: widget.branch?.address ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.branch == null ? 'Add Branch' : 'Edit Branch'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Branch Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a branch name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final newBranch = Branch(
                      createdAt: DateTime.now(),
                      id: widget.branch!.id,
                      name: _nameController.text,
                      address: _addressController.text,
                    );
                    if (widget.branch == null) {
                      branchController.addBranch(newBranch);
                    } else {
                      branchController.updateBranch(newBranch);
                    }
                  }
                },
                child: Text(widget.branch == null ? 'Add' : 'Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
