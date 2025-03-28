// lib/common/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/features/analytics/screens/analytics_screen.dart';
import 'package:food_inventory/features/export/screens/export_screen.dart';
import 'package:food_inventory/features/inventory/screens/inventory_screen.dart';
import 'package:food_inventory/features/shipments/screens/shipments_screen.dart';
import 'package:food_inventory/features/settings/screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 1; // Start with Inventory (center screen)
  late PageController _pageController;
  
  // Screen titles
  final List<String> _screenTitles = [
    'Settings',
    'Analytics',
    'Inventory',
    'Shipments',
    'Export',
  ];

  // Screen icons
  final List<IconData> _screenIcons = [
    Icons.settings,
    Icons.analytics,
    Icons.inventory_2,
    Icons.local_shipping,
    Icons.download_rounded,
  ];

  // Define screens as lazy loading widgets to avoid premature BLoC creation
  final List<Widget> _screenWidgets = [
    const SettingsScreen(),
    const AnalyticsScreen(),
    const InventoryScreen(),
    const ShipmentsScreen(),
    const ExportScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Set the initial page to Inventory (index 2)
    _currentIndex = 2;
    _pageController = PageController(initialPage: _currentIndex, viewportFraction: 1);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Column(
        children: [
          // Horizontal indicator with title and icon
          SafeArea(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 16, bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon for current screen
                  Icon(
                    _screenIcons[_currentIndex],
                    size: ConfigService.defaultIconSize,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  // Screen title
                  Text(
                    _screenTitles[_currentIndex],
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Page indicator dots
                  Row(
                    children: List.generate(5, (index) {
                      return Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index == _currentIndex 
                              ? theme.colorScheme.primary 
                              : theme.colorScheme.surfaceContainerHighest,
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          
          // Main content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: _screenWidgets,
            ),
          ),
        ],
      ),
    );
  }
}