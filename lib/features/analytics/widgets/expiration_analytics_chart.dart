import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/features/analytics/models/expiration_analytics_data.dart';
import 'package:intl/intl.dart';

class ExpirationAnalyticsChart extends StatefulWidget {
  final ExpirationAnalyticsData? data;
  final bool isLoading;

  const ExpirationAnalyticsChart({
    super.key,
    this.data,
    this.isLoading = false,
  });

  @override
  State<ExpirationAnalyticsChart> createState() => _ExpirationAnalyticsChartState();
}

class _ExpirationAnalyticsChartState extends State<ExpirationAnalyticsChart> {
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
    final theme = Theme.of(context);
    final data = widget.data!;
    
    // Get timeline data for charts
    final timelineData = data.getTimelineData();
    
    return Column(
      children: [
        // Summary metrics at the top
        Padding(
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
        ),
        
        SizedBox(height: ConfigService.defaultPadding),
        
        // Charts Grid
        Padding(
          padding: EdgeInsets.all(ConfigService.defaultPadding),
          child: Row(
            children: [
              // Bar Chart
              Expanded(
                child: Container(
                  height: 220,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expiration Timeline',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: ConfigService.smallPadding),
                      Expanded(
                        child: BarChart(
                          _createBarChartData(timelineData, theme),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(width: ConfigService.defaultPadding),
              
              // Pie Chart
              Expanded(
                child: Container(
                  height: 220,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Timeline Distribution',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: ConfigService.smallPadding),
                      Expanded(
                        child: PieChart(
                          _createPieChartData(timelineData, theme),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Insights section
        SizedBox(height: ConfigService.defaultPadding),
        Padding(
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
                  _calculatePercentageCritical(data) > 15
                      ? 'High proportion of critical items (${_calculatePercentageCritical(data)}%), review purchasing patterns'
                      : 'Healthy balance of expiration timeframes',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildDetailView(BuildContext context, List<Map<String, dynamic>> items) {
    final theme = Theme.of(context);
    
    return Container(
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
          // Header
          Padding(
            padding: EdgeInsets.all(ConfigService.defaultPadding),
            child: Row(
              children: [
                Icon(
                  Icons.list,
                  size: ConfigService.defaultIconSize,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(width: ConfigService.smallPadding),
                Text(
                  'Expiring Items Detail',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          
          // Table header
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ConfigService.defaultPadding,
              vertical: ConfigService.smallPadding,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Item',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Expires',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Days Left',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Qty',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Status',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          
          // Item list
          SizedBox(
            height: 300,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = items[index];
                final itemName = item['itemName'] as String;
                final quantity = item['quantity'] as int;
                final expirationDate = DateTime.fromMillisecondsSinceEpoch(item['expirationDate'] as int);
                final status = item['status'] as String;
                
                // Calculate days remaining
                final daysLeft = expirationDate.difference(DateTime.now()).inDays;
                
                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ConfigService.defaultPadding,
                    vertical: ConfigService.smallPadding,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          itemName,
                          style: theme.textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          DateFormat('yyyy-MM-dd').format(expirationDate),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          daysLeft.toString(),
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          quantity.toString(),
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: _buildStatusBadge(context, status),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Recommendations
          Padding(
            padding: EdgeInsets.all(ConfigService.defaultPadding),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(ConfigService.defaultPadding),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withAlpha(ConfigService.alphaLight),
                borderRadius: BorderRadius.circular(ConfigService.borderRadiusSmall),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: ConfigService.smallPadding),
                  if (items.any((item) => (item['status'] as String) == 'critical')) ...[
                    _buildQuickAction(
                      context, 
                      'Move critical items to stock', 
                      Icons.move_up
                    ),
                  ],
                  SizedBox(height: ConfigService.tinyPadding),
                  _buildQuickAction(
                    context, 
                    'Check storage conditions for early expirations', 
                    Icons.thermostat
                  ),
                ],
              ),
            ),
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
  
  Widget _buildStatusBadge(BuildContext context, String status) {
    final theme = Theme.of(context);
    
    Color badgeColor;
    Color textColor;
    
    switch(status) {
      case 'critical':
        badgeColor = Colors.red.shade100;
        textColor = Colors.red.shade900;
      case 'warning':
        badgeColor = Colors.orange.shade100;
        textColor = Colors.orange.shade900;
      case 'normal':
        badgeColor = Colors.blue.shade100;
        textColor = Colors.blue.shade900;
      case 'safe':
        badgeColor = Colors.green.shade100;
        textColor = Colors.green.shade900;
      default:
        badgeColor = theme.colorScheme.surfaceContainerHighest;
        textColor = theme.colorScheme.onSurface;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(ConfigService.borderRadiusSmall),
      ),
      child: Text(
        status.substring(0, 1).toUpperCase() + status.substring(1),
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
  
  Widget _buildQuickAction(BuildContext context, String text, IconData icon) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Icon(
          icon,
          size: ConfigService.smallIconSize,
          color: theme.colorScheme.primary,
        ),
        SizedBox(width: ConfigService.smallPadding),
        Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary,
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
  
  BarChartData _createBarChartData(List<Map<String, dynamic>> timelineData, ThemeData theme) {
    return BarChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 10,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: theme.colorScheme.outlineVariant.withAlpha(ConfigService.alphaLight),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < timelineData.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    timelineData[index]['category'] as String,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                );
              }
              return Container();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              );
            },
            reservedSize: 30,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(ConfigService.alphaLight),
        ),
      ),
      barGroups: List.generate(
        timelineData.length,
        (index) {
          final item = timelineData[index];
          final count = item['count'] as int;
          final color = _hexToColor(item['color'] as String);
          
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: count.toDouble(),
                color: color,
                width: 20,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(ConfigService.borderRadiusSmall),
                  topRight: Radius.circular(ConfigService.borderRadiusSmall),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  PieChartData _createPieChartData(List<Map<String, dynamic>> timelineData, ThemeData theme) {
    return PieChartData(
      sectionsSpace: 0,
      centerSpaceRadius: 40,
      sections: List.generate(
        timelineData.length,
        (index) {
          final item = timelineData[index];
          final count = item['count'] as int;
          final category = item['category'] as String;
          final color = _hexToColor(item['color'] as String);
          
          // Calculate percentage
          final total = timelineData.fold<int>(
            0, (sum, item) => sum + (item['count'] as int)
          );
          final percentage = total > 0 ? (count / total * 100) : 0.0;
          
          return PieChartSectionData(
            color: color,
            value: count.toDouble(),
            title: '${percentage.toStringAsFixed(0)}%',
            radius: 60,
            titleStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            badgeWidget: _LegendBadge(
              color: color,
              text: category,
            ),
            badgePositionPercentageOffset: 1.5,
          );
        },
      ),
    );
  }
  
  // Helper method to convert hex color string to Color
  Color _hexToColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}

class _LegendBadge extends StatelessWidget {
  final Color color;
  final String text;
  
  const _LegendBadge({
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}