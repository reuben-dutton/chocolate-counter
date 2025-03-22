import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/data/models/item_definition.dart';
import 'package:food_inventory/features/inventory/services/image_service.dart';
import 'package:food_inventory/common/widgets/cached_image_widgets.dart';
import 'package:food_inventory/common/widgets/expiration_indicator.dart';
import 'package:provider/provider.dart';

class InventoryListItem extends StatelessWidget {
  final ItemDefinition itemDefinition;
  final int stockCount;
  final int inventoryCount;
  final bool isEmptyItem;
  final VoidCallback onTap;
  final DateTime? earliestExpirationDate;

  const InventoryListItem({
    super.key,
    required this.itemDefinition,
    required this.stockCount,
    required this.inventoryCount,
    required this.isEmptyItem,
    required this.onTap,
    this.earliestExpirationDate,
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
                _buildImageWithExpirationIndicator(context, imageService),
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
                      _buildStatusText(context, stockCount, inventoryCount, theme),
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
  
  Widget _buildImageWithExpirationIndicator(BuildContext context, ImageService imageService) {
    // Determine if we should show expiration indicator
    Color? indicatorColor;
    if (earliestExpirationDate != null) {
      final daysUntil = earliestExpirationDate!.difference(DateTime.now()).inDays;
      
      if (daysUntil < ConfigService.expirationWarningDays) {
        // Use the config service to get the appropriate color
        indicatorColor = ConfigService.getExpirationColor(context, earliestExpirationDate);
      }
    }
    
    return Stack(
      children: [
        ItemImageWidget(
          imagePath: itemDefinition.imageUrl,
          itemName: itemDefinition.name,
          radius: ConfigService.avatarRadiusMedium,
          imageService: imageService,
          memoryEfficient: true,
        ),
        if (indicatorColor != null)
          Positioned(
            top: 0,
            left: 0,
            child: ExpirationIndicator(
              color: indicatorColor,
              size: 14.0,
            ),
          ),
      ],
    );
  }
  
  Widget _buildStatusText(BuildContext context, int stockCount, int inventoryCount, ThemeData theme) {
    if (stockCount > 0) {
      return Text(
        'In Stock',
        style: TextStyle(
          color: theme.colorScheme.secondary,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      );
    } else if (inventoryCount > 0) {
      return Text(
        'In Inventory',
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      );
    } else {
      return Text(
        'Out of Stock',
        style: TextStyle(
          color: theme.colorScheme.error,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      );
    }
  }
}