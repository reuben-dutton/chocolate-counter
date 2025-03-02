import 'package:flutter/material.dart';
import 'package:food_inventory/services/image_service.dart';

class ItemImageWidget extends StatelessWidget {
  final String? imagePath;
  final String itemName;
  final double radius;
  final ImageService _imageService;

  ItemImageWidget({
    super.key,
    required this.imagePath,
    required this.itemName,
    this.radius = 24.0,
    ImageService? imageService,
  }) : _imageService = imageService ?? ImageService();

  @override
  Widget build(BuildContext context) {
    return _imageService.buildItemImage(imagePath, itemName, context, radius: radius);
  }
}