import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/common/utils/item_visualization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:compute/compute.dart';

// Message for isolate to resize an image
class _CompressImageParams {
  final String inputPath;
  final String outputPath;
  final int targetSize;

  _CompressImageParams({
    required this.inputPath,
    required this.outputPath, 
    required this.targetSize,
  });
}

// Static method for isolate to process image resizing
Future<bool> _isolateCompressImage(_CompressImageParams params) async {
  try {
    final result = await FlutterImageCompress.compressAndGetFile(
      params.inputPath,
      params.outputPath,
      minWidth: params.targetSize,
      minHeight: params.targetSize,
      quality: 85,
    );
    
    return result != null;
  } catch (e) {
    return false;
  }
}

/// Service for handling image operations in the application
class ImageService {
  final ImagePicker _picker = ImagePicker();
  
  // Cache manager instance
  final CacheManager _cacheManager = CacheManager(
    Config(
      'imageCache',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 100,
      repo: JsonCacheInfoRepository(databaseName: 'imageCache'),
      fileService: HttpFileService(),
    ),
  );
  
  // Image resizing constants
  final int _thumbnailSize = 128; // Size for list thumbnails
  
  // Directory for storing thumbnail cache
  Directory? _thumbnailCacheDir;
  
  // Constructor
  ImageService() {
    _initThumbnailCache();
  }
  
  // Initialize thumbnail cache directory
  Future<void> _initThumbnailCache() async {
    if (_thumbnailCacheDir != null) return;
    
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/thumbnails');
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }
      _thumbnailCacheDir = cacheDir;
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error initializing thumbnail cache', e, stackTrace, 'ImageService');
    }
  }
  
  /// Take a photo using the device camera
  Future<File?> takePhoto() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
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
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
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
        
        // Also remove thumbnail if it exists
        await _deleteThumbnail(imagePath);
        
        // Clear CacheManager entry if exists
        final fileUrl = 'file://$imagePath';
        await _cacheManager.removeFile(fileUrl);
        
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
      await _initThumbnailCache();
      if (_thumbnailCacheDir == null) return;
      
      final thumbFileName = 'thumbnail_${path.basename(imagePath)}';
      final thumbFile = File('${_thumbnailCacheDir!.path}/$thumbFileName');
      
      if (await thumbFile.exists()) {
        await thumbFile.delete();
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error deleting thumbnail', e, stackTrace, 'ImageService');
    }
  }
  
  /// Resize a file image for optimal memory usage in lists
  Future<File> _resizeImageFile(File file, int targetSize) async {
    await _initThumbnailCache();
    if (_thumbnailCacheDir == null) {
      return file; // Fallback if cache dir initialization failed
    }
    
    final fileName = path.basename(file.path);
    final thumbnailFileName = 'thumbnail_$fileName';
    final thumbnailPath = '${_thumbnailCacheDir!.path}/$thumbnailFileName';
    
    // Check if thumbnail already exists
    final thumbnailFile = File(thumbnailPath);
    if (await thumbnailFile.exists()) {
      return thumbnailFile;
    }
    
    try {
      // For small operations on a UI thread, use compute
      if (file.lengthSync() < 500 * 1024) { // Files under 500KB
        return await compute<_CompressImageParams, File>(
          (_CompressImageParams params) async {
            final success = await _isolateCompressImage(params);
            if (success) {
              return File(params.outputPath);
            }
            return File(params.inputPath);
          },
          _CompressImageParams(
            inputPath: file.path,
            outputPath: thumbnailPath,
            targetSize: targetSize,
          ),
        );
      } else {
        // For larger files, use Flutter Image Compress
        final compressed = await FlutterImageCompress.compressAndGetFile(
          file.path,
          thumbnailPath,
          minWidth: targetSize,
          minHeight: targetSize,
          quality: 85,
        );
        
        if (compressed != null) {
          return File(compressed.path);
        }
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error resizing image', e, stackTrace, 'ImageService');
    }
    
    // Return original on error
    return file;
  }
  
  /// Clean up old thumbnails that are no longer needed
  Future<void> cleanupThumbnailCache() async {
    try {
      await _initThumbnailCache();
      if (_thumbnailCacheDir == null) return;
      
      final files = await _thumbnailCacheDir!.list().toList();
      const maxCacheSize = 100; // Maximum number of files to keep
      
      // Keep only most recent files (up to max cache size)
      if (files.length > maxCacheSize * 2) {
        // Sort by modification time (newest first)
        files.sort((a, b) {
          if (a is! File || b is! File) return 0;
          return b.lastModifiedSync().compareTo(a.lastModifiedSync());
        });
        
        // Delete old files
        for (int i = maxCacheSize * 2; i < files.length; i++) {
          if (files[i] is File) {
            try {
              await (files[i] as File).delete();
            } catch (e) {
              // Ignore errors during cleanup
            }
          }
        }
      }
      
      // Also purge Flutter Cache Manager's old cache
      await _cacheManager.emptyCache();
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error cleaning up thumbnail cache', e, stackTrace, 'ImageService');
    }
  }
  
  /// Build a widget to display an item image with fallback
  Widget buildItemImage(String? imagePath, String itemName, BuildContext context, {double radius = ConfigService.avatarRadiusMedium}) {
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
      // Local file handling
      final file = File(imagePath);
      if (!file.existsSync()) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey,
          child: Icon(Icons.image_not_supported, color: Colors.white, size: radius * 0.8),
        );
      }
      
      // This will use the cached memory provider and start the resize in the background
      _resizeImageFile(file, _thumbnailSize).then((resizedFile) {
        // The resizing is now handled in the background
      });
      
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(file),
        onBackgroundImageError: (_, __) {
          // Error fallback is handled in onError
        },
      );
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
  
  /// Build a widget to display a full item image with fallback
  Widget buildFullItemImage(String? imagePath, String itemName, BuildContext context, {double? height = 220.0}) {
    if (imagePath == null) {
      final color = ItemVisualization.getColorForItem(itemName, context);
      final icon = ItemVisualization.getIconForItem(itemName);

      return Container(
        width: double.infinity,
        height: height,
        color: color,
        child: Icon(icon, size: ConfigService.xxLargeIconSize, color: Colors.white),
      );
    }

    try {
      // Local file path
      final file = File(imagePath);
      if (!file.existsSync()) {
        return Container(
          width: double.infinity,
          height: height,
          color: Colors.grey.shade300,
          child: const Icon(Icons.image_not_supported, size: ConfigService.xxLargeIconSize, color: Colors.white),
        );
      }
      
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
            child: const Icon(Icons.image_not_supported, size: ConfigService.xxLargeIconSize, color: Colors.white),
          );
        },
      );
    } catch (e, stackTrace) {
      // Fallback in case of any image loading errors
      ErrorHandler.logError('Error loading image', e, stackTrace, 'ImageService');
      return Container(
        width: double.infinity,
        height: height,
        color: Colors.grey.shade300,
        child: const Icon(Icons.image_not_supported, size: ConfigService.xxLargeIconSize, color: Colors.white),
      );
    }
  }
  
  /// Clear the image cache and thumbnail cache
  Future<void> clearCache() async {
    await _cacheManager.emptyCache();
    
    // Clear thumbnail directory
    try {
      await _initThumbnailCache();
      if (_thumbnailCacheDir == null) return;
      
      final files = await _thumbnailCacheDir!.list().toList();
      for (var file in files) {
        if (file is File) {
          try {
            await file.delete();
          } catch (e) {
            // Ignore errors during deletion
          }
        }
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error clearing thumbnail cache', e, stackTrace, 'ImageService');
    }
  }
  
  /// Dispose of resources when service is no longer needed
  void dispose() {
    _cacheManager.dispose();
  }
}