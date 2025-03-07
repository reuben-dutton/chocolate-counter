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
  PageController _pageController = PageController(); // Initialize here

  // Define screens as lazy loading widgets to avoid premature BLoC creation
  final List<Widget Function(BuildContext)> _screenBuilders = [
    (context) => const InventoryScreen(),
    (context) => const ShipmentsScreen(),
    (context) => const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Set the initial page
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onTabTapped(int index) {
    // Animate to the selected page when tab is tapped
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          _screenBuilders[0](context),
          _screenBuilders[1](context),
          _screenBuilders[2](context),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabTapped,
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