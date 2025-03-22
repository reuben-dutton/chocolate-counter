import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/features/analytics/models/expiration_analytics_data.dart';
import 'package:food_inventory/features/analytics/widgets/expiration/expiration_bar_chart.dart';
import 'package:food_inventory/features/analytics/widgets/expiration/expiration_detail_list.dart';
import 'package:food_inventory/features/analytics/widgets/expiration/expiration_insights.dart';
import 'package:food_inventory/features/analytics/widgets/expiration/expiration_pie_chart.dart';
import 'package:food_inventory/features/analytics/widgets/expiration/expiration_summary_metrics.dart';

/// Main view widget that combines all expiration analytics components
class ExpirationAnalyticsView extends StatefulWidget {
  final ExpirationAnalyticsData? data;
  final bool isLoading;

  const ExpirationAnalyticsView({
    super.key,
    this.data,
    this.isLoading = false,
  });

  @override
  State<ExpirationAnalyticsView> createState() => _ExpirationAnalyticsViewState();
}

class _ExpirationAnalyticsViewState extends State<ExpirationAnalyticsView> {
  bool _showDetailView = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (widget.isLoading) {
      return _buildLoadingSkeleton(theme);
    }
    
    if (widget.data == null) {
      return _buildEmptyState(theme);
    }
    
    // Get all items with status for display
    final items = widget.data!.getItemsWithStatus();
    
    if (items.isEmpty) {
      return _buildEmptyState(theme);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // View toggle buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildToggleButton(
              context,
              'Summary',
              !_showDetailView,
              () => setState(() => _showDetailView = false),
            ),
            SizedBox(width: ConfigService.smallPadding),
            _buildToggleButton(
              context,
              'Expiring Items',
              _showDetailView,
              () => setState(() => _showDetailView = true),
            ),
          ],
        ),
        
        SizedBox(height: ConfigService.mediumPadding),
        
        // Summary metrics if in summary view
        if (!_showDetailView) ...[
          _buildSummaryView(context),
        ] else ...[
          _buildDetailView(context, items),
        ],
      ],
    );
  }
  
  Widget _buildLoadingSkeleton(ThemeData theme) {
    return Column(
      children: [
        // Toggle buttons skeleton
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            SizedBox(width: ConfigService.smallPadding),
            Container(
              width: 100,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
        
        SizedBox(height: ConfigService.defaultPadding),
        
        // Metrics skeleton
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(3, (_) => 
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        
        SizedBox(height: ConfigService.defaultPadding),
        
        // Chart skeletons
        Row(
          children: [
            Expanded(
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(width: ConfigService.defaultPadding),
            Expanded(
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
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
  
  Widget _buildToggleButton(
    BuildContext context, 
    String text, 
    bool isSelected, 
    VoidCallback onTap
  ) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ConfigService.borderRadiusMedium),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
            ? theme.colorScheme.primary 
            : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(ConfigService.borderRadiusMedium),
        ),
        child: Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isSelected 
              ? theme.colorScheme.onPrimary 
              : theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  Widget _buildSummaryView(BuildContext context) {
    final data = widget.data!;
    
    // Get timeline data for charts
    final timelineData = data.getTimelineData();
    
    return Column(
      children: [
        // Summary metrics at the top
        ExpirationSummaryMetrics(data: data),
        
        SizedBox(height: ConfigService.defaultPadding),
        
        // Charts Grid
        Padding(
          padding: EdgeInsets.all(ConfigService.defaultPadding),
          child: Row(
            children: [
              // Bar Chart
              Expanded(
                child: ExpirationBarChart(timelineData: timelineData),
              ),
              
              SizedBox(width: ConfigService.defaultPadding),
              
              // Pie Chart
              Expanded(
                child: ExpirationPieChart(timelineData: timelineData),
              ),
            ],
          ),
        ),
        
        // Insights section
        ExpirationInsights(data: data),
      ],
    );
  }
  
  Widget _buildDetailView(BuildContext context, List<Map<String, dynamic>> items) {
    return ExpirationDetailList(items: items);
  }
}