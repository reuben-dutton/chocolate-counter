import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/features/analytics/models/stock_trend_data.dart';
import 'package:food_inventory/features/analytics/widgets/stock_trends/stock_metrics.dart';
import 'package:food_inventory/features/analytics/widgets/stock_trends/stock_line_chart.dart';
import 'package:food_inventory/features/analytics/widgets/stock_trends/stock_ratio_display.dart';
import 'package:food_inventory/features/analytics/widgets/stock_trends/stock_insights.dart';

class StockTrendsChart extends StatelessWidget {
  final List<StockTrendData> trendsData;
  final bool isLoading;

  const StockTrendsChart({
    super.key,
    required this.trendsData,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (isLoading) {
      return _buildLoadingSkeleton(theme);
    }
    
    if (trendsData.isEmpty) {
      return _buildEmptyState(theme);
    }
    
    // Calculate summary stats
    final currentStock = trendsData.last.stockCount;
    final currentInventory = trendsData.last.inventoryCount;
    final initialStock = trendsData.first.stockCount;
    final initialInventory = trendsData.first.inventoryCount;
    
    final stockGrowth = initialStock > 0
        ? ((currentStock / initialStock - 1) * 100)
        : 0.0;
    final inventoryGrowth = initialInventory > 0
        ? ((currentInventory / initialInventory - 1) * 100)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary metrics at the top
        StockMetrics(
          currentStock: currentStock,
          currentInventory: currentInventory,
          stockGrowth: stockGrowth,
          inventoryGrowth: inventoryGrowth,
          firstMonthLabel: trendsData.first.month,
        ),
        
        // Main chart
        Padding(
          padding: EdgeInsets.all(ConfigService.defaultPadding),
          child: SizedBox(
            height: 240,
            child: StockLineChart(trendsData: trendsData),
          ),
        ),
        
        // Stock/Inventory Ratio section
        StockRatioDisplay(
          currentStock: currentStock,
          currentInventory: currentInventory,
        ),
        
        // Insights section
        StockInsights(
          trendsData: trendsData,
          stockGrowth: stockGrowth,
          currentInventory: currentInventory,
          currentStock: currentStock,
        ),
      ],
    );
  }
  
  Widget _buildLoadingSkeleton(ThemeData theme) {
    return Column(
      children: [
        // Placeholder for metrics
        Padding(
          padding: EdgeInsets.all(ConfigService.defaultPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(3, (index) => 
              Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(height: ConfigService.smallPadding),
                  Container(
                    width: 80,
                    height: 16,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Placeholder for chart
        Padding(
          padding: EdgeInsets.all(ConfigService.defaultPadding),
          child: Container(
            height: 240,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(ConfigService.borderRadiusMedium),
            ),
          ),
        ),
        
        // Placeholder for ratio
        Padding(
          padding: EdgeInsets.all(ConfigService.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 150,
                height: 24,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(height: ConfigService.smallPadding),
              Container(
                height: 20,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(ConfigService.borderRadiusSmall),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
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
            'No stock trend data available',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(ConfigService.alphaDefault),
            ),
          ),
        ],
      ),
    );
  }
}