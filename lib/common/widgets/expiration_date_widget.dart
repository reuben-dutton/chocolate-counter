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
    final theme = Theme.of(context);
    
    if (expirationDate == null) {
      return Text(
        'No expiration date',
        style: TextStyle(
          fontSize: fontSize,
          fontStyle: FontStyle.italic,
          color: theme.colorScheme.onSurface.withAlpha(ConfigService.alphaModerate),
        ),
      );
    }

    final daysUntil = expirationDate!.difference(DateTime.now()).inDays;
    final String humanReadableText = _getHumanReadableTimespan(daysUntil);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          Icon(
            Icons.event_available,
            size: iconSize,
            color: theme.colorScheme.onSurface,
          ),
          SizedBox(width: ConfigService.tinyPadding),
        ],
        Text(
          dateFormat.format(expirationDate!),
          style: TextStyle(
            fontSize: fontSize,
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: ConfigService.tinyPadding),
        Text(
          humanReadableText,
          style: TextStyle(
            fontSize: fontSize,
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  String _getHumanReadableTimespan(int daysUntil) {
    if (daysUntil < 0) {
      return '(Expired)';
    } else if (daysUntil == 0) {
      return '(Today)';
    } else if (daysUntil == 1) {
      return '(Tomorrow)';
    } else if (daysUntil < 7) {
      return '($daysUntil days from now)';
    } else if (daysUntil < 14) {
      return '(1 week from now)';
    } else if (daysUntil < 21) {
      return '(2 weeks from now)';
    } else if (daysUntil < 28) {
      return '(3 weeks from now)';
    } else if (daysUntil < 60) {
      return '(1 month from now)';
    } else if (daysUntil < 90) {
      return '(2 months from now)';
    } else if (daysUntil < 365) {
      final months = (daysUntil / 30).floor();
      return '($months months from now)';
    } else {
      final years = (daysUntil / 365).floor();
      return '($years ${years == 1 ? 'year' : 'years'} from now)';
    }
  }
}