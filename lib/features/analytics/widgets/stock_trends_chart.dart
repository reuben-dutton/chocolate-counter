import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/features/analytics/models/stock_trend_data.dart';

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
        Padding(
          padding: EdgeInsets.symmetric(
            vertical: ConfigService.largePadding,
            horizontal: ConfigService.defaultPadding
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricColumn(
                context,
                Icons.shopping_cart,
                'Current Stock',
                currentStock.toString(),
                stockGrowth,
                '${trendsData.first.month} to now',
              ),
              _buildMetricColumn(
                context,
                Icons.inventory_2,
                'Current Inventory',
                currentInventory.toString(),
                inventoryGrowth,
                '${trendsData.first.month} to now',
              ),
              _buildMetricColumn(
                context,
                Icons.donut_large,
                'Total Items',
                (currentStock + currentInventory).toString(),
                null,
                'Combined total',
              ),
            ],
          ),
        ),
        
        // Main chart
        Padding(
          padding: EdgeInsets.all(ConfigService.defaultPadding),
          child: SizedBox(
            height: 240,
            child: LineChart(
              _createLineChartData(theme),
            ),
          ),
        ),
        
        // Stock/Inventory Ratio section
        Padding(
          padding: EdgeInsets.all(ConfigService.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stock-to-Inventory Ratio',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              SizedBox(height: ConfigService.smallPadding),
              
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(ConfigService.borderRadiusSmall),
                child: LinearProgressIndicator(
                  value: currentStock / (currentStock + currentInventory),
                  backgroundColor: theme.colorScheme.primary.withAlpha(ConfigService.alphaLight),
                  color: theme.colorScheme.primary,
                  minHeight: 20,
                ),
              ),
              
              // Labels
              Padding(
                padding: EdgeInsets.symmetric(vertical: ConfigService.smallPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Stock: ${(currentStock / (currentStock + currentInventory) * 100).toStringAsFixed(1)}%',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      'Inventory: ${(currentInventory / (currentStock + currentInventory) * 100).toStringAsFixed(1)}%',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Insights section
        Padding(
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
  
  Widget _buildMetricColumn(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    double? percentChange,
    String subLabel,
  ) {
    final theme = Theme.of(context);
    final isGrowthPositive = percentChange != null && percentChange >= 0;
    
    return Column(
      children: [
        Icon(
          icon, 
          size: ConfigService.largeIconSize, 
          color: theme.colorScheme.primary
        ),
        SizedBox(height: ConfigService.smallPadding),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(ConfigService.alphaHigh),
          ),
        ),
        SizedBox(height: ConfigService.tinyPadding),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        if (percentChange != null) ...[
          SizedBox(height: ConfigService.tinyPadding),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isGrowthPositive ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
                color: isGrowthPositive ? Colors.green : Colors.red,
              ),
              SizedBox(width: 2),
              Text(
                '${percentChange.abs().toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: isGrowthPositive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
        SizedBox(height: ConfigService.tinyPadding),
        Text(
          subLabel,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(ConfigService.alphaModerate),
            fontSize: 10,
          ),
        ),
      ],
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
  
  LineChartData _createLineChartData(ThemeData theme) {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 10,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: theme.colorScheme.outlineVariant.withAlpha(ConfigService.alphaLight),
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: theme.colorScheme.outlineVariant.withAlpha(ConfigService.alphaLight),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < trendsData.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    trendsData[value.toInt()].month,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              }
              return Container();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 20,
            getTitlesWidget: (value, meta) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              );
            },
            reservedSize: 40,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(ConfigService.alphaLight),
        ),
      ),
      minX: 0,
      maxX: trendsData.length - 1.0,
      minY: 0,
      maxY: _getMaxY(),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          // Using the tooltip property instead of tooltipBgColor
          tooltip: FlTooltip(
            getTooltipColor: (_) => theme.colorScheme.surface,
          ),
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              final index = barSpot.x.toInt();
              if (index >= 0 && index < trendsData.length) {
                final data = trendsData[index];
                
                final isStock = barSpot.barIndex == 0;
                return LineTooltipItem(
                  '${isStock ? 'Stock' : 'Inventory'}: ${barSpot.y.toInt()}',
                  TextStyle(
                    color: isStock ? 
                      theme.colorScheme.primary : 
                      theme.colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }
              return null;
            }).toList();
          },
        ),
      ),
      lineBarsData: [
        // Stock line
        LineChartBarData(
          spots: _createSpots(true),
          isCurved: true,
          color: theme.colorScheme.primary,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: theme.colorScheme.primary.withAlpha(ConfigService.alphaLight),
          ),
        ),
        // Inventory line
        LineChartBarData(
          spots: _createSpots(false),
          isCurved: true,
          color: theme.colorScheme.secondary,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: theme.colorScheme.secondary.withAlpha(ConfigService.alphaLight),
          ),
        ),
      ],
    );
  }
  
  List<FlSpot> _createSpots(bool isStock) {
    return List.generate(trendsData.length, (index) {
      return FlSpot(
        index.toDouble(),
        isStock ? 
          trendsData[index].stockCount.toDouble() : 
          trendsData[index].inventoryCount.toDouble(),
      );
    });
  }
  
  double _getMaxY() {
    double maxStock = 0;
    double maxInventory = 0;
    
    for (var data in trendsData) {
      if (data.stockCount > maxStock) {
        maxStock = data.stockCount.toDouble();
      }
      if (data.inventoryCount > maxInventory) {
        maxInventory = data.inventoryCount.toDouble();
      }
    }
    
    // Return the larger of the two with some padding
    return (maxStock > maxInventory ? maxStock : maxInventory) * 1.2;
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