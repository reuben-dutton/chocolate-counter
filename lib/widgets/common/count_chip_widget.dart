import 'package:flutter/material.dart';

class CountChipWidget extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;
  final double iconSize;
  final double fontSize;

  const CountChipWidget({
    super.key,
    required this.icon,
    required this.count,
    required this.color,
    this.iconSize = 14,
    this.fontSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: color),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}