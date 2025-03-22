import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';

class CountDisplayWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const CountDisplayWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Icon(
          icon, 
          size: ConfigService.largeIconSize, 
          color: color
        ),
        SizedBox(height: ConfigService.smallPadding),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(ConfigService.alphaHigh),
          ),
        ),
        SizedBox(height: ConfigService.tinyPadding),
        Text(
          '$count',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}