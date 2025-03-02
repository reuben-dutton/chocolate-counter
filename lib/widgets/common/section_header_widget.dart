import 'package:flutter/material.dart';

class SectionHeaderWidget extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onActionPressed;
  final IconData? actionIcon;
  final String? actionTooltip;

  const SectionHeaderWidget({
    super.key,
    required this.title,
    required this.icon,
    this.iconColor,
    this.onActionPressed,
    this.actionIcon,
    this.actionTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.colorScheme.primary;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: effectiveIconColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (onActionPressed != null && actionIcon != null)
          IconButton(
            icon: Icon(actionIcon, size: 18),
            tooltip: actionTooltip,
            onPressed: onActionPressed,
          ),
      ],
    );
  }
}