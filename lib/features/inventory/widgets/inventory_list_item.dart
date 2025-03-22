import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/data/models/item_definition.dart';
import 'package:food_inventory/features/inventory/services/image_service.dart';
import 'package:food_inventory/common/widgets/count_chip_widget.dart';
import 'package:food_inventory/common/widgets/cached_image_widgets.dart';
import 'package:provider/provider.dart';

class InventoryListItem extends StatelessWidget {
  final ItemDefinition itemDefinition;
  final int stockCount;
  final int inventoryCount;
  final bool isEmptyItem;
  final VoidCallback onTap;

  const InventoryListItem({
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
    final imageService = Provider.of<ImageService>(context);
    
    return Opacity(
      opacity: isEmptyItem ? 0.5 : 1.0,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: ConfigService.smallPadding, vertical: ConfigService.tinyPadding),
        child: InkWell(
          borderRadius: BorderRadius.circular(ConfigService.borderRadiusMedium),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(ConfigService.smallPadding),
            child: Row(
              children: [
                ItemImageWidget(
                  imagePath: itemDefinition.imageUrl,
                  itemName: itemDefinition.name,
                  radius: ConfigService.avatarRadiusMedium,
                  imageService: imageService,
                  memoryEfficient: true,
                ),
                SizedBox(width: ConfigService.mediumPadding),
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
                      SizedBox(height: ConfigService.tinyPadding),
                      Row(
                        children: [
                          CountChipWidget(
                            icon: Icons.shopping_cart,
                            count: stockCount,
                            color: theme.colorScheme.secondary,
                          ),
                          SizedBox(width: ConfigService.smallPadding),
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
                  size: ConfigService.mediumIconSize, 
                  color: theme.colorScheme.onSurface.withAlpha(ConfigService.alphaDefault)
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}