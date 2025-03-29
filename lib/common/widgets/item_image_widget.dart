import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/features/inventory/services/image_service.dart';
import 'package:provider/provider.dart';

/// A unified widget for displaying item images
/// Handles both avatar-style (circle) and full-size (rectangle) displays
class ItemImageWidget extends StatelessWidget {
  final String? imagePath;
  final String itemName;
  final double? height;
  final double radius;
  final bool isFullSize;
  final BoxFit fit;

  /// Construct an item image widget
  /// 
  /// [isFullSize] determines whether to display as a full-size image or a circular avatar
  /// [height] is used for full-size images (width is always full width)
  /// [radius] is used for circle avatars (defaults to ConfigService.avatarRadiusMedium)
  const ItemImageWidget({
    Key? key,
    required this.imagePath,
    required this.itemName,
    this.height = 220.0,
    this.radius = ConfigService.avatarRadiusMedium,
    this.isFullSize = false,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  /// Shorthand constructor for creating a circle avatar image
  factory ItemImageWidget.circle({
    Key? key,
    required String? imagePath,
    required String itemName,
    double radius = ConfigService.avatarRadiusMedium,
  }) {
    return ItemImageWidget(
      key: key,
      imagePath: imagePath,
      itemName: itemName,
      radius: radius,
      isFullSize: false,
    );
  }

  /// Shorthand constructor for creating a full-size image
  factory ItemImageWidget.full({
    Key? key,
    required String? imagePath,
    required String itemName,
    double? height = 220.0,
    BoxFit fit = BoxFit.cover,
  }) {
    return ItemImageWidget(
      key: key,
      imagePath: imagePath,
      itemName: itemName,
      height: height,
      isFullSize: true,
      fit: fit,
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageService = Provider.of<ImageService>(context, listen: false);
    
    if (isFullSize) {
      return imageService.buildFullItemImage(imagePath, itemName, context, height: height);
    } else {
      return imageService.buildItemImage(imagePath, itemName, context, radius: radius);
    }
  }
}