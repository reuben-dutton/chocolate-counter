import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:food_inventory/features/inventory/services/image_service.dart';
import 'package:provider/provider.dart';

/// A memory-efficient cached network image widget
class CachedNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final DefaultCacheManager? cacheManager;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;
  
  const CachedNetworkImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.cacheManager,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final effectiveCacheManager = cacheManager ?? DefaultCacheManager();
    
    final defaultPlaceholder = Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: const Center(child: CircularProgressIndicator()),
    );
    
    final defaultErrorWidget = Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
    
    return FutureBuilder<File>(
      future: effectiveCacheManager.getSingleFile(imageUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return placeholder?.call(context, imageUrl) ?? defaultPlaceholder;
        }
        
        if (snapshot.hasError || !snapshot.hasData) {
          return errorWidget?.call(context, imageUrl, snapshot.error) ?? defaultErrorWidget;
        }
        
        return Image.file(
          snapshot.data!,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return errorWidget?.call(context, imageUrl, error) ?? defaultErrorWidget;
          },
        );
      },
    );
  }
}

/// A memory-efficient image widget that handles both network and local file images
class ItemImageWidget extends StatelessWidget {
  final String? imagePath;
  final String itemName;
  final double radius;
  final ImageService? imageService;
  final bool memoryEfficient;

  const ItemImageWidget({
    Key? key,
    required this.imagePath,
    required this.itemName,
    this.radius = 24.0,
    this.imageService,
    this.memoryEfficient = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final service = imageService ?? Provider.of<ImageService>(context);
    
    // If memoryEfficient is enabled, use the optimized version
    if (memoryEfficient) {
      return service.buildItemImage(imagePath, itemName, context, radius: radius);
    }
    
    // Original implementation (kept for backward compatibility)
    if (imagePath == null) {
      // Fallback icon logic
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade300,
        child: Icon(Icons.image, color: Colors.white, size: radius * 0.8),
      );
    }
    
    return CircleAvatar(
      radius: radius,
      backgroundImage: imagePath!.startsWith('http')
          ? NetworkImage(imagePath!) as ImageProvider
          : FileImage(File(imagePath!)),
      onBackgroundImageError: (_, __) {
        // Fallback on error
      },
    );
  }
}

/// A memory-efficient full image widget for item details
class FullItemImageWidget extends StatelessWidget {
  final String? imagePath;
  final String itemName;
  final ImageService? imageService;
  final double? height;
  final bool memoryEfficient;

  const FullItemImageWidget({
    Key? key,
    required this.imagePath,
    required this.itemName,
    this.imageService,
    this.height = 220.0,
    this.memoryEfficient = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final service = imageService ?? Provider.of<ImageService>(context);
    
    // If memoryEfficient is enabled, use the optimized version
    if (memoryEfficient) {
      return service.buildFullItemImage(imagePath, itemName, context, height: height);
    }
    
    // Original implementation (kept for backward compatibility)
    if (imagePath == null) {
      // Fallback icon logic
      return Container(
        height: height,
        width: double.infinity,
        color: Colors.grey.shade300,
        child: Icon(Icons.image, size: 80, color: Colors.white),
      );
    }
    
    return SizedBox(
      height: height,
      width: double.infinity,
      child: imagePath!.startsWith('http')
          ? Image.network(
              imagePath!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.broken_image, size: 80, color: Colors.white),
                );
              },
            )
          : Image.file(
              File(imagePath!),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.broken_image, size: 80, color: Colors.white),
                );
              },
            ),
    );
  }
}