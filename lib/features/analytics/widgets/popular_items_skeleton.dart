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
    
    return SizedBox(
      // height: 550, // Approximate height to match the actual content
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card skeleton that better matches the actual layout
          _buildSummaryCardSkeleton(theme),
          
          // Top Sellers title skeleton
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ConfigService.defaultPadding, 
              vertical: ConfigService.mediumPadding
            ),
            child: Row(
              children: [
                _buildShimmerContainer(width: 120, height: 28),
              ],
            ),
          ),
          
          // Top Sellers list skeleton - match the actual number and spacing
          for (int i = 0; i < 5; i++)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ConfigService.defaultPadding, 
                vertical: ConfigService.smallPadding
              ),
              child: _buildTopSellerItemSkeleton(),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCardSkeleton(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.all(ConfigService.tinyPadding),
      child: Container(
        // width: double.infinity,
        padding: EdgeInsets.all(ConfigService.defaultPadding),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(ConfigService.borderRadiusLarge),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumnSkeleton(theme),
                _buildStatColumnSkeleton(theme),
                _buildStatColumnSkeleton(theme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumnSkeleton(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 24 + ConfigService.mediumPadding * 2, 
          height: 24 + ConfigService.mediumPadding * 2,
          decoration: BoxDecoration(
            color: _colorAnimation.value,
            borderRadius: BorderRadius.circular(ConfigService.mediumPadding),
          ),
        ),
        SizedBox(height: ConfigService.smallPadding),
        _buildShimmerContainer(width: 70, height: 18),
        SizedBox(height: ConfigService.smallPadding),
        _buildShimmerContainer(width: 30, height: 18),
      ],
    );
  }

  Widget _buildTopSellerItemSkeleton() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _colorAnimation.value,
            borderRadius: BorderRadius.circular(ConfigService.borderRadiusMedium),
          ),
        ),
        SizedBox(width: ConfigService.defaultPadding),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShimmerContainer(width: 150, height: 24),
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
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _colorAnimation.value,
        borderRadius: BorderRadius.circular(borderRadius ?? ConfigService.borderRadiusSmall),
      ),
    );
  }
}