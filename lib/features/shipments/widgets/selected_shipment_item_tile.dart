import 'package:flutter/material.dart';
import 'package:food_inventory/data/models/shipment_item.dart';
import 'package:food_inventory/common/services/dialog_service.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/features/shipments/widgets/edit_item_bottom_sheet.dart';
import 'package:food_inventory/common/widgets/item_image_widget.dart';
import 'package:food_inventory/common/widgets/expiration_date_widget.dart';
import 'package:provider/provider.dart';

// Extracted widget for selected items to prevent parent rebuilds
class SelectedShipmentItemTile extends StatelessWidget {
  final ShipmentItem item;
  final Function(int quantity, DateTime? expirationDate, double? unitPrice) onEdit;
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
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: ConfigService.tinyPadding, vertical: 1),
        leading: ItemImageWidget.circle(
          imagePath: item.itemDefinition?.imageUrl,
          itemName: item.itemDefinition?.name ?? 'Unknown Item',
          radius: 16,
        ),
        title: Text(
          item.itemDefinition?.name ?? 'Unknown Item',
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.expirationDate != null)
              ExpirationDateWidget(
                expirationDate: item.expirationDate,
                fontSize: 12,
                iconSize: ConfigService.tinyIconSize,
              ),
            if (item.unitPrice != null)
              Row(
                children: [
                  Icon(Icons.attach_money, size: ConfigService.tinyIconSize, color: theme.colorScheme.secondary),
                  SizedBox(width: ConfigService.tinyPadding),
                  Text(
                    ConfigService.formatCurrency(item.unitPrice!),
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: ConfigService.smallPadding, vertical: ConfigService.tinyPadding),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(ConfigService.borderRadiusMedium),
              ),
              child: Text(
                '${item.quantity}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            SizedBox(width: ConfigService.tinyPadding),
            IconButton(
              icon: const Icon(Icons.edit, size: ConfigService.smallIconSize),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => _showEditBottomSheet(context),
            ),
            SizedBox(width: ConfigService.tinyPadding),
            IconButton(
              icon: const Icon(Icons.delete, size: ConfigService.smallIconSize),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditBottomSheet(BuildContext context) async {
    final dialogService = Provider.of<DialogService>(context, listen: false);
    
    // Use the helper method to show the bottom sheet instead of dialog
    final result = await showEditItemBottomSheet(
      context,
      item,
      dialogService,
    );
    
    if (result != null) {
      onEdit(
        result['quantity'], 
        result['expirationDate'],
        result['unitPrice']
      );
    }
  }
}