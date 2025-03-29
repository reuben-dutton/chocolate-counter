import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';

class SummaryMetrics extends StatelessWidget {
  final int totalSales;
  final int totalStockCount;
  final int uniqueItemsCount;

  const SummaryMetrics({
    super.key,
    required this.totalSales,
    required this.totalStockCount,
    required this.uniqueItemsCount,
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
              'Total Sales',
              totalSales.toString(),
            ),
          ),
          Expanded(
            child: _buildMetricColumn(
              context,
              Icons.inventory_2,
              'Total Stock',
              totalStockCount.toString(),
            ),
          ),
          Expanded(
            child: _buildMetricColumn(
              context,
              Icons.add_chart,
              'Unique Items',
              uniqueItemsCount.toString(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn(BuildContext context, IconData icon, String label, String value) {
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