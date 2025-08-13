import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:umayumcha_ims/controllers/auth_controller.dart';
import 'package:umayumcha_ims/screens/sign_in_screen.dart';

class CreateNewPasswordScreen extends StatefulWidget {
  const CreateNewPasswordScreen({super.key});

  @override
  State<CreateNewPasswordScreen> createState() =>
      _CreateNewPasswordScreenState();
}

class _CreateNewPasswordScreenState extends State<CreateNewPasswordScreen> {
  final AuthController authController = Get.find();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Password'),
        automaticallyImplyLeading: false, // No back button
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_reset, size: 80),
                const SizedBox(height: 24),
                Text(
                  'Enter Your New Password',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: newPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a new password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value != newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Obx(() {
                  return authController.isLoading.value
                      ? const CircularProgressIndicator()
                      : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              // Update the password first
                              await authController.updatePassword(
                                newPasswordController.text,
                              );

                              // Sign the user out to clear the session
                              await authController.signOut();

                              // Explicitly navigate to SignInScreen and clear navigation stack
                              Get.offAll(() => const SignInScreen());

                              Get.snackbar(
                                'Success',
                                'Password reset successfully. Please sign in again.',
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            }
                          },
                          child: const Text('Save New Password'),
                        ),
                      );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
