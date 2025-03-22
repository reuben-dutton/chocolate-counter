import 'package:flutter/material.dart';
import 'package:food_inventory/data/models/shipment_item.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/common/widgets/expiration_date_widget.dart';
import 'package:food_inventory/common/widgets/cached_image_widgets.dart';
import 'package:food_inventory/features/inventory/services/image_service.dart';
import 'package:food_inventory/features/shipments/widgets/expiration_edit_bottom_sheet.dart';
import 'package:provider/provider.dart';

class ShipmentItemList extends StatelessWidget {
  final List<dynamic> items;
  final Function(int, DateTime?)? onExpirationDateChanged;

  const ShipmentItemList({
    super.key,
    required this.items,
    this.onExpirationDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final imageService = Provider.of<ImageService>(context, listen: false);
    final theme = Theme.of(context);
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index] as ShipmentItem;
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: ConfigService.tinyPadding, vertical: ConfigService.tinyPadding),
          leading: ItemImageWidget(
            imagePath: item.itemDefinition?.imageUrl,
            itemName: item.itemDefinition?.name ?? 'Unknown Item',
            radius: 18,
            imageService: imageService,
            memoryEfficient: true,
          ),
          title: Text(
            item.itemDefinition?.name ?? 'Unknown Item',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExpirationDateWidget(
                expirationDate: item.expirationDate,
                iconSize: ConfigService.tinyIconSize,
                fontSize: 12,
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Add edit button for expiration date if the callback is provided
              if (onExpirationDateChanged != null)
                IconButton(
                  icon: const Icon(Icons.edit_calendar, size: ConfigService.smallIconSize),
                  padding: EdgeInsets.all(ConfigService.tinyPadding),
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Edit expiration date',
                  onPressed: () => _showExpirationEditBottomSheet(context, item),
                ),
              SizedBox(width: ConfigService.smallPadding),
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
  
  void _showExpirationEditBottomSheet(BuildContext context, ShipmentItem item) async {
    if (item.id == null) return;
    
    // Use the bottom sheet instead of dialog
    final newExpirationDate = await showExpirationEditBottomSheet(
      context,
      item,
    );
    
    // If a date was selected and the callback exists, trigger it
    if (onExpirationDateChanged != null) {
      onExpirationDateChanged!(item.id!, newExpirationDate);
    }
  }
}