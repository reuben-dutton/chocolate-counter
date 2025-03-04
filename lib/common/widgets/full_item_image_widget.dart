import 'package:flutter/material.dart';
import 'package:food_inventory/features/inventory/services/image_service.dart';
import 'package:provider/provider.dart';

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
    final service = imageService ?? Provider.of<ImageService>(context);
    
    return SizedBox(
      height: height,
      width: double.infinity,
      child: service.buildFullItemImage(imagePath, itemName, context),
    );
  }
}