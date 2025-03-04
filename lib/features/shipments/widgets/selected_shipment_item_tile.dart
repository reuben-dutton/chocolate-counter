import 'package:flutter/material.dart';
import 'package:food_inventory/data/models/shipment_item.dart';
import 'package:food_inventory/common/services/dialog_service.dart';
import 'package:food_inventory/features/inventory/services/image_service.dart';
import 'package:food_inventory/features/shipments/widgets/edit_item_dialog.dart';
import 'package:food_inventory/common/widgets/item_image_widget.dart';
import 'package:food_inventory/common/widgets/expiration_date_widget.dart';
import 'package:provider/provider.dart';

// Extracted widget for selected items to prevent parent rebuilds
class SelectedShipmentItemTile extends StatelessWidget {
  final ShipmentItem item;
  final Function(int quantity, DateTime? expirationDate) onEdit;
  final VoidCallback onRemove;

  const SelectedShipmentItemTile({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageService = Provider.of<ImageService>(context, listen: false);
    
    return Card(
      color: theme.colorScheme.surface,
      margin: const EdgeInsets.symmetric(vertical: 1),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        leading: ItemImageWidget(
          imagePath: item.itemDefinition?.imageUrl,
          itemName: item.itemDefinition?.name ?? 'Unknown Item',
          radius: 16,
          imageService: imageService,
        ),
        title: Text(
          item.itemDefinition?.name ?? 'Unknown Item',
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14),
        ),
        subtitle: item.expirationDate != null
            ? ExpirationDateWidget(
                expirationDate: item.expirationDate,
                fontSize: 12,
                iconSize: 12,
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${item.quantity}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.edit, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => _showEditDialog(context),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context) async {
    final dialogService = Provider.of<DialogService>(context, listen: false);
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EditItemDialog(
        item: item,
        dialogService: dialogService,
      ),
    );
    
    if (result != null) {
      onEdit(result['quantity'], result['expirationDate']);
    }
  }
}