import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/features/analytics/models/expiration_analytics_data.dart';
import 'package:food_inventory/features/analytics/widgets/expiration/expiration_pie_chart.dart';
import 'package:food_inventory/features/analytics/widgets/expiration/expiration_detail_list.dart';
import 'package:food_inventory/features/analytics/widgets/expiration/expiration_insights.dart';

/// Main view widget that combines all expiration analytics components
class ExpirationAnalyticsView extends StatelessWidget {
  final ExpirationAnalyticsData? data;
  final bool isLoading;
  final bool showDetailView;

  const ExpirationAnalyticsView({
    super.key,
    this.data,
    this.isLoading = false,
    this.showDetailView = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (isLoading) {
      return _buildLoadingSkeleton(theme);
    }
    
    if (data == null) {
      return _buildEmptyState(theme);
    }
    
    // Get items with status for display
    final items = data!.getItemsWithStatus()
        .where((item) => showDetailView ? true : ['critical', 'warning'].contains(item['status']))
        .toList();
    
    if (items.isEmpty && showDetailView) {
      // If detail view has no items to show
      return _buildEmptyState(theme);
    }
    
    // Summary or Detail view based on selection
    if (!showDetailView) {
      return _buildSummaryView(context);
    } else {
      return _buildDetailView(context, items);
    }
  }
  
  Widget _buildSummaryView(BuildContext context) {
    final timelineData = data!.getTimelineData();
    
    return Column(
      children: [
        // Pie Chart
        Padding(
          padding: EdgeInsets.all(ConfigService.defaultPadding),
          child: Row(
            children: [
              Expanded(
                child: ExpirationPieChart(timelineData: timelineData),
              ),
            ],
          ),
        ),
        
        // Summary metrics with horizontal alignment
        _buildAlignedSummaryMetrics(context),
        
        // Insights section
        ExpirationInsights(data: data!),
      ],
    );
  }

  Widget _buildAlignedSummaryMetrics(BuildContext context) {
    
    // Calculate items for each category
    final criticalItems = data!.thisWeekItems.length;
    final warningItems = data!.nextWeekItems.length;
    final expiredItems = data!.expiredItems.length;
    final okayItems = data!.thisMonthItems.length + data!.nextMonthItems.length + data!.beyondItems.length;
    
    return Padding(
      padding: EdgeInsets.all(ConfigService.defaultPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildMetricBox(
            context,
            okayItems,
            'Okay',
            Colors.green,
            Icons.check_circle,
          ),
          SizedBox(width: ConfigService.smallPadding),
          _buildMetricBox(
            context,
            warningItems,
            'Warning',
            Colors.orange,
            Icons.timelapse,
          ),
          SizedBox(width: ConfigService.mediumPadding),
          _buildMetricBox(
            context,
            criticalItems,
            'Critical',
            Colors.red,
            Icons.warning_amber,
          ),
          SizedBox(width: ConfigService.mediumPadding),
          _buildMetricBox(
            context,
            expiredItems,
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
  
  Widget _buildDetailView(BuildContext context, List<Map<String, dynamic>> items) {
    return ExpirationDetailList(items: items);
  }
  
  Widget _buildLoadingSkeleton(ThemeData theme) {
    return Column(
      children: [
        // Metrics skeleton
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(3, (_) => 
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        
        SizedBox(height: ConfigService.defaultPadding),
        
        // Chart skeleton
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        
        SizedBox(height: ConfigService.defaultPadding),
        
        // Insights skeleton
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }
  
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: ConfigService.xLargeIconSize,
            color: theme.colorScheme.onSurface.withAlpha(ConfigService.alphaModerate)
          ),
          SizedBox(height: ConfigService.defaultPadding),
          Text(
            'No expiration data available',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(ConfigService.alphaDefault),
            ),
          ),
          SizedBox(height: ConfigService.smallPadding),
          Text(
            'Add items with expiration dates',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(ConfigService.alphaDefault),
            ),
          ),
        ],
      ),
    );
  }
}