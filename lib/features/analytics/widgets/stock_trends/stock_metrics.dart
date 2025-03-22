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
        horizontal: ConfigService.smallPadding
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: _buildMetricColumn(
              context,
              Icons.shopping_cart,
              'Current Stock',
              currentStock.toString(),
            ),
          ),
          Expanded(
            child: _buildMetricColumn(
              context,
              Icons.inventory_2,
              'Current Inventory',
              currentInventory.toString(),
            ),
          ),
          Expanded(
            child: _buildMetricColumn(
              context,
              Icons.donut_large,
              'Total Items',
              (currentStock + currentInventory).toString(),
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
  ) {
    final theme = Theme.of(context);
    
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
          textAlign: TextAlign.center,
        ),
        SizedBox(height: ConfigService.tinyPadding),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}