import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/features/analytics/models/analytics_data.dart';

class PopularItemsChart extends StatelessWidget {
  final List<PopularItemData> popularItems;

  const PopularItemsChart({
    super.key, 
    required this.popularItems
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (popularItems.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart_outlined,
                size: 48,
                color: theme.colorScheme.onSurface.withAlpha(100),
              ),
              const SizedBox(height: 16),
              Text(
                'No sales data available yet',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(150),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Sort items by sales count
    final sortedItems = List<PopularItemData>.from(popularItems)
      ..sort((a, b) => b.salesCount.compareTo(a.salesCount));
    
    // Take top 5 items for better visualization
    final topItems = sortedItems.take(10).toList();
    
    // Calculate total for percentage
    final total = topItems.fold<int>(
      0, (sum, item) => sum + item.salesCount
    );
    
    // Use theme colors
    final List<Color> chartColors = [
      theme.colorScheme.primary,
      theme.colorScheme.tertiary, 
      theme.colorScheme.secondary,
      theme.colorScheme.primaryContainer,
      theme.colorScheme.tertiaryContainer,
      theme.colorScheme.secondaryContainer,
    ];
    
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 30,
              sections: List.generate(topItems.length, (index) {
                final item = topItems[index];
                final percentage = (item.salesCount / total) * 100;
                return PieChartSectionData(
                  color: chartColors[index % chartColors.length],
                  value: item.salesCount.toDouble(),
                  title: '${percentage.toStringAsFixed(1)}%',
                  radius: 90,
                  titleStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimary,
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: ConfigService.defaultPadding),
        // Legend
        ...List.generate(topItems.length, (index) {
          final item = topItems[index];
          return Padding(
            padding: const EdgeInsets.symmetric(
              vertical: ConfigService.smallPadding,
              horizontal: ConfigService.smallPadding,
            ),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: chartColors[index % chartColors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.itemName,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Text(
                  '${item.salesCount}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}