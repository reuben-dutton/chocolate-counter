import 'package:flutter/material.dart';

enum SwipeDirection { left, right, up, down }
enum SwipeType { short, long }

/// A class that handles gesture detection and provides standard behavior
/// for the app's gesture-based navigation.
class GestureHandler {
  /// Duration for determining if a swipe is long or short
  static const longSwipeDuration = Duration(milliseconds: 300);
  
  /// Distance threshold for a swipe to be considered a navigation action
  static const double navigationThreshold = 80.0;
  
  /// Distance threshold for a swipe to be considered a preview
  static const double previewThreshold = 20.0;
  
  /// Velocity threshold for swipes
  static const double velocityThreshold = 300.0;
  
  /// Edge zone width for back gesture detection
  static const double edgeZoneWidth = 20.0;
  
  /// Callback for handling navigation swipes
  final Function(SwipeDirection direction)? onNavigationSwipe;
  
  /// Callback for handling create actions (swipe up)
  final VoidCallback? onCreateAction;
  
  /// Callback for handling filter/search actions (short swipe down)
  final VoidCallback? onFilterAction;
  
  /// Callback for handling settings action (long swipe down)
  final VoidCallback? onSettingsAction;
  
  /// Callback for preview updates during a horizontal swipe
  final Function(double previewPercent, SwipeDirection direction)? onPreviewUpdate;
  
  /// Callback for when a swipe is canceled
  final VoidCallback? onSwipeCancel;
  
  // State for tracking horizontal gestures
  DateTime? _horizontalDragStartTime;
  double _horizontalDragDistance = 0.0;
  Offset _horizontalDragStartPosition = Offset.zero;
  
  // State for tracking vertical gestures
  DateTime? _verticalDragStartTime;
  double _verticalDragDistance = 0.0;
  
  /// Constructor - not const since we have non-final instance fields
  GestureHandler({
    this.onNavigationSwipe,
    this.onCreateAction,
    this.onFilterAction,
    this.onSettingsAction,
    this.onPreviewUpdate,
    this.onSwipeCancel,
  });
  
  /// Wraps a widget with standard gesture detection
  Widget wrapWithGestures(
    BuildContext context, 
    Widget child, {
    bool enableHorizontalSwipe = true,
    bool enableVerticalSwipe = true,
  }) {
    return GestureDetector(
      onVerticalDragStart: !enableVerticalSwipe ? null : _handleVerticalDragStart,
      onVerticalDragUpdate: !enableVerticalSwipe ? null : _handleVerticalDragUpdate,
      onVerticalDragEnd: !enableVerticalSwipe ? null : _handleVerticalDragEnd,
      onHorizontalDragStart: !enableHorizontalSwipe ? null : _handleHorizontalDragStart,
      onHorizontalDragUpdate: !enableHorizontalSwipe ? null : _handleHorizontalDragUpdate,
      onHorizontalDragEnd: !enableHorizontalSwipe ? null : _handleHorizontalDragEnd,
      onHorizontalDragCancel: () {
        _resetHorizontalState();
        onSwipeCancel?.call();
      },
      onVerticalDragCancel: () {
        _resetVerticalState();
        onSwipeCancel?.call();
      },
      child: child,
    );
  }
  
  // Reset state
  void _resetHorizontalState() {
    _horizontalDragStartTime = null;
    _horizontalDragDistance = 0.0;
    _horizontalDragStartPosition = Offset.zero;
  }
  
  void _resetVerticalState() {
    _verticalDragStartTime = null;
    _verticalDragDistance = 0.0;
  }
  
  // Handle horizontal drag (for navigation)
  void _handleHorizontalDragStart(DragStartDetails details) {
    _horizontalDragStartTime = DateTime.now();
    _horizontalDragDistance = 0.0;
    _horizontalDragStartPosition = details.globalPosition;
  }
  
  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    _horizontalDragDistance += details.delta.dx;
    
    // Provide preview updates
    if (onPreviewUpdate != null) {
      double previewPercent = _horizontalDragDistance.abs() / navigationThreshold;
      previewPercent = previewPercent.clamp(0.0, 1.0);
      
      SwipeDirection direction = _horizontalDragDistance > 0 
          ? SwipeDirection.right 
          : SwipeDirection.left;
      
      onPreviewUpdate!(previewPercent, direction);
    }
  }
  
  void _handleHorizontalDragEnd(DragEndDetails details) {
    // Determine if the swipe is enough for navigation
    if (_horizontalDragDistance.abs() >= navigationThreshold) {
      final direction = _horizontalDragDistance > 0 
          ? SwipeDirection.right 
          : SwipeDirection.left;
      
      onNavigationSwipe?.call(direction);
    } else {
      // Reset preview if we're not navigating
      if (onPreviewUpdate != null) {
        onPreviewUpdate!(0.0, SwipeDirection.left);
      }
      onSwipeCancel?.call();
    }
    
    _resetHorizontalState();
  }
  
  // Handle vertical drag (for actions)
  void _handleVerticalDragStart(DragStartDetails details) {
    _verticalDragStartTime = DateTime.now();
    _verticalDragDistance = 0.0;
  }
  
  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    _verticalDragDistance += details.delta.dy;
  }
  
  void _handleVerticalDragEnd(DragEndDetails details) {
    final now = DateTime.now();
    final dragDuration = now.difference(_verticalDragStartTime!);
    
    // For vertical gestures, we care about both duration and distance
    if (_verticalDragDistance.abs() >= navigationThreshold) {
      if (_verticalDragDistance < 0) {
        // Swipe up - Create action
        onCreateAction?.call();
      } else {
        // Swipe down - Filter or Settings
        final swipeType = dragDuration > longSwipeDuration 
            ? SwipeType.long 
            : SwipeType.short;
        
        if (swipeType == SwipeType.long) {
          onSettingsAction?.call();
        } else {
          onFilterAction?.call();
        }
      }
    } else {
      onSwipeCancel?.call();
    }
    
    _resetVerticalState();
  }
  
  /// Creates a back navigation gesture detector for detail screens
  static Widget wrapWithBackGesture(
    BuildContext context, 
    Widget child, {
    VoidCallback? onBack,
  }) {
    return GestureDetector(
      onHorizontalDragStart: (details) {
        // Only detect swipes starting from left edge
        if (details.globalPosition.dx > edgeZoneWidth) {
          // Cancel the gesture if not starting from left edge
          return;
        }
      },
      onHorizontalDragEnd: (details) {
        // Check both velocity and distance for better reliability
        // A back gesture should be a right swipe starting from left edge
        if (details.primaryVelocity != null && 
            details.primaryVelocity! > velocityThreshold) {
          if (onBack != null) {
            onBack();
          } else {
            Navigator.of(context).pop();
          }
        }
      },
      child: child,
    );
  }
  
  /// Handle long press to show contextual menu
  static Future<void> showContextMenu(
    BuildContext context, 
    Offset position, 
    List<PopupMenuEntry<dynamic>> items
  ) async {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
    return showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(
          position,
          position,
        ),
        Offset.zero & overlay.size,
      ),
      items: items,
    );
  }
}