import 'package:flutter/material.dart';

/// A widget that shows available swipe directions for gesture-based navigation
class SwipeIndicator extends StatelessWidget {
  final bool enableLeftSwipe;
  final bool enableRightSwipe;
  final bool enableUpSwipe;
  final bool enableDownSwipe;
  final Color color;
  final int opacity;
  final double size;
  final double spacing;
  final String? leftLabel;
  final String? rightLabel;
  final String? upLabel;
  final String? downLabel;
  
  const SwipeIndicator({
    super.key,
    this.enableLeftSwipe = true,
    this.enableRightSwipe = true,
    this.enableUpSwipe = true,
    this.enableDownSwipe = true,
    this.color = Colors.white,
    this.opacity = 175,
    this.size = 5.0,
    this.spacing = 5.0,
    this.leftLabel,
    this.rightLabel,
    this.upLabel,
    this.downLabel,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Up indicator
          if (enableUpSwipe) ...[
            _buildDirectionIndicator(
              context,
              Icons.keyboard_arrow_up,
              upLabel ?? 'Create',
              theme,
            ),
            SizedBox(height: spacing * 2),
          ],
          
          // Horizontal indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Left indicator
              if (enableLeftSwipe) ...[
                _buildDirectionIndicator(
                  context,
                  Icons.keyboard_arrow_left,
                  leftLabel ?? 'Analytics',
                  theme,
                ),
                SizedBox(width: spacing * 4),
              ],
              
              // Center pill (always shown)
              Container(
                width: size * 12,
                height: size,
                decoration: BoxDecoration(
                  color: color.withAlpha(opacity),
                  borderRadius: BorderRadius.circular(size / 2),
                ),
              ),
              
              // Right indicator
              if (enableRightSwipe) ...[
                SizedBox(width: spacing * 4),
                _buildDirectionIndicator(
                  context,
                  Icons.keyboard_arrow_right,
                  rightLabel ?? 'Shipments',
                  theme,
                ),
              ],
            ],
          ),
          
          // Down indicator
          if (enableDownSwipe) ...[
            SizedBox(height: spacing * 2),
            _buildDirectionIndicator(
              context,
              Icons.keyboard_arrow_down,
              downLabel ?? 'Filter',
              theme,
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildDirectionIndicator(
    BuildContext context,
    IconData icon,
    String label,
    ThemeData theme,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color.withAlpha(opacity),
          size: size * 3,
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color.withAlpha(opacity),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

/// A widget that shows a pill indicator for horizontal navigation
class HorizontalSwipeIndicator extends StatelessWidget {
  final int currentIndex;
  final int totalItems;
  final Color activeColor;
  final Color inactiveColor;
  final double height;
  final double width;
  final double spacing;
  
  const HorizontalSwipeIndicator({
    super.key,
    required this.currentIndex,
    required this.totalItems,
    this.activeColor = Colors.white,
    this.inactiveColor = Colors.grey,
    this.height = 4.0,
    this.width = 24.0,
    this.spacing = 8.0,
  });
  
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalItems, (index) {
        final isActive = index == currentIndex;
        return Container(
          margin: EdgeInsets.symmetric(horizontal: spacing / 2),
          width: isActive ? width : width / 2,
          height: height,
          decoration: BoxDecoration(
            color: isActive ? activeColor : inactiveColor.withAlpha(127),
            borderRadius: BorderRadius.circular(height / 2),
          ),
        );
      }),
    );
  }
}

/// A widget that animates to suggest available swipe gestures
class SwipeHintAnimation extends StatefulWidget {
  final Widget child;
  final bool showHint;
  final Duration duration;
  final Axis direction;
  final double distance;
  
  const SwipeHintAnimation({
    super.key,
    required this.child,
    this.showHint = false,
    this.duration = const Duration(seconds: 1),
    this.direction = Axis.horizontal,
    this.distance = 20.0,
  });
  
  @override
  State<SwipeHintAnimation> createState() => _SwipeHintAnimationState();
}

class _SwipeHintAnimationState extends State<SwipeHintAnimation> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    
    // Create animation based on direction
    final Offset begin;
    final Offset end;
    
    if (widget.direction == Axis.horizontal) {
      begin = const Offset(0.0, 0.0);
      end = Offset(widget.distance / 100, 0.0);
    } else {
      begin = const Offset(0.0, 0.0);
      end = Offset(0.0, widget.distance / 100);
    }
    
    _animation = Tween<Offset>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    if (widget.showHint) {
      _startAnimation();
    }
  }
  
  @override
  void didUpdateWidget(SwipeHintAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showHint != oldWidget.showHint) {
      if (widget.showHint) {
        _startAnimation();
      } else {
        _controller.stop();
      }
    }
  }
  
  void _startAnimation() {
    _controller.repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _animation,
      child: widget.child,
    );
  }
}