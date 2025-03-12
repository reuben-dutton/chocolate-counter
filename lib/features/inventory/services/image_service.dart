import 'dart:io';
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:math' as math;
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/common/utils/item_visualization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Message for isolate to resize an image
class _ResizeImageMessage {
  final String inputPath;
  final String outputPath;
  final int targetSize;
  final SendPort sendPort;

  _ResizeImageMessage({
    required this.inputPath,
    required this.outputPath, 
    required this.targetSize,
    required this.sendPort
  });
}

/// Static method for isolate to process image resizing
Future<void> _isolateResizeImage(_ResizeImageMessage message) async {
  try {
    // Read file
    final file = File(message.inputPath);
    final bytes = await file.readAsBytes();
    
    // Create image codec
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: message.targetSize,
      targetHeight: message.targetSize,
    );
    
    // Get first frame
    final frameInfo = await codec.getNextFrame();
    
    try {
      // Convert to PNG bytes
      final pngBytes = await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
      
      if (pngBytes != null) {
        // Write the resized image to file
        final outputFile = File(message.outputPath);
        await outputFile.writeAsBytes(pngBytes.buffer.asUint8List());
        
        // Signal success
        message.sendPort.send(true);
      } else {
        // Signal failure
        message.sendPort.send(false);
      }
    } finally {
      // Always dispose of the image
      frameInfo.image.dispose();
    }
  } catch (e) {
    // Signal error
    message.sendPort.send(false);
  }
}

/// Service for handling image operations in the application
class ImageService {
  final ImagePicker _picker = ImagePicker();
  
  // LRU Cache implementation with memory limits
  final int _maxCacheSize = 100; // Maximum number of images to cache
  final int _maxCacheMemoryBytes = 30 * 1024 * 1024; // 30MB maximum cache size
  int _currentCacheMemoryUsage = 0;
  final Map<String, int> _imageSizeMap = {}; // Track image sizes in bytes
  final Map<String, ImageProvider> _imageCache = {};
  final List<String> _cacheOrder = []; // Tracks access order for LRU policy
  
  // Image resizing constants
  final int _thumbnailSize = 128; // Size for list thumbnails
  
  // Track pending operations to avoid duplicates
  final Map<String, Future<File>> _pendingOperations = {};
  final Duration _pendingOperationTimeout = const Duration(seconds: 30);
  
  // Directory for storing thumbnail cache
  Directory? _thumbnailCacheDir;
  
  // Cleanup timer
  Timer? _cleanupTimer;
  
  // Constructor
  ImageService() {
    _initThumbnailCache();
    _startPeriodicCleanup();
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
      // Don't rethrow, try to continue without cache
    }
  }
  
  // Start periodic cache cleanup
  void _startPeriodicCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      cleanupThumbnailCache();
      
      // Check for memory pressure
      if (_currentCacheMemoryUsage > _maxCacheMemoryBytes * 0.9) {
        // If we're close to the limit, proactively clean up
        while (_cacheOrder.isNotEmpty && 
               _currentCacheMemoryUsage > _maxCacheMemoryBytes * 0.7) {
          final lruKey = _cacheOrder.removeAt(0);
          final removedSize = _imageSizeMap[lruKey] ?? 0;
          _imageCache.remove(lruKey);
          _imageSizeMap.remove(lruKey);
          _currentCacheMemoryUsage = math.max(0, _currentCacheMemoryUsage - removedSize);
        }
      }
    });
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
        _removeFromCache(imagePath);
        
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
      if (_thumbnailCacheDir == null) return;
      
      final thumbFileName = 'thumbnail_${path.basename(imagePath)}';
      final thumbFile = File('${_thumbnailCacheDir!.path}/$thumbFileName');
      
      if (await thumbFile.exists()) {
        await thumbFile.delete();
        
        // Remove from cache
        final thumbCacheKey = '${imagePath}_thumb';
        _removeFromCache(thumbCacheKey);
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error deleting thumbnail', e, stackTrace, 'ImageService');
    }
  }

  /// Removes an item from the cache and updates memory usage
  void _removeFromCache(String key) {
    final size = _imageSizeMap[key] ?? 0;
    _imageCache.remove(key);
    _imageSizeMap.remove(key);
    _cacheOrder.remove(key);
    _currentCacheMemoryUsage = math.max(0, _currentCacheMemoryUsage - size);
  }

  /// Add an image to the cache with memory-aware eviction policy
  void _addToCache(String key, ImageProvider imageProvider, int estimatedSizeBytes) {
    // First check if we need to evict due to memory or size constraints
    while ((_cacheOrder.length >= _maxCacheSize || 
           _currentCacheMemoryUsage + estimatedSizeBytes > _maxCacheMemoryBytes) && 
           _cacheOrder.isNotEmpty) {
      // Remove least recently used item
      final lruKey = _cacheOrder.removeAt(0);
      final removedSize = _imageSizeMap[lruKey] ?? 0;
      _imageCache.remove(lruKey);
      _imageSizeMap.remove(lruKey);
      _currentCacheMemoryUsage = math.max(0, _currentCacheMemoryUsage - removedSize);
    }
    
    // Update cache
    _imageCache[key] = imageProvider;
    _imageSizeMap[key] = estimatedSizeBytes;
    _currentCacheMemoryUsage += estimatedSizeBytes;
    
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
                _removeFromCache(key);
                return null;
              }
            }
          }
        } else {
          // If file no longer exists, remove from cache
          _removeFromCache(key);
          return null;
        }
      } catch (e, stackTrace) {
        ErrorHandler.logError('Error validating cache entry', e, stackTrace, 'ImageService');
        _removeFromCache(key);
        return null;
      }
    }
    
    if (imageProvider != null) {
      // Update access order by moving to the end
      _cacheOrder.remove(key);
      _cacheOrder.add(key);
    }
    return imageProvider;
  }
  
  /// Estimate the size of an image in bytes
  int _estimateImageSize(int width, int height) {
    // Assuming 4 bytes per pixel (RGBA)
    return width * height * 4;
  }
  
  /// Create a timed operation that will auto-cancel after timeout
  Future<T> _createTimedOperation<T>(String cacheKey, Future<T> operation) {
    // Create a new completer that will handle the timeout
    final completer = Completer<T>();
    
    // Start the timer for the timeout
    final timer = Timer(_pendingOperationTimeout, () {
      if (!completer.isCompleted) {
        _pendingOperations.remove(cacheKey);
        completer.completeError(TimeoutException(
          'Operation timed out after $_pendingOperationTimeout', 
          _pendingOperationTimeout
        ));
      }
    });
    
    // Register the operation with cleanup
    operation.then((result) {
      timer.cancel();
      if (!completer.isCompleted) {
        completer.complete(result);
      }
      _pendingOperations.remove(cacheKey);
    }).catchError((error, stackTrace) {
      timer.cancel();
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
      _pendingOperations.remove(cacheKey);
    });
    
    final future = completer.future;
    if (T == File) {
      _pendingOperations[cacheKey] = future as Future<File>;
    }
    return future;
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
    
    // Check if there's a pending operation for this file
    final cacheKey = '${file.path}_resize';
    if (_pendingOperations.containsKey(cacheKey)) {
      return _pendingOperations[cacheKey]!;
    }
    
    // Create a new resize operation with timeout
    final operation = Future<File>(() async {
      try {
        // For small operations on a UI thread, use compute instead of full isolate
        if (file.lengthSync() < 500 * 1024) { // Files under 500KB
          return await compute<Map<String, dynamic>, File>((data) async {
            try {
              final inputFile = File(data['inputPath']);
              final bytes = await inputFile.readAsBytes();
              final codec = await ui.instantiateImageCodec(
                bytes,
                targetWidth: data['targetSize'],
                targetHeight: data['targetSize'],
              );
              final frameInfo = await codec.getNextFrame();
              try {
                final pngBytes = await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
                if (pngBytes != null) {
                  final outputFile = File(data['outputPath']);
                  await outputFile.writeAsBytes(pngBytes.buffer.asUint8List());
                  return outputFile;
                }
              } finally {
                frameInfo.image.dispose();
              }
            } catch (e) {
              // Ignore error, will return original file
            }
            return File(data['inputPath']);
          }, {
            'inputPath': file.path,
            'outputPath': thumbnailPath,
            'targetSize': targetSize,
          });
        } else {
          // For larger files, use a full isolate
          final completer = Completer<File>();
          final receivePort = ReceivePort();
          
          // Create isolate for CPU-intensive task
          final isolate = await Isolate.spawn(
            _isolateResizeImage,
            _ResizeImageMessage(
              inputPath: file.path,
              outputPath: thumbnailPath,
              targetSize: targetSize,
              sendPort: receivePort.sendPort,
            ),
          );
          
          // Set up timeout
          final timeout = Timer(const Duration(seconds: 15), () {
            receivePort.close();
            isolate.kill(priority: Isolate.immediate);
            if (!completer.isCompleted) {
              completer.complete(file); // Return original file on timeout
            }
          });
          
          // Listen for result
          receivePort.listen((message) {
            timeout.cancel();
            receivePort.close();
            isolate.kill(priority: Isolate.immediate);
            
            if (message == true && !completer.isCompleted) {
              final outputFile = File(thumbnailPath);
              if (outputFile.existsSync()) {
                completer.complete(outputFile);
              } else {
                completer.complete(file);
              }
            } else if (!completer.isCompleted) {
              completer.complete(file);
            }
          });
          
          return await completer.future;
        }
      } catch (e, stackTrace) {
        ErrorHandler.logError('Error resizing image', e, stackTrace, 'ImageService');
        return file; // Return original on error
      }
    });
    
    return _createTimedOperation(cacheKey, operation);
  }
  
  /// Clean up old thumbnails that are no longer needed
  Future<void> cleanupThumbnailCache() async {
    try {
      await _initThumbnailCache();
      if (_thumbnailCacheDir == null) return;
      
      final files = await _thumbnailCacheDir!.list().toList();
      
      // Keep only most recent files (up to max cache size)
      if (files.length > _maxCacheSize * 2) { // Use a multiplier for buffer
        // Sort by modification time (newest first)
        files.sort((a, b) {
          if (a is! File || b is! File) return 0;
          return b.lastModifiedSync().compareTo(a.lastModifiedSync());
        });
        
        // Delete old files
        for (int i = _maxCacheSize * 2; i < files.length; i++) {
          if (files[i] is File) {
            try {
              await (files[i] as File).delete();
            } catch (e) {
              // Ignore errors during cleanup
            }
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
          // Estimate memory usage (thumbnail size * 4 bytes per pixel for RGBA)
          _addToCache(cacheKey, imageProvider, _estimateImageSize(_thumbnailSize, _thumbnailSize));
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
          
          // Use file initially with the original size
          imageProvider = FileImage(file);
          
          try {
            // Get file size or estimate
            final fileSize = file.lengthSync();
            _addToCache(cacheKey, imageProvider, fileSize);
          } catch (e) {
            // If we can't get the file size, use a conservative estimate
            _addToCache(cacheKey, imageProvider, 1 * 1024 * 1024); // 1MB estimate
          }
          
          // Start async resize operation
          _resizeImageFile(file, _thumbnailSize).then((resizedFile) {
            final resizedProvider = FileImage(resizedFile);
            try {
              // Get resized file size or estimate
              final resizedSize = resizedFile.lengthSync();
              _addToCache(cacheKey, resizedProvider, resizedSize);
            } catch (e) {
              // If we can't get the file size, use a conservative estimate
              _addToCache(cacheKey, resizedProvider, _estimateImageSize(_thumbnailSize, _thumbnailSize));
            }
          }).catchError((e, stackTrace) {
            ErrorHandler.logError('Error resizing image', e, stackTrace, 'ImageService');
          });
        }
      }
      
      return CircleAvatar(
        radius: radius,
        backgroundImage: imageProvider,
        onBackgroundImageError: (_, __) {
          // On error, remove from cache
          _removeFromCache(cacheKey);
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
          // Conservative estimate for a full-size image
          _addToCache(imagePath, imageProvider, 2 * 1024 * 1024); // 2MB estimate
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
          
          try {
            // Get file size
            final fileSize = file.lengthSync();
            _addToCache(cacheKey, imageProvider, fileSize);
          } catch (e) {
            // If we can't get the file size, use a conservative estimate
            _addToCache(cacheKey, imageProvider, 2 * 1024 * 1024); // 2MB estimate
          }
        }
      }
      
      return Image(
        image: imageProvider,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // On error, remove from cache
          _removeFromCache(cacheKey);
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
    _imageSizeMap.clear();
    _currentCacheMemoryUsage = 0;
    
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
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _imageCache.clear();
    _cacheOrder.clear();
    _imageSizeMap.clear();
    _currentCacheMemoryUsage = 0;
  }
}