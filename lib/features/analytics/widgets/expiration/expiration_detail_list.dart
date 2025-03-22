import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:intl/intl.dart';

class ExpirationDetailList extends StatelessWidget {
  final List<Map<String, dynamic>> items;

  const ExpirationDetailList({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
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
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final expirationDate = DateTime.fromMillisecondsSinceEpoch(item['expirationDate'] as int);
          final quantity = item['quantity'] as int;
          final itemName = item['itemName'] as String;
          final status = item['status'] as String;
          
          // Determine status color
          Color statusColor;
          switch (status) {
            case 'critical':
              statusColor = Colors.red;
              break;
            case 'warning':
              statusColor = Colors.orange;
              break;
            case 'normal':
              statusColor = Colors.blue;
              break;
            case 'safe':
              statusColor = Colors.green;
              break;
            default:
              statusColor = theme.colorScheme.onSurface;
          }
          
          return Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: statusColor,
                  width: 4,
                ),
              ),
            ),
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: ConfigService.defaultPadding,
                vertical: ConfigService.smallPadding,
              ),
              title: Text(
                itemName,
                style: theme.textTheme.bodyMedium,
              ),
              subtitle: Text(
                DateFormat('yyyy-MM-dd').format(expirationDate),
                style: theme.textTheme.bodySmall,
              ),
              trailing: Chip(
                label: Text(
                  '$quantity',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}