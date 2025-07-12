import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:umayumcha/controllers/auth_controller.dart';
import 'package:umayumcha/controllers/home_controller.dart';
import 'package:umayumcha/screens/inventory_screen.dart';
import 'package:umayumcha/screens/delivery_note_list_screen.dart';

class MyHomePage extends StatelessWidget {
  MyHomePage({super.key, required this.title});

  final String title;
  final HomeController homeController = Get.put(HomeController());
  final AuthController authController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authController.signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Obx(() {
                // Display user's email and role
                final user = authController.currentUser.value;
                final role = authController.userRole.value;
                return Column(
                  children: [
                    Text(
                      'Welcome, ${user?.email ?? 'Guest'}!',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your role is: $role',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                );
              }),
              const SizedBox(height: 40),
              // Conditionally show a widget based on the role
              Obx(() {
                if (authController.userRole.value == 'admin') {
                  return Card(
                    color: Colors.amber[100],
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'You see this because you are an ADMIN.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                } else {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'This is the standard view for a regular USER.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
              }),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Get.to(() => const InventoryScreen());
                },
                child: const Text('Go to Inventory'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Get.to(() => const DeliveryNoteListScreen());
                },
                child: const Text('View Delivery Notes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
