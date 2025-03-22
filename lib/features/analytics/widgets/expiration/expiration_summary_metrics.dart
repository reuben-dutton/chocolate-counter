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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildMetricBox(
            context,
            data.beyondCount + data.nextMonthCount + data.thisMonthCount,
            'Okay',
            Colors.green,
            Icons.check_circle,
          ),
          SizedBox(width: ConfigService.smallPadding),
          _buildMetricBox(
            context,
            data.nextWeekCount,
            'Warning',
            Colors.orange,
            Icons.timelapse,
          ),
          SizedBox(width: ConfigService.mediumPadding),
          _buildMetricBox(
            context,
            data.thisWeekCount,
            'Critical',
            Colors.red,
            Icons.warning_amber,
          ),
          SizedBox(width: ConfigService.mediumPadding),
          _buildMetricBox(
            context,
            data.expiredCount,
            'Expired',
            Colors.red.shade900,
            Icons.event_busy,
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
    IconData icon,
  ) {
    final theme = Theme.of(context);
    
    return Container(
      width: 65,
      padding: EdgeInsets.all(ConfigService.tinyPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(ConfigService.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: ConfigService.defaultIconSize,
            color: color,
          ),
          const SizedBox(height: 6),
          Container(
            alignment: Alignment.center,
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value.toString(),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}