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
        horizontal: ConfigService.defaultPadding
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSimpleStatColumn(
            context,
            Icons.shopping_cart,
            'Total Sales',
            totalSales.toString(),
          ),
          _buildSimpleStatColumn(
            context,
            Icons.inventory_2,
            'Total Stock',
            totalStockCount.toString(),
          ),
          _buildSimpleStatColumn(
            context,
            Icons.add_chart,
            'Unique Items',
            uniqueItemsCount.toString(),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStatColumn(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 24,
        ),
        SizedBox(height: ConfigService.smallPadding),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(ConfigService.alphaDefault),
          ),
        ),
        SizedBox(height: ConfigService.smallPadding),
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