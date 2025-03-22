import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';

class StockRatioDisplay extends StatelessWidget {
  final int currentStock;
  final int currentInventory;

  const StockRatioDisplay({
    super.key,
    required this.currentStock,
    required this.currentInventory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
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
              value: _calculateRatio(),
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
                  'Stock: ${_formatPercentage(currentStock)}',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  'Inventory: ${_formatPercentage(currentInventory)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateRatio() {
    final total = currentStock + currentInventory;
    return total > 0 ? currentStock / total : 0.5; // Default to 50% if total is 0
  }

  String _formatPercentage(int value) {
    final total = currentStock + currentInventory;
    if (total == 0) return '0.0%';
    return '${(value / total * 100).toStringAsFixed(1)}%';
  }
}