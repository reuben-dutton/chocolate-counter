import 'package:flutter/material.dart';
import 'package:food_inventory/models/shipment_item.dart';
import 'package:food_inventory/utils/item_visualization.dart';
import 'package:food_inventory/widgets/expiration_edit_dialog.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class ShipmentItemList extends StatelessWidget {
  final List<ShipmentItem> items;
  final Function(int, DateTime?)? onExpirationDateChanged;

  const ShipmentItemList({
    super.key,
    required this.items,
    this.onExpirationDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          leading: _buildItemImage(item, context),
          title: Text(
            item.itemDefinition?.name ?? 'Unknown Item',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: item.expirationDate != null
              ? Row(
                  children: [
                    const Icon(Icons.event_available, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('yyyy-MM-dd').format(item.expirationDate!),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                )
              : const Text(
                  'No expiration date',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Add edit button for expiration date if the callback is provided
              if (onExpirationDateChanged != null)
                IconButton(
                  icon: const Icon(Icons.edit_calendar, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Edit expiration date',
                  onPressed: () => _showExpirationEditDialog(context, item),
                ),
              const SizedBox(width: 8),
              Chip(
                padding: const EdgeInsets.all(0),
                visualDensity: VisualDensity.compact,
                label: Text(
                  '${item.quantity}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItemImage(ShipmentItem item, BuildContext context) {
    if (item.itemDefinition == null || item.itemDefinition!.imageUrl == null) {
      final color = ItemVisualization.getColorForItem(
          item.itemDefinition?.name ?? 'Unknown Item', 
          context
      );
      final icon = ItemVisualization.getIconForItem(
          item.itemDefinition?.name ?? 'Unknown Item'
      );
      return CircleAvatar(
        radius: 18,
        backgroundColor: color,
        child: Icon(icon, color: Colors.white, size: 16),
      );
    }
    
    final String imagePath = item.itemDefinition!.imageUrl!;
    
    try {
      if (imagePath.startsWith('http')) {
        // Remote URL
        return CircleAvatar(
          radius: 18,
          backgroundImage: NetworkImage(imagePath),
          onBackgroundImageError: (_, __) {},
        );
      } else {
        // Local file path
        final file = File(imagePath);
        if (!file.existsSync()) {
          return CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey,
            child: const Icon(Icons.image_not_supported, color: Colors.white, size: 16),
          );
        }
        return CircleAvatar(
          radius: 18,
          backgroundImage: FileImage(file),
          onBackgroundImageError: (_, __) {},
        );
      }
    } catch (e) {
      // Fallback in case of any image loading errors
      return CircleAvatar(
        radius: 18,
        backgroundColor: Colors.grey,
        child: const Icon(Icons.image_not_supported, color: Colors.white, size: 16),
      );
    }
  }
  
  void _showExpirationEditDialog(BuildContext context, ShipmentItem item) async {
    if (item.id == null) return;
    
    final newExpirationDate = await showDialog<DateTime?>(
      context: context,
      builder: (context) => ExpirationEditDialog(item: item),
    );
    
    // If a date was selected and the callback exists, trigger it
    if (onExpirationDateChanged != null) {
      onExpirationDateChanged!(item.id!, newExpirationDate);
    }
  }
}