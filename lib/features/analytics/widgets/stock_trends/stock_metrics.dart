import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';

class StockMetrics extends StatelessWidget {
  final int currentStock;
  final int currentInventory;
  final double stockGrowth;
  final double inventoryGrowth;
  final String firstMonthLabel;

  const StockMetrics({
    super.key,
    required this.currentStock,
    required this.currentInventory,
    required this.stockGrowth,
    required this.inventoryGrowth,
    required this.firstMonthLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            '$firstMonthLabel to now',
          ),
          _buildMetricColumn(
            context,
            Icons.inventory_2,
            'Current Inventory',
            currentInventory.toString(),
            inventoryGrowth,
            '$firstMonthLabel to now',
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
}