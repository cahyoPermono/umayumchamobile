import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:umayumcha_ims/controllers/auth_controller.dart';
import 'package:umayumcha_ims/controllers/branch_controller.dart';
import 'package:umayumcha_ims/models/branch_model.dart';

class BranchFormScreen extends StatefulWidget {
  final Branch? branch;

  const BranchFormScreen({super.key, this.branch});

  @override
  State<BranchFormScreen> createState() => _BranchFormScreenState();
}

class _BranchFormScreenState extends State<BranchFormScreen> {
  final BranchController branchController = Get.find();
  final AuthController authController = Get.find();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late bool _isReadOnly;

  @override
  void initState() {
    super.initState();
    // Users with the 'finance' role have read-only access.
    _isReadOnly = authController.userRole.value == 'finance';

    // If a finance user tries to open the form for a new branch, deny access.
    if (_isReadOnly && widget.branch == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.back();
        Get.snackbar(
          'Access Denied',
          'You do not have permission to create a new branch.',
          snackPosition: SnackPosition.BOTTOM,
        );
      });
    }

    _nameController = TextEditingController(text: widget.branch?.name ?? '');
    _addressController = TextEditingController(
      text: widget.branch?.address ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.branch == null
              ? 'Add Branch'
              : _isReadOnly
              ? 'Branch Details'
              : 'Edit Branch',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                readOnly:
                    _isReadOnly ||
                    widget.branch?.id == '2e109b1a-12c6-4572-87ab-6c96add8a603',
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
                readOnly: _isReadOnly,
                decoration: const InputDecoration(labelText: 'Address'),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              if (!_isReadOnly)
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      if (widget.branch == null) {
                        // Create new branch without an ID
                        final newBranch = Branch(
                          name: _nameController.text,
                          address: _addressController.text,
                          createdAt: DateTime.now(),
                        );
                        branchController.addBranch(newBranch);
                      } else {
                        // Update existing branch with its ID
                        final updatedBranch = Branch(
                          id: widget.branch!.id,
                          name: _nameController.text,
                          address: _addressController.text,
                          createdAt: widget.branch!.createdAt,
                        );
                        branchController.updateBranch(updatedBranch);
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
