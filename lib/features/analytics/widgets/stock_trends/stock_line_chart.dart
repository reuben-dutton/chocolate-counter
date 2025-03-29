import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/features/analytics/models/stock_trend_data.dart';

class StockLineChart extends StatelessWidget {
  final List<StockTrendData> trendsData;

  const StockLineChart({
    super.key,
    required this.trendsData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LineChart(_createLineChartData(theme));
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
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
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
                    fontSize: 10,
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
          getTooltipColor: (touchedSpot) => theme.colorScheme.surface,
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              final index = barSpot.x.toInt();
              if (index >= 0 && index < trendsData.length) {
                
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
}