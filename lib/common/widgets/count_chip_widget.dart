import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';

class CountChipWidget extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;
  final double iconSize;
  final double fontSize;
  final String? text;

  const CountChipWidget({
    super.key,
    required this.icon,
    required this.count,
    required this.color,
    this.iconSize = ConfigService.smallIconSize,
    this.fontSize = 13,
    this.text, // Optional text to display instead of count
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize, color: color),
        SizedBox(width: ConfigService.tinyPadding),
        Text(
          text ?? '$count',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
          ),
        ),
      ],
    );
  }
}