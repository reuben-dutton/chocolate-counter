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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.list, size: ConfigService.defaultIconSize),
              SizedBox(width: ConfigService.smallPadding),
              Text(
                'Expiring Items Detail',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 1, thickness: 1),
          
          // Table header
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ConfigService.defaultPadding,
              vertical: ConfigService.smallPadding,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Item',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Expires',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Days Left',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Qty',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Status',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          
          // Item list
          SizedBox(
            height: 300,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = items[index];
                final itemName = item['itemName'] as String;
                final quantity = item['quantity'] as int;
                final expirationDate = DateTime.fromMillisecondsSinceEpoch(item['expirationDate'] as int);
                final status = item['status'] as String;
                
                // Calculate days remaining
                final daysLeft = expirationDate.difference(DateTime.now()).inDays;
                
                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ConfigService.defaultPadding,
                    vertical: ConfigService.smallPadding,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          itemName,
                          style: theme.textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          DateFormat('yyyy-MM-dd').format(expirationDate),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          daysLeft.toString(),
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          quantity.toString(),
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: _buildStatusBadge(context, status),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Quick actions section
          Padding(
            padding: EdgeInsets.all(ConfigService.defaultPadding),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(ConfigService.defaultPadding),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withAlpha(ConfigService.alphaLight),
                borderRadius: BorderRadius.circular(ConfigService.borderRadiusSmall),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: ConfigService.smallPadding),
                  if (items.any((item) => (item['status'] as String) == 'critical')) ...[
                    _buildQuickAction(
                      context, 
                      'Move critical items to stock', 
                      Icons.move_up
                    ),
                  ],
                  SizedBox(height: ConfigService.tinyPadding),
                  _buildQuickAction(
                    context, 
                    'Check storage conditions for early expirations', 
                    Icons.thermostat
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusBadge(BuildContext context, String status) {
    final theme = Theme.of(context);
    
    Color badgeColor;
    Color textColor;
    
    switch(status) {
      case 'critical':
        badgeColor = Colors.red.shade100;
        textColor = Colors.red.shade900;
      case 'warning':
        badgeColor = Colors.orange.shade100;
        textColor = Colors.orange.shade900;
      case 'normal':
        badgeColor = Colors.blue.shade100;
        textColor = Colors.blue.shade900;
      case 'safe':
        badgeColor = Colors.green.shade100;
        textColor = Colors.green.shade900;
      default:
        badgeColor = theme.colorScheme.surfaceContainerHighest;
        textColor = theme.colorScheme.onSurface;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(ConfigService.borderRadiusSmall),
      ),
      child: Text(
        status.substring(0, 1).toUpperCase() + status.substring(1),
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
  
  Widget _buildQuickAction(BuildContext context, String text, IconData icon) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Icon(
          icon,
          size: ConfigService.smallIconSize,
          color: theme.colorScheme.primary,
        ),
        SizedBox(width: ConfigService.smallPadding),
        Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}