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
            data.totalItemsCount == 0
                ? _buildNoDataInsight(context)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInsightRow(
                        context,
                        data.criticalCount > 0 
                            ? 'Prioritize ${data.criticalCount} items expiring this week'
                            : 'No items expiring this week, great job!',
                        Icons.priority_high,
                        data.criticalCount > 0 ? Colors.red : Colors.green,
                      ),
                      SizedBox(height: ConfigService.smallPadding),
                      _buildInsightRow(
                        context,
                        data.warningCount > 0 
                            ? 'Move ${data.warningCount} items expiring next week from inventory to stock'
                            : 'No items expiring next week',
                        Icons.move_up,
                        data.warningCount > 0 ? Colors.orange : theme.colorScheme.onSurface.withAlpha(ConfigService.alphaHigh),
                      ),
                      SizedBox(height: ConfigService.smallPadding),
                      _buildInsightRow(
                        context,
                        percentageCritical > 15
                            ? 'High proportion of critical items ($percentageCritical%), review purchasing patterns'
                            : 'Healthy balance of expiration timeframes',
                        Icons.balance,
                        percentageCritical > 15 ? Colors.amber : Colors.green,
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNoDataInsight(BuildContext context) {
    return _buildInsightRow(
      context,
      'No expiration data available. Add items with expiration dates to see insights.',
      Icons.info_outline,
      Theme.of(context).colorScheme.onSurface.withAlpha(ConfigService.alphaHigh),
    );
  }
  
  Widget _buildInsightRow(BuildContext context, String insight, IconData insightIcon, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(insightIcon, size: ConfigService.smallIconSize, color: iconColor),
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