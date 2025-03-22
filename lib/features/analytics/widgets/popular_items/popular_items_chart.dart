import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/features/analytics/models/analytics_data.dart';
import 'package:food_inventory/features/analytics/widgets/popular_items/summary_metrics.dart';
import 'package:food_inventory/features/analytics/widgets/popular_items/top_sellers_list.dart';

class PopularItemsChart extends StatelessWidget {
  final List<PopularItemData> popularItems;
  final int totalStockCount;

  const PopularItemsChart({
    super.key, 
    required this.popularItems,
    required this.totalStockCount
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (popularItems.isEmpty) {
      return _buildEmptyState(theme);
    }
    
    // Calculate summary statistics
    final totalSales = popularItems.fold(0, (sum, item) => sum + item.salesCount);
    final sortedItems = List<PopularItemData>.from(popularItems)
      ..sort((a, b) => b.salesCount.compareTo(a.salesCount));
    final topItems = sortedItems.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overall Summary Metrics
        SummaryMetrics(
          totalSales: totalSales,
          totalStockCount: totalStockCount,
          uniqueItemsCount: sortedItems.length,
        ),
        
        // Top Sellers Section
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ConfigService.tinyPadding, 
            vertical: ConfigService.mediumPadding
          ),
          child: Text(
            'Top Sellers',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        
        // Top Sellers List
        TopSellersList(
          topItems: topItems,
          totalSales: totalSales,
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: ConfigService.xLargeIconSize,
              color: theme.colorScheme.onSurface.withAlpha(ConfigService.alphaModerate)
            ),
            SizedBox(height: ConfigService.defaultPadding),
            Text(
              'No sales data available',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(ConfigService.alphaDefault),
              ),
            ),
          ],
        ),
      ),
    );
  }
}