import 'package:flutter/material.dart';

/// Helper for navigation with custom transitions
class NavigationUtils {
  /// Navigate to a new screen with a slide from right transition
  static Future<T?> navigateWithSlide<T>(
    BuildContext context,
    Widget destination, {
    bool fullscreenDialog = false,
    bool replace = false,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    final PageRouteBuilder<T> route = PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => destination,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        
        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        final offsetAnimation = animation.drive(tween);
        
        return SlideTransition(
          position: offsetAnimation, 
          child: _SwipeDetector(
            child: child,
            onSwipeRight: () {
              Navigator.of(context).pop();
            },
          ),
        );
      },
      transitionDuration: duration,
      fullscreenDialog: fullscreenDialog,
    );
    
    if (replace) {
      return Navigator.pushReplacement(context, route);
    } else {
      return Navigator.push(context, route);
    }
  }
  
  /// Navigate and remove all previous routes
  static Future<T?> navigateAndRemoveUntil<T>(
    BuildContext context,
    Widget destination, {
    Duration duration = const Duration(milliseconds: 300),
  }) {
    final PageRouteBuilder<T> route = PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => destination,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        
        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        final offsetAnimation = animation.drive(tween);
        
        return SlideTransition(
          position: offsetAnimation, 
          child: _SwipeDetector(
            child: child,
            onSwipeRight: () {
              Navigator.of(context).pop();
            },
          ),
        );
      },
      transitionDuration: duration,
    );
    
    return Navigator.pushAndRemoveUntil(context, route, (route) => false);
  }
  
  /// Pop back to previous screen with a slide to right transition
  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.pop(context, result);
  }
}

/// Widget that detects right swipe gestures
class _SwipeDetector extends StatelessWidget {
  final Widget child;
  final VoidCallback onSwipeRight;
  final double threshold;

  const _SwipeDetector({
    required this.child,
    required this.onSwipeRight,
    this.threshold = 60.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (DragEndDetails details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > threshold) {
          onSwipeRight();
        }
      },
      child: child,
    );
  }
}