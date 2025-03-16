import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/features/analytics/models/analytics_data.dart';

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
    
    // Calculate summary statistics
    final totalSales = popularItems.fold(0, (sum, item) => sum + item.salesCount);
    final sortedItems = List<PopularItemData>.from(popularItems)
      ..sort((a, b) => b.salesCount.compareTo(a.salesCount));
    final topItems = sortedItems.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overall Summary
        _buildSummaryCard(context, totalSales, sortedItems, totalStockCount),
        
        // Top Sellers Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ConfigService.defaultPadding, vertical: ConfigService.mediumPadding),
          child: Text(
            'Top Sellers',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        
        // Top Sellers List
        Padding(
          padding: EdgeInsets.zero,
          child: Column(
            children: topItems.map((item) {
              final percentage = (item.salesCount / totalSales * 100).toStringAsFixed(1);
              final index = topItems.indexOf(item);
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: ConfigService.defaultPadding, vertical: ConfigService.smallPadding),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(ConfigService.alphaLight),
                        borderRadius: BorderRadius.circular(ConfigService.borderRadiusMedium),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: ConfigService.defaultPadding),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.itemName,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: ConfigService.tinyPadding),
                          LinearProgressIndicator(
                            value: item.salesCount / topItems.first.salesCount,
                            backgroundColor: theme.colorScheme.surface,
                            color: theme.colorScheme.primary,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(ConfigService.borderRadiusMedium),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: ConfigService.defaultPadding),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${item.salesCount}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Text(
                          '$percentage%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(ConfigService.alphaDefault),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, int totalSales, List<PopularItemData> sortedItems, int totalStockCount) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(ConfigService.tinyPadding),
      child: Container(
        padding: const EdgeInsets.all(ConfigService.defaultPadding),
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
                _buildStatColumn(
                  context,
                  Icons.shopping_cart,
                  'Total Sales',
                  totalSales.toString(),
                ),
                _buildStatColumn(
                  context,
                  Icons.inventory_2,
                  'Total Stock',
                  totalStockCount.toString(),
                ),
                _buildStatColumn(
                  context,
                  Icons.add_chart,
                  'Unique Items',
                  sortedItems.length.toString(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(ConfigService.mediumPadding),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha(ConfigService.alphaLight),
            borderRadius: BorderRadius.circular(ConfigService.mediumPadding),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 24,
          ),
        ),
        const SizedBox(height: ConfigService.smallPadding),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(ConfigService.alphaDefault),
          ),
        ),
        const SizedBox(height: ConfigService.smallPadding),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}