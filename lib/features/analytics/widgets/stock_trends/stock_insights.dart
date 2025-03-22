import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/features/analytics/models/stock_trend_data.dart';

class StockInsights extends StatelessWidget {
  final List<StockTrendData> trendsData;
  final double stockGrowth;
  final int currentInventory;
  final int currentStock;

  const StockInsights({
    super.key,
    required this.trendsData,
    required this.stockGrowth,
    required this.currentInventory,
    required this.currentStock,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: EdgeInsets.all(ConfigService.defaultPadding),
      child: Container(
        padding: EdgeInsets.all(ConfigService.defaultPadding),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withAlpha(ConfigService.alphaHigh),
          borderRadius: BorderRadius.circular(ConfigService.borderRadiusMedium),
          border: Border.all(
            color: theme.colorScheme.primary.withAlpha(ConfigService.alphaModerate),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: ConfigService.mediumIconSize,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(width: ConfigService.smallPadding),
                Text(
                  'Insights',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: ConfigService.mediumPadding),
            
            // Insights based on the data
            _buildInsightRow(
              context,
              stockGrowth > 10 
                  ? 'Stock levels have grown significantly (${stockGrowth.toStringAsFixed(1)}%), consider adjusting ordering frequency.'
                  : 'Stock levels are ${stockGrowth >= 0 ? 'stable' : 'declining'}, ${stockGrowth < 0 ? 'check if increased ordering is needed.' : 'maintain current patterns.'}',
            ),
            SizedBox(height: ConfigService.smallPadding),
            _buildInsightRow(
              context,
              currentInventory > currentStock * 2 
                  ? 'High inventory levels detected, consider moving more items to stock.'
                  : 'Inventory to stock ratio is within optimal range.',
            ),
            
            if (_getStockTrend() != 0.0) ...[
              SizedBox(height: ConfigService.smallPadding),
              _buildInsightRow(
                context,
                'Stock levels are ${_getStockTrend() > 0 ? 'trending up' : 'trending down'} over the last ${_getAnalysisMonths()} months.',
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildInsightRow(BuildContext context, String insight) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('•', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(width: ConfigService.smallPadding),
        Expanded(
          child: Text(
            insight,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
  
  // Calculate the trend of stock over the last 3 months (or fewer if not available)
  double _getStockTrend() {
    if (trendsData.length < 2) {
      return 0.0;
    }
    
    final endIndex = trendsData.length - 1;
    final startIndex = trendsData.length >= 4 ? trendsData.length - 4 : 0;
    
    final startValue = trendsData[startIndex].stockCount;
    final endValue = trendsData[endIndex].stockCount;
    
    if (startValue == 0) {
      return 0.0;
    }
    
    return (endValue - startValue) / startValue * 100;
  }
  
  int _getAnalysisMonths() {
    return trendsData.length >= 4 ? 3 : trendsData.length - 1;
  }
}