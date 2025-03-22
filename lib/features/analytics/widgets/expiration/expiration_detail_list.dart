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
    
    // Group items by status for showing headers
    final Map<String, List<Map<String, dynamic>>> groupedItems = {
      'expired': [],
      'critical': [],
      'warning': [],
      'normal': [],
      'safe': [],
    };
    
    for (final item in items) {
      final status = item['status'] as String;
      groupedItems[status]?.add(item);
    }
    
    final List<Widget> sections = [];
    
    // Expired items
    if (groupedItems['expired']!.isNotEmpty) {
      sections.add(_buildSectionHeader('Expired', groupedItems['expired']!.length, Colors.red.shade900));
      sections.addAll(groupedItems['expired']!.map((item) => _buildItemTile(context, item, Colors.red.shade900)));
    }
    
    // Critical items
    if (groupedItems['critical']!.isNotEmpty) {
      sections.add(_buildSectionHeader('Expiring This Week', groupedItems['critical']!.length, Colors.red));
      sections.addAll(groupedItems['critical']!.map((item) => _buildItemTile(context, item, Colors.red)));
    }
    
    // Warning items
    if (groupedItems['warning']!.isNotEmpty) {
      sections.add(_buildSectionHeader('Expiring Next Week', groupedItems['warning']!.length, Colors.orange));
      sections.addAll(groupedItems['warning']!.map((item) => _buildItemTile(context, item, Colors.orange)));
    }
    
    // Normal items
    if (groupedItems['normal']!.isNotEmpty) {
      sections.add(_buildSectionHeader('Expiring This Month', groupedItems['normal']!.length, theme.colorScheme.primary));
      sections.addAll(groupedItems['normal']!.map((item) => _buildItemTile(context, item, theme.colorScheme.primary)));
    }
    
    // Safe items
    if (groupedItems['safe']!.isNotEmpty) {
      sections.add(_buildSectionHeader('Expiring Later', groupedItems['safe']!.length, Colors.green));
      sections.addAll(groupedItems['safe']!.map((item) => _buildItemTile(context, item, Colors.green)));
    }
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: sections,
      ),
    );
  }
  
  Widget _buildSectionHeader(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 12, bottom: 4),
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
          SizedBox(width: 8),
          Text(
            '$title ($count)',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
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
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          left: BorderSide(
            color: statusColor,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
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
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 12,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 4),
                Text(
                  formattedDate,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(width: 8),
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
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
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