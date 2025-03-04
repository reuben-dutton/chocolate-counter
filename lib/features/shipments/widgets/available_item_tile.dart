import 'package:flutter/material.dart';
import 'package:food_inventory/data/models/item_definition.dart';
import 'package:food_inventory/features/inventory/services/image_service.dart';
import 'package:food_inventory/common/widgets/item_image_widget.dart';


// Extracted widget for available items to prevent parent rebuilds
class AvailableItemTile extends StatelessWidget {
  final ItemDefinition item;
  final Function(ItemDefinition) onAdd;
  final ImageService imageService;

  const AvailableItemTile({
    super.key,
    required this.item,
    required this.onAdd,
    required this.imageService,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      leading: ItemImageWidget(
        imagePath: item.imageUrl,
        itemName: item.name,
        radius: 16,
        imageService: imageService,
      ),
      title: Text(
        item.name,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.add_circle, size: 20),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        onPressed: () => onAdd(item),
      ),
    );
  }
}