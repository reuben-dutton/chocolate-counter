import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/common/utils/item_visualization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:math' as math;
import 'dart:async';

// Parameters for resizing operation
class ResizeParams {
  final String filePath;
  final int targetSize;
  final String outputPath;

  ResizeParams(this.filePath, this.targetSize, this.outputPath);
}

/// Service for handling image operations in the application
class ImageService {
  final ImagePicker _picker = ImagePicker();
  
  // LRU Cache implementation
  final int _maxCacheSize = 100; // Maximum number of images to cache
  final Map<String, ImageProvider> _imageCache = {};
  final List<String> _cacheOrder = []; // Tracks access order for LRU policy
  
  // Image resizing constants
  final int _thumbnailSize = 128; // Size for list thumbnails
  
  // Track pending operations to avoid duplicates
  final Map<String, Future<File>> _pendingOperations = {};
  
  // Directory for storing thumbnail cache
  Directory? _thumbnailCacheDir;
  
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
      // Don't rethrow, try to continue without cache
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
        
        // Also remove from cache if present
        if (_imageCache.containsKey(imagePath)) {
          _imageCache.remove(imagePath);
          _cacheOrder.remove(imagePath);
        }
        
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
      await _initThumbnailCache();
      final thumbFileName = 'thumbnail_${path.basename(imagePath)}';
      final thumbFile = File('${_thumbnailCacheDir!.path}/$thumbFileName');
      
      if (await thumbFile.exists()) {
        await thumbFile.delete();
        
        // Remove from cache
        final thumbCacheKey = '${imagePath}_thumb';
        _imageCache.remove(thumbCacheKey);
        _cacheOrder.remove(thumbCacheKey);
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error deleting thumbnail', e, stackTrace, 'ImageService');
    }
  }

  /// Add an image to the cache with LRU eviction policy
  void _addToCache(String key, ImageProvider imageProvider) {
    // First check if we need to evict
    if (_cacheOrder.length >= _maxCacheSize && !_imageCache.containsKey(key)) {
      // Remove least recently used item
      final lruKey = _cacheOrder.removeAt(0);
      _imageCache.remove(lruKey);
    }
    
    // Update cache
    _imageCache[key] = imageProvider;
    
    // Update access order (remove if exists, then add to end)
    _cacheOrder.remove(key);
    _cacheOrder.add(key);
  }
  
  /// Get image from cache, updating its position in LRU order
  /// Validates the cache entry against file modification time
  ImageProvider? _getFromCache(String key) {
    final imageProvider = _imageCache[key];
    
    // For file-based images, check if source file has been modified
    if (imageProvider != null && imageProvider is FileImage) {
      try {
        final file = File(imageProvider.file.path);
        if (file.existsSync()) {
          // Extract timestamp from key if it exists
          final keyParts = key.split('_ts_');
          if (keyParts.length > 1) {
            final cachedTimestamp = int.tryParse(keyParts[1]);
            if (cachedTimestamp != null) {
              final currentTimestamp = file.lastModifiedSync().millisecondsSinceEpoch;
              // If file was modified after cache entry was created, invalidate cache
              if (currentTimestamp > cachedTimestamp) {
                _imageCache.remove(key);
                _cacheOrder.remove(key);
                return null;
              }
            }
          }
        }
      } catch (e, stackTrace) {
        ErrorHandler.logError('Error validating cache entry', e, stackTrace, 'ImageService');
      }
    }
    
    if (imageProvider != null) {
      // Update access order by moving to the end
      _cacheOrder.remove(key);
      _cacheOrder.add(key);
    }
    return imageProvider;
  }
  
  /// Resize a file image for optimal memory usage in lists
  Future<File> _resizeImageFile(File file, int targetSize) async {
    await _initThumbnailCache();
    final fileName = path.basename(file.path);
    final thumbnailFileName = 'thumbnail_$fileName';
    final thumbnailPath = '${_thumbnailCacheDir!.path}/$thumbnailFileName';
    
    // Check if thumbnail already exists
    final thumbnailFile = File(thumbnailPath);
    if (await thumbnailFile.exists()) {
      return thumbnailFile;
    }
    
    // Check if there's a pending operation for this file
    final cacheKey = '${file.path}_resize';
    if (_pendingOperations.containsKey(cacheKey)) {
      return _pendingOperations[cacheKey]!;
    }
    
    // New approach to resize image using raw bytes
    final resizeOperation = Future<File>(() async {
      try {
        // Read the file bytes
        final bytes = await file.readAsBytes();
        
        // Decode the image
        final codec = await ui.instantiateImageCodec(
          bytes,
          targetWidth: targetSize,
          targetHeight: targetSize,
        );
        
        // Get the first frame
        final frameInfo = await codec.getNextFrame();
        
        // Convert to PNG bytes
        final pngBytes = await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
        
        if (pngBytes != null) {
          // Write the resized image to file
          final thumbnailFile = File(thumbnailPath);
          await thumbnailFile.writeAsBytes(pngBytes.buffer.asUint8List());
          
          // Dispose of the image to free up resources
          frameInfo.image.dispose();
          
          return thumbnailFile;
        }
        
        // Fallback if conversion fails
        return file;
      } catch (e, stackTrace) {
        ErrorHandler.logError('Error resizing image', e, stackTrace, 'ImageService');
        return file; // Return original on error
      } finally {
        // Always remove from pending operations
        _pendingOperations.remove(cacheKey);
      }
    });
    
    // Register pending operation
    _pendingOperations[cacheKey] = resizeOperation;
    
    return resizeOperation;
  }
  
  /// Clean up old thumbnails that are no longer needed
  Future<void> cleanupThumbnailCache() async {
    try {
      await _initThumbnailCache();
      final files = await _thumbnailCacheDir!.list().toList();
      
      // Keep only most recent files (up to max cache size)
      if (files.length > _maxCacheSize * 2) { // Use a multiplier for buffer
        // Sort by modification time
        files.sort((a, b) {
          if (a is! File || b is! File) return 0;
          return b.lastModifiedSync().compareTo(a.lastModifiedSync());
        });
        
        // Delete old files
        for (int i = _maxCacheSize * 2; i < files.length; i++) {
          if (files[i] is File) {
            await (files[i] as File).delete();
          }
        }
      }
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
      // For local file paths, get timestamp for cache validation
      int? fileTimestamp;
      if (!imagePath.startsWith('http')) {
        try {
          final file = File(imagePath);
          if (file.existsSync()) {
            fileTimestamp = file.lastModifiedSync().millisecondsSinceEpoch;
          }
        } catch (e, stackTrace) {
          ErrorHandler.logError('Error getting file timestamp', e, stackTrace, 'ImageService');
        }
      }
      
      // For thumbnail version, use a unique cache key with timestamp
      final String cacheKey = fileTimestamp != null 
          ? '${imagePath}_thumb_ts_$fileTimestamp' 
          : '${imagePath}_thumb';
      ImageProvider? imageProvider = _getFromCache(cacheKey);
      
      if (imageProvider == null) {
        if (imagePath.startsWith('http')) {
          // For network images, we use ResizeImage for memory efficiency
          imageProvider = ResizeImage(
            NetworkImage(imagePath),
            width: _thumbnailSize,
            height: _thumbnailSize,
          );
          _addToCache(cacheKey, imageProvider);
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
          
          // Use file initially
          imageProvider = FileImage(file);
          _addToCache(cacheKey, imageProvider);
          
          // Start async resize operation
          _resizeImageFile(file, _thumbnailSize).then((resizedFile) {
            final resizedProvider = FileImage(resizedFile);
            _addToCache(cacheKey, resizedProvider);
            
            // Schedule cleanup occasionally
            if (math.Random().nextInt(100) < 5) { // 5% chance
              cleanupThumbnailCache();
            }
          });
        }
      }
      
      return CircleAvatar(
        radius: radius,
        backgroundImage: imageProvider,
        onBackgroundImageError: (_, __) {
          // On error, remove from cache
          _imageCache.remove(cacheKey);
          _cacheOrder.remove(cacheKey);
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
        child: Icon(icon, size: 80, color: Colors.white),
      );
    }

    try {
      // For local file paths, get timestamp for cache validation
      int? fileTimestamp;
      if (!imagePath.startsWith('http')) {
        try {
          final file = File(imagePath);
          if (file.existsSync()) {
            fileTimestamp = file.lastModifiedSync().millisecondsSinceEpoch;
          }
        } catch (e, stackTrace) {
          ErrorHandler.logError('Error getting file timestamp', e, stackTrace, 'ImageService');
        }
      }
      
      // For full image, use original path as cache key with timestamp
      final String cacheKey = fileTimestamp != null 
          ? '${imagePath}_ts_$fileTimestamp' 
          : imagePath;
      ImageProvider? imageProvider = _getFromCache(cacheKey);
      
      if (imageProvider == null) {
        if (imagePath.startsWith('http')) {
          // Remote URL - use network image (no resize for full image)
          imageProvider = NetworkImage(imagePath);
          _addToCache(imagePath, imageProvider);
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
          imageProvider = FileImage(file);
          _addToCache(imagePath, imageProvider);
        }
      }
      
      return Image(
        image: imageProvider,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // On error, remove from cache
          _imageCache.remove(imagePath);
          _cacheOrder.remove(imagePath);
          ErrorHandler.logError('Error displaying image', error, stackTrace, 'ImageService');
          
          return Container(
            width: double.infinity,
            height: height,
            color: Colors.grey.shade300,
            child: const Icon(Icons.image_not_supported, size: 80, color: Colors.white),
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
        child: const Icon(Icons.image_not_supported, size: 80, color: Colors.white),
      );
    }
  }
  
  /// Clear the image cache and thumbnail cache
  Future<void> clearCache() async {
    _imageCache.clear();
    _cacheOrder.clear();
    
    // Clear thumbnail directory
    try {
      await _initThumbnailCache();
      final files = await _thumbnailCacheDir!.list().toList();
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