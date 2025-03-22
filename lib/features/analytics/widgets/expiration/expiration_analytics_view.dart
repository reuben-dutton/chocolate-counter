import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/features/analytics/models/expiration_analytics_data.dart';
import 'package:food_inventory/features/analytics/widgets/expiration/expiration_pie_chart.dart';
import 'package:food_inventory/features/analytics/widgets/expiration/expiration_detail_list.dart';
import 'package:food_inventory/features/analytics/widgets/expiration/expiration_insights.dart';
import 'package:food_inventory/features/analytics/widgets/expiration/expiration_summary_metrics.dart';

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
                child: Column(
                  children: [
                    ExpirationPieChart(timelineData: timelineData),
                    // Legend for pie chart
                    Padding(
                      padding: EdgeInsets.only(top: ConfigService.largePadding), // Increased padding
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: ConfigService.mediumPadding,
                          horizontal: ConfigService.smallPadding
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(ConfigService.borderRadiusSmall),
                        ),
                        child: Wrap(
                          spacing: 16, // Increased spacing
                          runSpacing: 12, // Increased spacing
                          alignment: WrapAlignment.center,
                          children: timelineData.map((item) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _hexToColor(item['color'] as String),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 6), // Increased spacing
                                Text(
                                  item['category'] as String,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Summary metrics
        ExpirationSummaryMetrics(data: data!),
        
        // Insights section
        ExpirationInsights(data: data!),
      ],
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
  
  // Helper method to convert hex color
  Color _hexToColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}