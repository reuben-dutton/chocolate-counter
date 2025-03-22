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
    
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: ConfigService.largeIconSize,
              color: theme.colorScheme.onSurface.withAlpha(ConfigService.alphaModerate),
            ),
            SizedBox(height: ConfigService.defaultPadding),
            Text(
              'No expiring items',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(ConfigService.alphaDefault),
              ),
            ),
          ],
        ),
      );
    }
    
    // Sort items by expiration date
    final sortedItems = List<Map<String, dynamic>>.from(items)
      ..sort((a, b) {
        final aDate = DateTime.fromMillisecondsSinceEpoch(a['expirationDate'] as int);
        final bDate = DateTime.fromMillisecondsSinceEpoch(b['expirationDate'] as int);
        return aDate.compareTo(bDate);
      });
    
    // Group items by status for showing headers
    final Map<String, List<Map<String, dynamic>>> groupedItems = {
      'critical': [],
      'warning': [],
      'normal': [],
      'safe': [],
    };
    
    for (final item in sortedItems) {
      final status = item['status'] as String;
      groupedItems[status]?.add(item);
    }
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Critical items
          if (groupedItems['critical']!.isNotEmpty)
            _buildStatusSection(context, 'Expiring This Week', groupedItems['critical']!, Colors.red),
            
          // Warning items
          if (groupedItems['warning']!.isNotEmpty)
            _buildStatusSection(context, 'Expiring Next Week', groupedItems['warning']!, Colors.orange),
            
          // Normal items
          if (groupedItems['normal']!.isNotEmpty)
            _buildStatusSection(context, 'Expiring This Month', groupedItems['normal']!, theme.colorScheme.primary),
            
          // Safe items
          if (groupedItems['safe']!.isNotEmpty)
            _buildStatusSection(context, 'Expiring Later', groupedItems['safe']!, Colors.green),
        ],
      ),
    );
  }
  
  Widget _buildStatusSection(
    BuildContext context,
    String title,
    List<Map<String, dynamic>> sectionItems,
    Color color
  ) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: EdgeInsets.only(bottom: ConfigService.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: ConfigService.smallPadding,
              horizontal: ConfigService.smallPadding,
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: ConfigService.smallPadding),
                Text(
                  '$title (${sectionItems.length})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(ConfigService.borderRadiusMedium),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sectionItems.length,
              separatorBuilder: (_, __) => Divider(height: 1, thickness: 1, indent: 70),
              itemBuilder: (context, index) => _buildItemTile(context, sectionItems[index], color),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildItemTile(BuildContext context, Map<String, dynamic> item, Color statusColor) {
    final theme = Theme.of(context);
    final expirationDate = DateTime.fromMillisecondsSinceEpoch(item['expirationDate'] as int);
    final quantity = item['quantity'] as int;
    final itemName = item['itemName'] as String;
    final daysUntil = expirationDate.difference(DateTime.now()).inDays;
    
    final dateFormat = DateFormat('MMM d, yyyy');
    final formattedDate = dateFormat.format(expirationDate);
    
    String daysText;
    if (daysUntil < 0) {
      daysText = 'Expired ${-daysUntil} ${-daysUntil == 1 ? 'day' : 'days'} ago';
    } else if (daysUntil == 0) {
      daysText = 'Expires today';
    } else {
      daysText = 'Expires in $daysUntil ${daysUntil == 1 ? 'day' : 'days'}';
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
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: ConfigService.tinyPadding),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: ConfigService.tinyIconSize,
                  color: theme.colorScheme.secondary,
                ),
                SizedBox(width: ConfigService.tinyPadding),
                Text(
                  formattedDate,
                  style: theme.textTheme.bodySmall,
                ),
                SizedBox(width: ConfigService.smallPadding),
                Text(
                  daysText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(
            horizontal: ConfigService.smallPadding,
            vertical: ConfigService.tinyPadding,
          ),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor, width: 1),
          ),
          child: Text(
            quantity.toString(),
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}