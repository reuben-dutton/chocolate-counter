import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/features/analytics/models/expiration_analytics_data.dart';

class ExpirationInsights extends StatelessWidget {
  final ExpirationAnalyticsData data;

  const ExpirationInsights({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentageCritical = _calculatePercentageCritical(data);
    
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
                  'Recommended Actions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: ConfigService.mediumPadding),
            
            // Generate insights based on the data
            _buildInsightRow(
              context,
              data.criticalCount > 0 
                  ? 'Consider prioritizing ${data.criticalCount} items expiring this week'
                  : 'No items expiring this week, great job!',
            ),
            SizedBox(height: ConfigService.smallPadding),
            _buildInsightRow(
              context,
              data.warningCount > 0 
                  ? 'Move ${data.warningCount} items expiring next week from inventory to stock'
                  : 'No items expiring next week',
            ),
            SizedBox(height: ConfigService.smallPadding),
            _buildInsightRow(
              context,
              percentageCritical > 15
                  ? 'High proportion of critical items ($percentageCritical%), review purchasing patterns'
                  : 'Healthy balance of expiration timeframes',
            ),
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
  
  int _calculatePercentageCritical(ExpirationAnalyticsData data) {
    if (data.totalItemsCount == 0) {
      return 0;
    }
    return (data.criticalCount / data.totalItemsCount * 100).round();
  }
}