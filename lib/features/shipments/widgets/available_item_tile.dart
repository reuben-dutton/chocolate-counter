import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/data/models/item_definition.dart';
import 'package:food_inventory/features/inventory/services/image_service.dart';
import 'package:food_inventory/common/widgets/cached_image_widgets.dart';
import 'package:provider/provider.dart';

// Extracted widget for available items to prevent parent rebuilds
class AvailableItemTile extends StatelessWidget {
  final ItemDefinition item;
  final Function(ItemDefinition) onAdd;

  const AvailableItemTile({
    super.key,
    required this.item,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final imageService = Provider.of<ImageService>(context, listen: false);
    
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: ConfigService.smallPadding, vertical: 0),
      leading: ItemImageWidget(
        imagePath: item.imageUrl,
        itemName: item.name,
        radius: 16,
        imageService: imageService,
        memoryEfficient: true,
      ),
      title: Text(
        item.name,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.add_circle, size: ConfigService.defaultIconSize),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        onPressed: () => onAdd(item),
      ),
    );
  }
}