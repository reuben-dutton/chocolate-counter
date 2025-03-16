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
        Container(
          padding: const EdgeInsets.all(ConfigService.mediumPadding),
          decoration: BoxDecoration(
            color: color.withAlpha(ConfigService.alphaLight),
            borderRadius: BorderRadius.circular(ConfigService.defaultBorderRadius),
          ),
          child: Icon(icon, size: ConfigService.mediumIconSize, color: color),
        ),
        const SizedBox(height: ConfigService.smallPadding),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(ConfigService.alphaHigh),
          ),
        ),
        const SizedBox(height: ConfigService.tinyPadding),
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