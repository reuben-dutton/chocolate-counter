import 'package:flutter/material.dart';
import 'package:food_inventory/features/inventory/services/image_service.dart';
import 'package:provider/provider.dart';

class ItemImageWidget extends StatelessWidget {
  final String? imagePath;
  final String itemName;
  final double radius;
  final ImageService? imageService;

  ItemImageWidget({
    super.key,
    required this.imagePath,
    required this.itemName,
    this.radius = 24.0,
    this.imageService,
  });

  @override
  Widget build(BuildContext context) {
    final _imageService = imageService ?? Provider.of<ImageService>(context);
    
    return _imageService.buildItemImage(imagePath, itemName, context, radius: radius);
  }
}