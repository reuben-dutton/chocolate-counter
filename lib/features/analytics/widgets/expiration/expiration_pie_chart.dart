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
    
    return Container(
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