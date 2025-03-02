import 'package:flutter/material.dart';
import 'package:food_inventory/services/config_service.dart';

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
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(ConfigService.defaultBorderRadius),
          ),
          child: Icon(icon, size: ConfigService.mediumIconSize, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(175),
          ),
        ),
        const SizedBox(height: 4),
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