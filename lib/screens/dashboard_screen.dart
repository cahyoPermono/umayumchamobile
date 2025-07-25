import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:umayumcha_ims/controllers/auth_controller.dart';
import 'package:umayumcha_ims/screens/consumable_list_screen.dart';
import 'package:umayumcha_ims/screens/inventory_screen.dart';
import 'package:umayumcha_ims/controllers/inventory_controller.dart'; // Import InventoryController
import 'package:umayumcha_ims/controllers/consumable_controller.dart';
import 'package:umayumcha_ims/screens/delivery_note_list_screen.dart';
import 'package:umayumcha_ims/screens/incoming_delivery_note_list_screen.dart'; // New: Import IncomingDeliveryNoteListScreen

import 'package:umayumcha_ims/screens/transaction_log_screen.dart';
import 'package:umayumcha_ims/screens/consumable_transaction_log_screen.dart';
import 'package:umayumcha_ims/screens/user_list_screen.dart';
import 'package:umayumcha_ims/screens/branch_list_screen.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthController authController = Get.find();
  late final InventoryController inventoryController;
  late final ConsumableController consumableController;
  Map<String, dynamic> branch = {};
  final SupabaseClient supabase = Supabase.instance.client;
  String umayumchaHQBranchId = '2e109b1a-12c6-4572-87ab-6c96add8a603';

  @override
  void initState() {
    super.initState();
    inventoryController = Get.find<InventoryController>();
    consumableController = Get.find<ConsumableController>();
    // Ensure data is fetched after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      inventoryController.refreshDashboardData();
      consumableController.fetchConsumables();
    });
    initiateBranch();
  }

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
                    size: 60,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    // 'Welcome, ${authController.currentUser.value?.email ?? 'Guest'}',
                    'Welcome,',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 24,
                    ),
                  ),
                  Obx(
                    () => Text(
                      authController.userRole.value,
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimary.withValues(alpha: 0.8),
                        fontSize: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Inventory Transaction Log'),
              onTap: () {
                Get.back(); // Close the drawer
                Get.to(() => const TransactionLogScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Consumable Transaction Log'),
              onTap: () {
                Get.back(); // Close the drawer
                Get.to(() => ConsumableTransactionLogScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Inventory'),
              onTap: () {
                Get.back(); // Close the drawer
                Get.to(() => const InventoryScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_drink),
              title: const Text('Consumable'),
              onTap: () {
                Get.back(); // Close the drawer
                Get.to(() => ConsumableListScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping),
              title: const Text('Delivery Notes (Out)'),
              onTap: () {
                Get.back(); // Close the drawer
                Get.to(() => const DeliveryNoteListScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping_outlined),
              title: const Text('Delivery Notes (In)'),
              onTap: () {
                Get.back(); // Close the drawer
                Get.to(() => const IncomingDeliveryNoteListScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.store),
              title: const Text('Cabang'),
              onTap: () {
                Get.back(); // Close the drawer
                Get.to(() => BranchListScreen());
              },
            ),
            Obx(
              () =>
                  authController.userRole.value == 'admin'
                      ? ListTile(
                        leading: const Icon(Icons.people),
                        title: const Text('User'),
                        onTap: () {
                          Get.back(); // Close the drawer
                          Get.to(() => UserListScreen());
                        },
                      )
                      : const SizedBox.shrink(),
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
      body: RefreshIndicator(
        onRefresh: () => inventoryController.refreshDashboardData(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Combined Low Stock Warning Section
              Obx(() {
                final lowStockProducts =
                    inventoryController.globalLowStockProducts;
                final lowStockConsumables =
                    consumableController.globalLowStockConsumables;

                if (lowStockProducts.isEmpty && lowStockConsumables.isEmpty) {
                  debugPrint('No low stock inventory or consumables.');
                  return Container();
                }

                final allLowStockItems = <String>[];
                for (var bp in lowStockProducts) {
                  allLowStockItems.add(
                    '${bp.product?.name ?? 'N/A'} (Inventory): ${bp.quantity} left',
                  );
                }
                for (var c in lowStockConsumables) {
                  allLowStockItems.add(
                    '${c.name} (Consumable): ${c.quantity} left',
                  );
                }

                debugPrint(
                  'Combined low stock items: ${allLowStockItems.length}',
                );

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
                                  Theme.of(
                                    context,
                                  ).colorScheme.onErrorContainer,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Low Stock Alert ${branch['name']}!',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onErrorContainer,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, thickness: 1),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 120, // Dynamic height up to 120
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            itemCount: allLowStockItems.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4.0,
                                ),
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
                                        allLowStockItems[index],
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
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Please restock these items soon.',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onErrorContainer
                                .withValues(alpha: 0.8),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),

              // Expiring Consumables Warning Section
              Obx(() {
                if (consumableController.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (consumableController.expiringConsumables.isEmpty) {
                  debugPrint('No expiring consumables.');
                  return Container(); // Changed from SizedBox.shrink()
                }
                debugPrint(
                  'Expiring consumables: ${consumableController.expiringConsumables.length}',
                );
                return Card(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onTertiaryContainer,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Expiring Consumables!',
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onTertiaryContainer,
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
                        SizedBox(
                          height: 120, // Fixed height for scrollable content
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            itemCount:
                                consumableController.expiringConsumables.length,
                            itemBuilder: (context, index) {
                              final c =
                                  consumableController
                                      .expiringConsumables[index];
                              debugPrint(
                                'Processing expiring consumable: ${c.name}',
                              ); // Changed from SizedBox.shrink()
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4.0,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.circle,
                                      size: 10,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onTertiaryContainer
                                          .withValues(alpha: 0.7),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${c.name} (Expires: ${c.expiredDate == null ? 'N/A' : DateFormat.yMd().format(c.expiredDate!)})',
                                        style: TextStyle(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onTertiaryContainer,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'These consumables will expire soon.',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onTertiaryContainer
                                .withValues(alpha: 0.8),
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
                    icon: Icons.local_drink,
                    title: 'Consumables',
                    subtitle: 'Manage consumables',
                    onTap: () => Get.to(() => ConsumableListScreen()),
                  ),
                ],
              ),
            ],
          ),
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

  void initiateBranch() async {
    branch =
        await supabase
            .from('branches')
            .select()
            .eq('id', umayumchaHQBranchId)
            .single();
  }
}
