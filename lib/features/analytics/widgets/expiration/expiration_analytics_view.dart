import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/features/analytics/models/expiration_analytics_data.dart';
import 'package:food_inventory/features/analytics/widgets/expiration/expiration_pie_chart.dart';
import 'package:food_inventory/features/analytics/widgets/expiration/expiration_detail_list.dart';
import 'package:food_inventory/features/analytics/widgets/expiration/expiration_insights.dart';
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
    
    // Get items with status for display, filtering only critical and warning
    final items = widget.data!.getItemsWithStatus()
        .where((item) => ['critical', 'warning'].contains(item['status']))
        .toList();
    
    if (items.isEmpty) {
      return _buildEmptyState(theme);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // View toggle buttons - next to title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.event_busy, size: ConfigService.defaultIconSize, color: theme.colorScheme.primary),
                SizedBox(width: ConfigService.smallPadding),
                Text(
                  'Expiration Analytics', 
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold
                  )
                ),
              ],
            ),
            Expanded(
              flex: 1,
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.selected)) {
                        return theme.colorScheme.primary.withOpacity(0.1);
                      }
                      return Colors.transparent;
                    },
                  ),
                  foregroundColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.selected)) {
                        return theme.colorScheme.primary;
                      }
                      return theme.colorScheme.onSurface.withOpacity(0.6);
                    },
                  ),
                  padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 0)
                  ),
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  minimumSize: MaterialStateProperty.all(const Size(0, 28)),
                  side: MaterialStateProperty.all(
                    BorderSide.none
                  ),
                ),
                segments: const [
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('Summary', style: TextStyle(fontSize: 11)),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('Expiring', style: TextStyle(fontSize: 11)),
                  ),
                ],
                selected: {_showDetailView},
                onSelectionChanged: (Set<bool> selection) {
                  if (selection.isNotEmpty) {
                    setState(() {
                      _showDetailView = selection.first;
                    });
                  }
                },
              ),
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
  
  Widget _buildSummaryView(BuildContext context) {
    final data = widget.data!;
    
    // Get timeline data for charts
    final timelineData = data.getTimelineData();
    
    return Column(
      children: [
        // Pie Chart without title
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
                      padding: EdgeInsets.only(top: ConfigService.mediumPadding),
                      child: Wrap(
                        spacing: 10,
                        children: timelineData.map((item) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                color: _hexToColor(item['color'] as String),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item['category'] as String,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Summary metrics
        ExpirationSummaryMetrics(data: data),
        
        // Insights section
        ExpirationInsights(data: data),
      ],
    );
  }
  
  Widget _buildDetailView(BuildContext context, List<Map<String, dynamic>> items) {
    return ExpirationDetailList(items: items);
  }
  
  Widget _buildLoadingSkeleton(ThemeData theme) {
    return Column(
      children: [
        // Toggle buttons skeleton
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
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
        
        // Chart skeleton
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
  
  // Helper method to convert hex color
  Color _hexToColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}