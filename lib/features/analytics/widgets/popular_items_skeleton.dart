import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';

class PopularItemsSkeleton extends StatefulWidget {
  const PopularItemsSkeleton({super.key});

  @override
  State<PopularItemsSkeleton> createState() => _PopularItemsSkeletonState();
}

class _PopularItemsSkeletonState extends State<PopularItemsSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = Theme.of(context);
    
    // Create animation that transitions between a lighter and darker shade
    _colorAnimation = ColorTween(
      begin: theme.colorScheme.surfaceContainerHigh,
      end: theme.colorScheme.surfaceContainerHighest,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary stats skeleton that matches the new layout
        Padding(
          padding: EdgeInsets.symmetric(
            vertical: ConfigService.largePadding,
            horizontal: ConfigService.defaultPadding
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSimpleStatColumnSkeleton(theme),
              _buildSimpleStatColumnSkeleton(theme),
              _buildSimpleStatColumnSkeleton(theme),
            ],
          ),
        ),
        
        // Top Sellers title skeleton
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ConfigService.tinyPadding, 
            vertical: ConfigService.mediumPadding
          ),
          child: _buildShimmerContainer(width: 120, height: 28),
        ),
        
        // Top Sellers list skeleton - match the actual number and spacing
        for (int i = 0; i < 5; i++)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ConfigService.tinyPadding, 
              vertical: ConfigService.smallPadding
            ),
            child: _buildTopSellerItemSkeleton(),
          ),
      ],
    );
  }

  Widget _buildSimpleStatColumnSkeleton(ThemeData theme) {
    return Column(
      children: [
        _buildShimmerContainer(width: 24, height: 24, isCircular: true),
        SizedBox(height: ConfigService.smallPadding),
        _buildShimmerContainer(width: 70, height: 16),
        SizedBox(height: ConfigService.smallPadding),
        _buildShimmerContainer(width: 30, height: 20),
      ],
    );
  }

  Widget _buildTopSellerItemSkeleton() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: _buildShimmerContainer(width: 20, height: 20, isCircular: true),
        ),
        SizedBox(width: ConfigService.defaultPadding),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShimmerContainer(width: 150, height: 20),
              SizedBox(height: ConfigService.tinyPadding),
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: _colorAnimation.value,
                  borderRadius: BorderRadius.circular(ConfigService.borderRadiusMedium),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: ConfigService.defaultPadding),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildShimmerContainer(width: 40, height: 20),
            SizedBox(height: ConfigService.tinyPadding),
            _buildShimmerContainer(width: 30, height: 14),
          ],
        ),
      ],
    );
  }

  Widget _buildShimmerContainer({
    required double width, 
    required double height,
    double? borderRadius,
    bool isCircular = false,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _colorAnimation.value,
        borderRadius: isCircular 
            ? BorderRadius.circular(height / 2) 
            : BorderRadius.circular(borderRadius ?? ConfigService.borderRadiusSmall),
      ),
    );
  }
}