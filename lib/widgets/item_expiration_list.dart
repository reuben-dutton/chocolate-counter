import 'package:flutter/material.dart';
import 'package:food_inventory/models/item_instance.dart';
import 'package:intl/intl.dart';

class ItemExpirationList extends StatelessWidget {
  final List<ItemInstance> instances;

  const ItemExpirationList({
    super.key,
    required this.instances,
  });

  @override
  Widget build(BuildContext context) {
    // Group by expiration date
    final Map<String, int> expirationCounts = {};
    
    for (final instance in instances) {
      final key = instance.expirationDate != null
          ? DateFormat('yyyy-MM-dd').format(instance.expirationDate!)
          : 'No expiration date';
      
      expirationCounts[key] = (expirationCounts[key] ?? 0) + instance.quantity;
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: expirationCounts.length,
      itemBuilder: (context, index) {
        final entry = expirationCounts.entries.toList()[index];
        Color iconColor = Colors.grey;
        
        if (entry.key != 'No expiration date') {
          final expDate = DateFormat('yyyy-MM-dd').parse(entry.key);
          final daysUntil = expDate.difference(DateTime.now()).inDays;
          
          if (daysUntil < 0) {
            iconColor = Colors.red;
          } else if (daysUntil < 7) {
            iconColor = Colors.orange;
          } else {
            iconColor = Colors.green;
          }
        }
        
        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          leading: Icon(
            Icons.calendar_today, 
            color: iconColor,
            size: 18,
          ),
          title: Text(
            entry.key,
            style: const TextStyle(fontSize: 14),
          ),
          trailing: Chip(
            padding: const EdgeInsets.all(0),
            visualDensity: VisualDensity.compact,
            label: Text(
              '${entry.value}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        );
      },
    );
  }
}