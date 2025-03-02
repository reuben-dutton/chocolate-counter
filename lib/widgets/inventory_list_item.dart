import 'package:flutter/material.dart';
import 'package:food_inventory/models/item_definition.dart';
import 'package:food_inventory/utils/item_visualization.dart';
import 'dart:io';

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
                _buildItemImage(context),
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
                          _buildCountChip(
                            context, 
                            Icons.shopping_cart, 
                            stockCount, 
                            theme.colorScheme.secondary
                          ),
                          const SizedBox(width: 8),
                          _buildCountChip(
                            context, 
                            Icons.inventory_2, 
                            inventoryCount, 
                            theme.colorScheme.secondary
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
  
  Widget _buildCountChip(BuildContext context, IconData icon, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildItemImage(BuildContext context) {
    if (itemDefinition.imageUrl == null) {
      final color = ItemVisualization.getColorForItem(itemDefinition.name, context);
      final icon = ItemVisualization.getIconForItem(itemDefinition.name);

      return CircleAvatar(
        radius: 24,
        backgroundColor: color,
        child: Icon(icon, color: Colors.white, size: 20),
      );
    }
    
    final String imagePath = itemDefinition.imageUrl!;
    
    try {
      if (imagePath.startsWith('http')) {
        // Remote URL
        return CircleAvatar(
          radius: 24,
          backgroundImage: NetworkImage(imagePath),
        );
      } else {
        // Local file path
        return CircleAvatar(
          radius: 24,
          backgroundImage: FileImage(File(imagePath)),
        );
      }
    } catch (e) {
      // Fallback in case of any image loading errors
      print('Error loading image: $e');
      return CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey,
        child: Icon(Icons.image_not_supported, color: Colors.white, size: 20),
      );
    }
  }
}