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
    
    // Calculate expired items (total items with negative days until expiration)
    final criticalItems = data.thisWeekItems.length;
    final criticalAndWarningItems = data.thisWeekItems.length + data.nextWeekItems.length;
    final expiredItems = data.thisWeekItems.where((item) {
      final expirationDate = DateTime.fromMillisecondsSinceEpoch(item['expirationDate'] as int);
      return expirationDate.isBefore(DateTime.now());
    }).length;
    
    return Padding(
      padding: EdgeInsets.all(ConfigService.defaultPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricBox(
            context,
            criticalItems,
            'Critical',
            theme.colorScheme.error,
          ),
          _buildMetricBox(
            context,
            criticalAndWarningItems,
            'Critical + Warning',
            Colors.orange,
          ),
          _buildMetricBox(
            context,
            expiredItems,
            'Expired',
            Colors.red.shade900,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBox(
    BuildContext context,
    int value,
    String label,
    Color color,
  ) {
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value.toString(),
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
        ],
      ),
    );
  }
}