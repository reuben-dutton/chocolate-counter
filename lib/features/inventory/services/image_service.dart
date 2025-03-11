import 'dart:io';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/common/utils/item_visualization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

// Parameters for resizing operation in isolate
class ResizeParams {
  final Uint8List imageData;
  final int targetSize;

  ResizeParams(this.imageData, this.targetSize);
}

// Result from isolate computation
class ResizeResult {
  final Uint8List resizedImageData;
  final String error;

  ResizeResult(this.resizedImageData, [this.error = '']);
}

/// Service for handling image operations in the application
class ImageService {
  final ImagePicker _picker = ImagePicker();
  
  // Cache manager for handling image caching with proper size limitations
  final DefaultCacheManager _cacheManager = DefaultCacheManager();
  
  // Image resizing constants
  final int _thumbnailSize = 128; // Size for list thumbnails
  
  // Track pending operations to avoid duplicates and enable cancellation
  final Map<String, Completer<File>> _pendingOperations = {};
  
  // Directory for storing thumbnail cache
  Directory? _thumbnailCacheDir;
  
  // Initialize thumbnail cache directory
  Future<Directory> _getThumbnailCacheDir() async {
    if (_thumbnailCacheDir != null) return _thumbnailCacheDir!;
    
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/thumbnails');
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }
      _thumbnailCacheDir = cacheDir;
      return cacheDir;
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error initializing thumbnail cache', e, stackTrace, 'ImageService');
      // Fallback to app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      _thumbnailCacheDir = appDir;
      return appDir;
    }
  }
  
  /// Take a photo using the device camera
  Future<File?> takePhoto() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,  // Limit max resolution to prevent excessive memory usage
        maxHeight: 1200,
        imageQuality: 85, // Good quality but still compressed
      );
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error taking photo', e, stackTrace, 'ImageService');
      return null;
    }
  }
  
  /// Select a photo from the device gallery
  Future<File?> pickPhoto() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,  // Limit max resolution to prevent excessive memory usage
        maxHeight: 1200,
        imageQuality: 85, // Good quality but still compressed
      );
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error picking photo', e, stackTrace, 'ImageService');
      return null;
    }
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
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error saving image', e, stackTrace, 'ImageService');
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
        
        // Also clear from cache
        await _cacheManager.removeFile(imagePath);
        
        // Also remove thumbnail if it exists
        await _deleteThumbnail(imagePath);
        
        return true;
      }
      ErrorHandler.logError('File does not exist', Exception('Path: $imagePath'), null, 'ImageService');
      return false;
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error deleting image', e, stackTrace, 'ImageService');
      return false;
    }
  }
  
  /// Delete thumbnail associated with an image path
  Future<void> _deleteThumbnail(String imagePath) async {
    try {
      final cacheDir = await _getThumbnailCacheDir();
      final thumbFileName = 'thumbnail_${path.basename(imagePath)}';
      final thumbFile = File('${cacheDir.path}/$thumbFileName');
      
      if (await thumbFile.exists()) {
        await thumbFile.delete();
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error deleting thumbnail', e, stackTrace, 'ImageService');
    }
  }

  /// Static isolate function for image resizing
  static Future<ResizeResult> _resizeImageInIsolate(ResizeParams params) async {
    try {
      final codec = await ui.instantiateImageCodec(
        params.imageData, 
        targetWidth: params.targetSize,
        targetHeight: params.targetSize,
      );
      
      final frameInfo = await codec.getNextFrame();
      final data = await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
      
      // Properly dispose of image after use
      frameInfo.image.dispose();
      
      if (data != null) {
        return ResizeResult(data.buffer.asUint8List());
      }
      
      return ResizeResult(Uint8List(0), 'Failed to encode image');
    } catch (e) {
      return ResizeResult(Uint8List(0), e.toString());
    }
  }
  
  /// Resize a file image using compute (lightweight isolate) for optimal memory usage
  Future<File> _resizeImageFile(File file, int targetSize) async {
    final cacheDir = await _getThumbnailCacheDir();
    final fileName = path.basename(file.path);
    final thumbnailFileName = 'thumbnail_$fileName';
    final thumbnailPath = '${cacheDir.path}/$thumbnailFileName';
    
    // Check if thumbnail already exists and is valid
    final thumbnailFile = File(thumbnailPath);
    if (await thumbnailFile.exists()) {
      try {
        final thumbnailStat = await thumbnailFile.stat();
        final originalStat = await file.stat();
        
        // Use thumbnail if it exists and original hasn't been modified since
        if (thumbnailStat.modified.isAfter(originalStat.modified)) {
          return thumbnailFile;
        }
      } catch (e) {
        // If stat fails, continue with resize operation
      }
    }
    
    // Check if there's a pending operation for this file
    final cacheKey = '${file.path}_resize';
    if (_pendingOperations.containsKey(cacheKey)) {
      return _pendingOperations[cacheKey]!.future;
    }
    
    // Create a completer to track this operation
    final completer = Completer<File>();
    _pendingOperations[cacheKey] = completer;
    
    try {
      // Read the file as bytes
      final bytes = await file.readAsBytes();
      
      // Use compute for isolate-based processing
      final result = await compute(_resizeImageInIsolate, ResizeParams(bytes, targetSize));
      
      if (result.error.isNotEmpty) {
        throw Exception(result.error);
      }
      
      if (result.resizedImageData.isEmpty) {
        throw Exception('Resize operation produced empty data');
      }
      
      // Create resized file
      await thumbnailFile.writeAsBytes(result.resizedImageData);
      completer.complete(thumbnailFile);
      return thumbnailFile;
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error resizing image', e, stackTrace, 'ImageService');
      // Return original on error, but still mark the operation as complete
      completer.complete(file);
      return file;
    } finally {
      // Remove from pending operations in all cases
      _pendingOperations.remove(cacheKey);
    }
  }
  
  /// Clean up old thumbnails that are no longer needed
  Future<void> cleanupThumbnailCache() async {
    try {
      final cacheDir = await _getThumbnailCacheDir();
      
      // Run this on a background isolate using compute
      await compute<String, void>((dirPath) async {
        final directory = Directory(dirPath);
        final files = await directory.list().toList();
        
        // Keep only 100 most recent files
        if (files.length > 100) {
          // Sort by modification time
          files.sort((a, b) {
            if (a is! File || b is! File) return 0;
            return b.lastModifiedSync().compareTo(a.lastModifiedSync());
          });
          
          // Delete old files
          for (int i = 100; i < files.length; i++) {
            if (files[i] is File) {
              await (files[i] as File).delete();
            }
          }
        }
      }, cacheDir.path);
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error cleaning up thumbnail cache', e, stackTrace, 'ImageService');
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
        // For network images, use a memory-efficient approach
        return FutureBuilder<File>(
          future: _cacheManager.getSingleFile(imagePath),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircleAvatar(
                radius: radius,
                backgroundColor: Colors.grey.shade300,
              );
            }
            
            if (snapshot.hasError || !snapshot.hasData) {
              return CircleAvatar(
                radius: radius,
                backgroundColor: Colors.grey,
                child: Icon(Icons.error_outline, color: Colors.white, size: radius * 0.8),
              );
            }
            
            return CircleAvatar(
              radius: radius,
              backgroundImage: FileImage(snapshot.data!),
              onBackgroundImageError: (_, __) {
                // Error handled by builder
              },
            );
          },
        );
      } else {
        // For local files, check if exists
        final file = File(imagePath);
        if (!file.existsSync()) {
          return CircleAvatar(
            radius: radius,
            backgroundColor: Colors.grey,
            child: Icon(Icons.image_not_supported, color: Colors.white, size: radius * 0.8),
          );
        }
        
        // Load the file but delegate thumbnail generation to a separate method
        return FutureBuilder<File>(
          future: _getOrCreateThumbnail(file),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Show a placeholder during loading
              return CircleAvatar(
                radius: radius,
                backgroundColor: Colors.grey.shade300,
              );
            }
            
            if (snapshot.hasError || !snapshot.hasData) {
              return CircleAvatar(
                radius: radius,
                backgroundColor: Colors.grey,
                child: Icon(Icons.error_outline, color: Colors.white, size: radius * 0.8),
              );
            }
            
            return CircleAvatar(
              radius: radius,
              backgroundImage: FileImage(snapshot.data!),
              onBackgroundImageError: (_, __) {
                // Error handled by builder
              },
            );
          },
        );
      }
    } catch (e, stackTrace) {
      // Fallback in case of any image loading errors
      ErrorHandler.logError('Error loading image', e, stackTrace, 'ImageService');
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey,
        child: Icon(Icons.image_not_supported, color: Colors.white, size: radius * 0.8),
      );
    }
  }
  
  /// Get or create a thumbnail for a file
  Future<File> _getOrCreateThumbnail(File file) async {
    final cacheKey = '${file.path}_thumb';
    
    // Check if there's a pending operation
    if (_pendingOperations.containsKey(cacheKey)) {
      return _pendingOperations[cacheKey]!.future;
    }
    
    // Create a new operation
    final completer = Completer<File>();
    _pendingOperations[cacheKey] = completer;
    
    try {
      final thumbnail = await _resizeImageFile(file, _thumbnailSize);
      completer.complete(thumbnail);
      return thumbnail;
    } catch (e) {
      // On error, return the original file
      completer.complete(file);
      return file;
    } finally {
      _pendingOperations.remove(cacheKey);
    }
  }
  
  /// Build a widget to display a full item image with fallback
  Widget buildFullItemImage(String? imagePath, String itemName, BuildContext context, {double? height = 220.0}) {
    if (imagePath == null) {
      final color = ItemVisualization.getColorForItem(itemName, context);
      final icon = ItemVisualization.getIconForItem(itemName);

      return Container(
        width: double.infinity,
        height: height,
        color: color,
        child: Icon(icon, size: 80, color: Colors.white),
      );
    }

    try {
      if (imagePath.startsWith('http')) {
        // For network images, use a simple Image with error handling
        return Image.network(
          imagePath,
          width: double.infinity,
          height: height,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: double.infinity,
              height: height,
              color: Colors.grey.shade300,
              child: const Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: double.infinity,
              height: height,
              color: Colors.grey.shade300,
              child: const Icon(Icons.image_not_supported, size: 80, color: Colors.white),
            );
          },
          cacheWidth: 800, // Limit memory usage by downsampling
        );
      } else {
        // Local file path
        final file = File(imagePath);
        if (!file.existsSync()) {
          return Container(
            width: double.infinity,
            height: height,
            color: Colors.grey.shade300,
            child: const Icon(Icons.image_not_supported, size: 80, color: Colors.white),
          );
        }
        
        // Use original size for full image display
        return Image.file(
          file,
          width: double.infinity,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            ErrorHandler.logError('Error displaying image', error, stackTrace, 'ImageService');
            
            return Container(
              width: double.infinity,
              height: height,
              color: Colors.grey.shade300,
              child: const Icon(Icons.image_not_supported, size: 80, color: Colors.white),
            );
          },
          cacheWidth: 800, // Limit memory usage by downsampling
        );
      }
    } catch (e, stackTrace) {
      // Fallback in case of any image loading errors
      ErrorHandler.logError('Error loading image', e, stackTrace, 'ImageService');
      return Container(
        width: double.infinity,
        height: height,
        color: Colors.grey.shade300,
        child: const Icon(Icons.image_not_supported, size: 80, color: Colors.white),
      );
    }
  }
  
  /// Clear the image cache and thumbnail cache
  Future<void> clearCache() async {
    await _cacheManager.emptyCache();
    
    // Clear thumbnail directory
    try {
      final cacheDir = await _getThumbnailCacheDir();
      final files = await cacheDir.list().toList();
      for (var file in files) {
        if (file is File) {
          await file.delete();
        }
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error clearing thumbnail cache', e, stackTrace, 'ImageService');
    }
  }
}