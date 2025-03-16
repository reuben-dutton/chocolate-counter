import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/data/models/item_instance.dart';
import 'package:food_inventory/common/widgets/expiration_date_widget.dart';
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
        DateTime? expDate;
        
        if (entry.key != 'No expiration date') {
          expDate = DateFormat('yyyy-MM-dd').parse(entry.key);
        }
        
        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: ConfigService.tinyPadding, vertical: 0),
          leading: const Icon(Icons.calendar_today, size: ConfigService.mediumIconSize),
          title: ExpirationDateWidget(
            expirationDate: expDate,
            showIcon: false,
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