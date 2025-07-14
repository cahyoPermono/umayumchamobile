import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:umayumcha/controllers/auth_controller.dart';
import 'package:umayumcha/screens/inventory_screen.dart';
import 'package:umayumcha/controllers/inventory_controller.dart'; // Import InventoryController
import 'package:umayumcha/screens/delivery_note_list_screen.dart';
import 'package:umayumcha/screens/product_form_screen.dart';
import 'package:umayumcha/screens/delivery_note_form_screen.dart';
import 'package:umayumcha/screens/transaction_log_screen.dart';

class DashboardScreen extends StatelessWidget {
  DashboardScreen({super.key});

  final AuthController authController = Get.find();
  final InventoryController inventoryController =
      Get.find(); // Get InventoryController

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Umayumcha Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.fastfood,
                    size: 50,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  const SizedBox(height: 8),
                  Obx(
                    () => Text(
                      'Welcome, ${authController.currentUser.value?.email ?? 'Guest'}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Obx(
                    () => Text(
                      'Role: ${authController.userRole.value}',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimary.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Master Inventory'),
              onTap: () {
                Get.back(); // Close the drawer
                Get.to(() => const InventoryScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping),
              title: const Text('Delivery Notes'),
              onTap: () {
                Get.back(); // Close the drawer
                Get.to(() => const DeliveryNoteListScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Transaction Log'),
              onTap: () {
                Get.back(); // Close the drawer
                Get.to(() => const TransactionLogScreen());
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Get.back(); // Close the drawer
                authController.signOut();
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Welcome Section
            Obx(() {
              final user = authController.currentUser.value;
              final role = authController.userRole.value;
              return Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${user?.email?.split('@').first ?? 'User'}!',
                          style: Theme.of(
                            context,
                          ).textTheme.headlineSmall?.copyWith(
                            color:
                                Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your role: $role',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer
                                .withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Manage your dimsum business efficiently.',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(
                            color:
                                Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),

            // Low Stock Warning Section
            Obx(() {
              if (inventoryController.globalLowStockProducts.isEmpty) {
                return const SizedBox.shrink();
              }
              return Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_rounded,
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Low Stock Alert!',
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onErrorContainer,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(
                        height: 1,
                        thickness: 1,
                      ), // Visual separator
                      const SizedBox(height: 12),
                      ...inventoryController.globalLowStockProducts.map(
                        (bp) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 10,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer
                                    .withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${bp.product?.name ?? 'N/A'} (${bp.branchName ?? 'N/A'}): ${bp.quantity} left',
                                  style: TextStyle(
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onErrorContainer,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Please restock these items soon.',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onErrorContainer.withValues(alpha: 0.8),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),

            // Quick Actions Section
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildDashboardCard(
                  context,
                  icon: Icons.inventory,
                  title: 'Inventory',
                  subtitle: 'Manage products',
                  onTap: () => Get.to(() => const InventoryScreen()),
                ),
                _buildDashboardCard(
                  context,
                  icon: Icons.local_shipping,
                  title: 'Delivery Notes',
                  subtitle: 'Track shipments',
                  onTap: () => Get.to(() => const DeliveryNoteListScreen()),
                ),
                _buildDashboardCard(
                  context,
                  icon: Icons.add_box,
                  title: 'Add New Product',
                  subtitle: 'For admins only',
                  onTap: () {
                    if (authController.userRole.value == 'admin') {
                      Get.to(() => const ProductFormScreen());
                    } else {
                      Get.snackbar(
                        'Access Denied',
                        'Only admins can add products.',
                      );
                    }
                  },
                ),
                _buildDashboardCard(
                  context,
                  icon: Icons.receipt,
                  title: 'New Delivery Note',
                  subtitle: 'Create a new order',
                  onTap: () => Get.to(() => const DeliveryNoteFormScreen()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
