import 'package:flutter/material.dart';
import 'package:food_inventory/services/image_service.dart';

class FullItemImageWidget extends StatelessWidget {
  final String? imagePath;
  final String itemName;
  final ImageService? imageService;
  final double? height;

  FullItemImageWidget({
    super.key,
    required this.imagePath,
    required this.itemName,
    this.imageService,
    this.height = 220.0,
  });

  @override
  Widget build(BuildContext context) {
    final ImageService service = imageService ?? ImageService();
    
    return Container(
      height: height,
      width: double.infinity,
      child: service.buildFullItemImage(imagePath, itemName, context),
    );
  }
}