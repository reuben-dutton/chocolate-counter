import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/features/analytics/models/expiration_analytics_data.dart';

class ExpirationSummaryMetrics extends StatelessWidget {
  final ExpirationAnalyticsData data;

  const ExpirationSummaryMetrics({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: EdgeInsets.all(ConfigService.defaultPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricBox(
            context,
            data.criticalCount,
            'Critical Items',
            'Expiring within 7 days',
            Colors.red,
          ),
          _buildMetricBox(
            context,
            data.totalItemsCount,
            'Expiring Items',
            'Across all timeframes',
            theme.colorScheme.primary,
          ),
          _buildMetricBox(
            context,
            _calculatePercentageCritical(data),
            'Critical %',
            'Of total inventory',
            Colors.orange,
            isPercentage: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBox(
    BuildContext context,
    int value,
    String label,
    String sublabel,
    Color color, {
    bool isPercentage = false,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      width: 100,
      padding: EdgeInsets.all(ConfigService.defaultPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(ConfigService.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            isPercentage ? '$value%' : value.toString(),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: ConfigService.tinyPadding),
          Text(
            label,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ConfigService.tinyPadding),
          Text(
            sublabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(ConfigService.alphaDefault),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  int _calculatePercentageCritical(ExpirationAnalyticsData data) {
    if (data.totalItemsCount == 0) {
      return 0;
    }
    return (data.criticalCount / data.totalItemsCount * 100).round();
  }
}