import 'dart:io';
import 'package:flutter/material.dart';
import 'package:food_inventory/common/utils/item_visualization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Service for handling image operations in the application
class ImageService {
  final ImagePicker _picker = ImagePicker();
  
  /// Take a photo using the device camera
  Future<File?> takePhoto() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }
  
  /// Select a photo from the device gallery
  Future<File?> pickPhoto() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }
  
  /// Save an image to the application documents directory
  Future<String?> saveImage(File? imageFile) async {
    if (imageFile == null) return null;
    
    try {
      // Get application documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'item_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
      final savedImage = await imageFile.copy('${appDir.path}/$fileName');
      return savedImage.path;
    } catch (e) {
      print('Error saving image: $e');
      return null;
    }
  }
  
  /// Delete an image from the application documents directory
  Future<bool> deleteImage(String? imagePath) async {
    if (imagePath == null || imagePath.startsWith('http')) return false;
    
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        print('Successfully deleted file: $imagePath');
        return true;
      }
      print('File does not exist: $imagePath');
      return false;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }
  
  /// Build a widget to display an item image with fallback
  Widget buildItemImage(String? imagePath, String itemName, BuildContext context, {double radius = 24.0}) {
    if (imagePath == null) {
      final color = ItemVisualization.getColorForItem(itemName, context);
      final icon = ItemVisualization.getIconForItem(itemName);

      return CircleAvatar(
        radius: radius,
        backgroundColor: color,
        child: Icon(icon, color: Colors.white, size: radius * 0.8),
      );
    }
    
    try {
      if (imagePath.startsWith('http')) {
        // Remote URL
        return CircleAvatar(
          radius: radius,
          backgroundImage: NetworkImage(imagePath),
          onBackgroundImageError: (_, __) {},
        );
      } else {
        // Local file path
        final file = File(imagePath);
        if (!file.existsSync()) {
          return CircleAvatar(
            radius: radius,
            backgroundColor: Colors.grey,
            child: Icon(Icons.image_not_supported, color: Colors.white, size: radius * 0.8),
          );
        }
        return CircleAvatar(
          radius: radius,
          backgroundImage: FileImage(file),
          onBackgroundImageError: (_, __) {},
        );
      }
    } catch (e) {
      // Fallback in case of any image loading errors
      print('Error loading image: $e');
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey,
        child: Icon(Icons.image_not_supported, color: Colors.white, size: radius * 0.8),
      );
    }
  }
  
  /// Build a widget to display a full item image with fallback
  Widget buildFullItemImage(String? imagePath, String itemName, BuildContext context) {
    if (imagePath == null) {
      final color = ItemVisualization.getColorForItem(itemName, context);
      final icon = ItemVisualization.getIconForItem(itemName);

      return Container(
        width: double.infinity,
        height: 180,
        color: color,
        child: Icon(icon, size: 80, color: Colors.white),
      );
    }

    try {
      if (imagePath.startsWith('http')) {
        // Remote URL
        return Image.network(
          imagePath,
          width: double.infinity,
          height: 220,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: double.infinity,
              height: 220,
              color: Colors.grey.shade300,
              child: const Icon(Icons.image_not_supported, size: 80, color: Colors.white),
            );
          },
        );
      } else {
        // Local file path
        return Image.file(
          File(imagePath),
          width: double.infinity,
          height: 220,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: double.infinity,
              height: 220,
              color: Colors.grey.shade300,
              child: const Icon(Icons.image_not_supported, size: 80, color: Colors.white),
            );
          },
        );
      }
    } catch (e) {
      // Fallback in case of any image loading errors
      print('Error loading image: $e');
      return Container(
        width: double.infinity,
        height: 220,
        color: Colors.grey.shade300,
        child: const Icon(Icons.image_not_supported, size: 80, color: Colors.white),
      );
    }
  }
}