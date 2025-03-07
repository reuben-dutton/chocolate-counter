import 'package:flutter/material.dart';
import 'package:food_inventory/features/inventory/screens/inventory_screen.dart';
import 'package:food_inventory/features/shipments/screens/shipments_screen.dart';
import 'package:food_inventory/features/settings/screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Define screens as lazy loading widgets to avoid premature BLoC creation
  final List<Widget Function(BuildContext)> _screenBuilders = [
    (context) => const InventoryScreen(),
    (context) => const ShipmentsScreen(),
    (context) => const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      // Use IndexedStack to maintain state when switching tabs
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Build screens only when needed
          _screenBuilders[0](context),
          _currentIndex == 1 ? _screenBuilders[1](context) : Container(),
          _currentIndex == 2 ? _screenBuilders[2](context) : Container(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: theme.colorScheme.surface,
        elevation: 3,
        shadowColor: Colors.black26,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined, color: theme.colorScheme.onSurface.withAlpha(175)),
            selectedIcon: Icon(Icons.inventory_2, color: theme.colorScheme.primary),
            label: 'Inventory',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined, color: theme.colorScheme.onSurface.withAlpha(175)),
            selectedIcon: Icon(Icons.local_shipping, color: theme.colorScheme.primary),
            label: 'Shipments',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, color: theme.colorScheme.onSurface.withAlpha(175)),
            selectedIcon: Icon(Icons.settings, color: theme.colorScheme.primary),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}