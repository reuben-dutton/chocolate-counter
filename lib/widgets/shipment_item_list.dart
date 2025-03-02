import 'package:flutter/material.dart';
import 'package:food_inventory/models/shipment_item.dart';
import 'package:food_inventory/widgets/common/expiration_date_widget.dart';
import 'package:food_inventory/widgets/common/item_image_widget.dart';
import 'package:food_inventory/widgets/expiration_edit_dialog.dart';

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
          leading: ItemImageWidget(
            imagePath: item.itemDefinition?.imageUrl,
            itemName: item.itemDefinition?.name ?? 'Unknown Item',
            radius: 18,
          ),
          title: Text(
            item.itemDefinition?.name ?? 'Unknown Item',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: ExpirationDateWidget(
            expirationDate: item.expirationDate,
            iconSize: 12,
            fontSize: 12,
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