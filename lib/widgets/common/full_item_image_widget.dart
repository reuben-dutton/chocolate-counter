import 'package:flutter/material.dart';
import 'package:food_inventory/services/image_service.dart';

class FullItemImageWidget extends StatelessWidget {
  final String? imagePath;
  final String itemName;
  final ImageService _imageService;

  FullItemImageWidget({
    super.key,
    required this.imagePath,
    required this.itemName,
    ImageService? imageService,
  }) : _imageService = imageService ?? ImageService();

  @override
  Widget build(BuildContext context) {
    return _imageService.buildFullItemImage(imagePath, itemName, context);
  }
}