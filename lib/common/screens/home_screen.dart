import 'package:flutter/material.dart';
import 'package:food_inventory/features/analytics/screens/analytics_screen.dart';
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
  ];
  
  // Screen icons
  final List<IconData> _screenIcons = [
    Icons.settings,
    Icons.analytics,
    Icons.inventory_2,
    Icons.local_shipping,
  ];

  // Define screens as lazy loading widgets to avoid premature BLoC creation
  final List<Widget Function(BuildContext)> _screenBuilders = [
    (context) => const SettingsScreen(),
    (context) => const AnalyticsScreen(),
    (context) => const InventoryScreen(),
    (context) => const ShipmentsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Set the initial page to Inventory (index 2)
    _currentIndex = 2;
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
              padding: const EdgeInsets.only(top: 20, bottom: 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon for current screen
                  Icon(
                    _screenIcons[_currentIndex],
                    size: 20,
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
                    children: List.generate(4, (index) {
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
              children: [
                _screenBuilders[0](context),
                _screenBuilders[1](context),
                _screenBuilders[2](context),
                _screenBuilders[3](context),
              ],
            ),
          ),
        ],
      ),
    );
  }
}