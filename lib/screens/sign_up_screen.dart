import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:umayumcha/controllers/auth_controller.dart';
import 'package:umayumcha/controllers/branch_controller.dart'; // Import BranchController
import 'package:umayumcha/models/branch_model.dart'; // Import Branch model

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final AuthController authController = Get.find();
  final BranchController branchController = Get.find();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Branch? selectedBranch; // To hold the selected branch for signup

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo or App Icon
              Image.asset(
                'assets/images/logo2.png',
                height: 120, // Adjust size as needed
              ),
              const SizedBox(height: 16),
              Text(
                'Join Umayumcha',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create your account to get started',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 48),

              // Sign Up Form Card
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      // Branch Selection for Signup
                      Obx(() {
                        if (branchController.isLoading.value) {
                          return const CircularProgressIndicator();
                        }
                        if (branchController.branches.isEmpty) {
                          return const Text(
                            'No branches available. Please add a branch first.',
                          );
                        }
                        return DropdownButtonFormField<Branch>(
                          decoration: const InputDecoration(
                            labelText: 'Assign to Branch',
                          ),
                          value: selectedBranch,
                          onChanged: (Branch? newValue) {
                            setState(() {
                              selectedBranch = newValue;
                            });
                          },
                          items:
                              branchController.branches.map((branch) {
                                return DropdownMenuItem<Branch>(
                                  value: branch,
                                  child: Text(branch.name),
                                );
                              }).toList(),
                        );
                      }),
                      const SizedBox(height: 24),
                      Obx(() {
                        return authController.isLoading.value
                            ? const CircularProgressIndicator()
                            : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (selectedBranch == null) {
                                    Get.snackbar(
                                      'Error',
                                      'Please select a branch.',
                                    );
                                    return;
                                  }
                                  authController.signUp(
                                    email: emailController.text.trim(),
                                    password: passwordController.text.trim(),
                                  );
                                },
                                child: const Text('Sign Up'),
                              ),
                            );
                      }),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Sign In Button
              TextButton(
                onPressed: () {
                  Get.back(); // Go back to Sign In screen
                },
                child: Text.rich(
                  TextSpan(
                    text: "Already have an account? ",
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    children: [
                      TextSpan(
                        text: 'Sign In',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
