import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';

class ExpirationPieChart extends StatelessWidget {
  final List<Map<String, dynamic>> timelineData;

  const ExpirationPieChart({
    super.key,
    required this.timelineData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool hasData = timelineData.any((item) => (item['count'] as int) > 0);
    
    if (!hasData) {
      return _buildEmptyChart(theme);
    }
    
    return Container(
      height: 230,
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
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: _createSections(timelineData, theme),
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              // Handle touch events if needed
            },
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyChart(ThemeData theme) {
    return Container(
      height: 230,
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: ConfigService.largeIconSize,
              color: theme.colorScheme.onSurface.withAlpha(ConfigService.alphaModerate),
            ),
            SizedBox(height: ConfigService.smallPadding),
            Text(
              'No expiration data',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(ConfigService.alphaDefault),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  List<PieChartSectionData> _createSections(List<Map<String, dynamic>> data, ThemeData theme) {
    final totalCount = data.fold<int>(0, (sum, item) => sum + (item['count'] as int));
    
    // If there's no data, return an empty section
    if (totalCount == 0) {
      return [
        PieChartSectionData(
          color: theme.colorScheme.surfaceContainerHighest,
          value: 100,
          title: '0%',
          radius: 60,
          titleStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ];
    }
    
    return data.map((item) {
      final count = item['count'] as int;
      final category = item['category'] as String;
      final color = _hexToColor(item['color'] as String);
      
      // Calculate percentage
      final percentage = totalCount > 0 ? (count / totalCount * 100) : 0.0;
      
      // Skip sections with 0 count
      if (count == 0) {
        return PieChartSectionData(
          color: Colors.transparent,
          value: 0,
          title: '',
          radius: 0,
        );
      }
      
      return PieChartSectionData(
        color: color,
        value: count.toDouble(),
        title: percentage >= 5 ? '${percentage.toStringAsFixed(0)}%' : '',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).where((section) => section.value > 0).toList();
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