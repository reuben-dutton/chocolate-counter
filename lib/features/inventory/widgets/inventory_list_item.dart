import 'package:flutter/material.dart';
import 'package:food_inventory/data/models/item_definition.dart';
import 'package:food_inventory/features/inventory/services/image_service.dart';
import 'package:food_inventory/common/services/service_locator.dart';
import 'package:food_inventory/common/widgets/count_chip_widget.dart';
import 'package:food_inventory/common/widgets/item_image_widget.dart';

class InventoryListItem extends StatelessWidget {
  final ItemDefinition itemDefinition;
  final int stockCount;
  final int inventoryCount;
  final bool isEmptyItem;
  final VoidCallback onTap;
  final ImageService _imageService = ServiceLocator.instance<ImageService>();

  InventoryListItem({
    super.key,
    required this.itemDefinition,
    required this.stockCount,
    required this.inventoryCount,
    required this.isEmptyItem,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Opacity(
      opacity: isEmptyItem ? 0.5 : 1.0,
      child: Card(
        color: theme.colorScheme.surface,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ItemImageWidget(
                  imagePath: itemDefinition.imageUrl,
                  itemName: itemDefinition.name,
                  radius: 24,
                  imageService: _imageService,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        itemDefinition.name,
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          CountChipWidget(
                            icon: Icons.shopping_cart,
                            count: stockCount,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          CountChipWidget(
                            icon: Icons.inventory_2,
                            count: inventoryCount,
                            color: theme.colorScheme.secondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right, 
                  size: 20, 
                  color: theme.colorScheme.onSurface.withAlpha(128)
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}