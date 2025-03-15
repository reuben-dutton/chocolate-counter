import 'package:flutter/material.dart';
import 'package:food_inventory/common/utils/gesture_handler.dart';
import 'package:food_inventory/common/utils/navigation_utils.dart';
import 'package:food_inventory/common/widgets/swipe_indicator.dart';
import 'package:food_inventory/features/analytics/screens/analytics_screen.dart';
import 'package:food_inventory/features/inventory/screens/add_item_definition_screen.dart';
import 'package:food_inventory/features/inventory/screens/inventory_screen.dart';
import 'package:food_inventory/features/settings/screens/settings_screen.dart';
import 'package:food_inventory/features/shipments/screens/add_shipment_screen.dart';
import 'package:food_inventory/features/shipments/screens/shipments_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  // Current page index (0: Inventory, 1: Analytics, 2: Shipments)
  int _currentIndex = 1;
  late PageController _pageController;
  
  // Preview animation controller for partial swipes
  late AnimationController _previewController;
  SwipeDirection? _previewDirection;
  
  // Define screens as lazy loading widgets to avoid premature BLoC creation
  final List<Widget Function(BuildContext)> _screenBuilders = [
    (context) => const AnalyticsScreen(), // Index 0: Analytics (left)
    (context) => const InventoryScreen(),  // Index 1: Inventory (center/home)
    (context) => const ShipmentsScreen(),  // Index 2: Shipments (right)
  ];
  
  // Screen labels for indicators
  final List<String> _screenLabels = [
    'Analytics',
    'Inventory',
    'Shipments',
  ];

  @override
  void initState() {
    super.initState();
    // Set the initial page to Inventory (center/home)
    _pageController = PageController(initialPage: _currentIndex);
    
    // Initialize preview animation controller
    _previewController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _previewController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
  
  // Method to handle swipe gestures for navigation
  void _handleNavigationSwipe(SwipeDirection direction) {
    if (direction == SwipeDirection.left) {
      // Navigate right in the PageView (index increases)
      if (_currentIndex < _screenBuilders.length - 1) {
        _pageController.animateToPage(
          _currentIndex + 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else if (direction == SwipeDirection.right) {
      // Navigate left in the PageView (index decreases)
      if (_currentIndex > 0) {
        _pageController.animateToPage(
          _currentIndex - 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }
  
  // Handle preview updates for partial swipes
  void _handlePreviewUpdate(double previewPercent, SwipeDirection direction) {
    setState(() {
      _previewDirection = direction;
    });
    
    if (previewPercent > 0) {
      _previewController.value = previewPercent;
    } else {
      _previewController.value = 0.0;
    }
  }
  
  // Handle swipe up for creation actions
  void _handleCreateAction() {
    switch (_currentIndex) {
      case 0: // Analytics - Create custom report/view
        // Analytics creation action
        _showNotImplementedMessage('Create Custom Report');
      case 1: // Inventory - Create new item definition
        NavigationUtils.navigateWithSlide(
          context,
          const AddItemDefinitionScreen(),
        );
      case 2: // Shipments - Create new shipment
        NavigationUtils.navigateWithSlide(
          context,
          const AddShipmentScreen(),
        );
    }
  }
  
  // Handle short swipe down for filter/search
  void _handleFilterAction() {
    switch (_currentIndex) {
      case 0: // Analytics - Filter analytics
        _showNotImplementedMessage('Filter Analytics');
      case 1: // Inventory - Search/filter items
        _showNotImplementedMessage('Search Items');
      case 2: // Shipments - Filter shipments
        _showNotImplementedMessage('Filter Shipments');
    }
  }
  
  // Handle long swipe down for settings
  void _handleSettingsAction() {
    NavigationUtils.navigateWithSlide(
      context,
      const SettingsScreen(),
    );
  }
  
  // Show temporary message for unimplemented features
  void _showNotImplementedMessage(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Create the gesture handler
    final gestureHandler = GestureHandler(
      onNavigationSwipe: _handleNavigationSwipe,
      onCreateAction: _handleCreateAction,
      onFilterAction: _handleFilterAction,
      onSettingsAction: _handleSettingsAction,
      onPreviewUpdate: _handlePreviewUpdate,
    );

    return Scaffold(
      // Page view with the main screens
      body: Stack(
        children: [
          // Preview animation for left screen if needed
          if (_previewDirection == SwipeDirection.right && _currentIndex > 0)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _previewController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _previewController.value * 0.5,
                    child: _screenBuilders[_currentIndex - 1](context),
                  );
                },
              ),
            ),
            
          // Preview animation for right screen if needed
          if (_previewDirection == SwipeDirection.left && _currentIndex < _screenBuilders.length - 1)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _previewController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _previewController.value * 0.5,
                    child: _screenBuilders[_currentIndex + 1](context),
                  );
                },
              ),
            ),
            
          // Main PageView
          gestureHandler.wrapWithGestures(
            context,
            PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: [
                _screenBuilders[0](context),
                _screenBuilders[1](context),
                _screenBuilders[2](context),
              ],
            ),
          ),
          
          // Bottom swipe indicator
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Horizontal page indicator
                HorizontalSwipeIndicator(
                  currentIndex: _currentIndex,
                  totalItems: _screenBuilders.length,
                  activeColor: theme.colorScheme.primary,
                  inactiveColor: theme.colorScheme.onSurface.withAlpha(75),
                ),
                
                // Gesture indicators
                SwipeIndicator(
                  enableLeftSwipe: _currentIndex < _screenBuilders.length - 1,
                  enableRightSwipe: _currentIndex > 0,
                  color: theme.colorScheme.onSurface,
                  leftLabel: _currentIndex < _screenBuilders.length - 1 
                      ? _screenLabels[_currentIndex + 1] 
                      : null,
                  rightLabel: _currentIndex > 0 
                      ? _screenLabels[_currentIndex - 1] 
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}