import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:intl/intl.dart';

class ExpirationDateWidget extends StatelessWidget {
  final DateTime? expirationDate;
  final bool showIcon;
  final double iconSize;
  final double fontSize;
  final DateFormat dateFormat;

  ExpirationDateWidget({
    super.key,
    required this.expirationDate,
    this.showIcon = true,
    this.iconSize = ConfigService.tinyIconSize,
    this.fontSize = 12,
    DateFormat? dateFormat,
  }) : dateFormat = dateFormat ?? DateFormat('yyyy-MM-dd');

  @override
  Widget build(BuildContext context) {
    if (expirationDate == null) {
      return Text(
        'No expiration date',
        style: TextStyle(
          fontSize: fontSize,
          fontStyle: FontStyle.italic,
          color: Colors.grey,
        ),
      );
    }

    final color = ConfigService.getExpirationColor(context, expirationDate);
    final daysUntil = expirationDate!.difference(DateTime.now()).inDays;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          Icon(
            Icons.event_available,
            size: iconSize,
            color: color,
          ),
          SizedBox(width: ConfigService.tinyPadding),
        ],
        Text(
          dateFormat.format(expirationDate!),
          style: TextStyle(
            fontSize: fontSize,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: ConfigService.tinyPadding),
        if (daysUntil < 0) 
          Text(
            '(Expired)',
            style: TextStyle(
              fontSize: fontSize,
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          )
        else if (daysUntil <= ConfigService.expirationCriticalDays)
          Text(
            '(${daysUntil == 0 ? 'Today' : '$daysUntil days'})',
            style: TextStyle(
              fontSize: fontSize,
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          )
        else if (daysUntil <= ConfigService.expirationWarningDays)
          Text(
            '($daysUntil days)',
            style: TextStyle(
              fontSize: fontSize,
              color: Colors.amber,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }
}