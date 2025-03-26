// lib/features/export/services/export_service.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:food_inventory/common/services/database_service.dart';
import 'package:food_inventory/common/services/error_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:excel/excel.dart';

enum ExportFormat { csv, json, sqlite, excel }

class ExportService {
  final DatabaseService _databaseService;

  ExportService(this._databaseService);

  // This method helps determine if we have proper storage permissions
  Future<bool> checkAndRequestStoragePermissions() async {
    try {
      if (Platform.isAndroid) {
        // Get Android version information
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        
        // Check if it's an emulator - skip permission checks for emulators
        if (!androidInfo.isPhysicalDevice) {
          return true;
        }
        
        final sdkInt = androidInfo.version.sdkInt;
        
        if (sdkInt >= 30) { // Android 11+
          // First try regular storage permission
          var storageStatus = await Permission.storage.status;
          if (!storageStatus.isGranted) {
            storageStatus = await Permission.storage.request();
          }
          
          if (storageStatus.isGranted) {
            return true;
          }
          
          // If regular permission isn't enough, try manage external storage
          var manageStatus = await Permission.manageExternalStorage.status;
          if (!manageStatus.isGranted) {
            manageStatus = await Permission.manageExternalStorage.request();
          }
          
          return manageStatus.isGranted;
        } else { // Android 10 and below
          var status = await Permission.storage.status;
          if (!status.isGranted) {
            status = await Permission.storage.request();
          }
          
          return status.isGranted;
        }
      }
      
      // For iOS and other platforms, we don't need special permissions for app directories
      return true;
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error checking storage permissions', e, stackTrace, 'ExportService');
      return false;
    }
  }

  Future<String> exportToCSV({
    bool includeImages = false,
    bool includeHistory = true,
    bool exportAllData = false,
    String? customExportDir = null,
  }) async {
    try {
      // Get app document directory
      final dir = await _getExportDirectory(
        useExternalStorage: true,
        customDir: customExportDir
      );
      final timestamp = _getTimestamp();
      final exportDir = Directory(path.join(dir.path, 'export_$timestamp'));
      await exportDir.create(recursive: true);

      // Define tables to export
      final tables = _getTablesToExport(includeHistory, exportAllData);

      // Export each table to a separate CSV file
      for (final table in tables) {
        final data = await _getTableData(table);
        if (data.isEmpty) continue;

        // Convert data to CSV
        final headers = data.first.keys.toList();
        final List<List<dynamic>> rows = [headers]; // Specify List<dynamic> for inner type

        for (final row in data) {
          final values = <dynamic>[];
          for (final header in headers) {
            values.add(row[header]);
          }
          rows.add(values);
        }

        final csv = const ListToCsvConverter().convert(rows);
        final file = File(path.join(exportDir.path, '$table.csv'));
        await file.writeAsString(csv);
      }

      // Handle images if requested
      if (includeImages) {
        await _exportImages(exportDir.path);
      }

      // Create a zip file of the export directory
      final zipFileName = 'inventory_export_$timestamp.zip';
      final zipPath = path.join(dir.path, zipFileName);
      
      // Create the ZIP file using a basic implementation
      await _createZipFile(exportDir.path, zipPath);
      
      // Clean up the temporary export directory
      await exportDir.delete(recursive: true);
      
      return zipPath;
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error exporting to CSV', e, stackTrace, 'ExportService');
      rethrow;
    }
  }

  Future<String> exportToJSON({
    bool includeImages = false,
    bool includeHistory = true,
    bool exportAllData = false,
    String? customExportDir = null,
  }) async {
    try {
      // Check permissions first
      final hasPermission = await checkAndRequestStoragePermissions();
      if (!hasPermission) {
        throw Exception('Storage permission denied. Please enable in app settings.');
      }
      
      // Get app document directory
      final dir = await _getExportDirectory(
        useExternalStorage: true,
        customDir: customExportDir
      );
      final timestamp = _getTimestamp();
      final exportDir = Directory(path.join(dir.path, 'export_$timestamp'));
      await exportDir.create(recursive: true);

      // Define tables to export
      final tables = _getTablesToExport(includeHistory, exportAllData);

      // Create a single JSON structure
      final Map<String, dynamic> exportData = {};

      // Export each table
      for (final table in tables) {
        final data = await _getTableData(table);
        exportData[table] = data;
      }

      // Write the JSON file
      final file = File(path.join(exportDir.path, 'inventory_data.json'));
      await file.writeAsString(jsonEncode(exportData));

      // Handle images if requested
      if (includeImages) {
        await _exportImages(exportDir.path);
      }

      return file.path;
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error exporting to JSON', e, stackTrace, 'ExportService');
      rethrow;
    }
  }

  Future<String> exportDatabaseFile({
    bool includeImages = false,
    String? customExportDir = null,
  }) async {
    try {
      // Check permissions first
      final hasPermission = await checkAndRequestStoragePermissions();
      if (!hasPermission) {
        throw Exception('Storage permission denied. Please enable in app settings.');
      }
      
      // Get export directory (external storage for better user access or custom directory)
      final dir = await _getExportDirectory(
        useExternalStorage: true, 
        customDir: customExportDir
      );
      final timestamp = _getTimestamp();
      
      // Database file path
      final dbPath = _databaseService.database.path;
      final dbFile = File(dbPath);
      
      // Copy the database file to exports directory with timestamp
      final exportFile = File(path.join(dir.path, 'food_inventory_$timestamp.db'));
      await dbFile.copy(exportFile.path);
      
      // Handle images if requested
      if (includeImages) {
        final exportDir = Directory(path.join(dir.path, 'export_images_$timestamp'));
        await exportDir.create(recursive: true);
        await _exportImages(exportDir.path);
        
        // Create a temporary info file explaining the contents
        final infoFile = File(path.join(exportDir.path, 'README.txt'));
        await infoFile.writeAsString(
          'Food Inventory Export\n'
          'Date: ${DateTime.now().toString()}\n\n'
          'This export contains:\n'
          '- Database file (SQLite)\n'
          '- Images folder with product images\n\n'
          'To use this export, copy the database file to your device\'s application data folder.'
        );
          
        // Return the path of the database file, which is what we'll share
        return exportFile.path;
      }
      
      return exportFile.path;
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error exporting database file', e, stackTrace, 'ExportService');
      rethrow;
    }
  }

  Future<String> exportToExcel({
    bool includeImages = false,
    bool includeHistory = true,
    bool exportAllData = false,
    String? customExportDir = null,
  }) async {
    try {
      // Get app document directory
      final dir = await _getExportDirectory(
        useExternalStorage: true,
        customDir: customExportDir
      );
      final timestamp = _getTimestamp();
      
      // Define tables to export
      final tables = _getTablesToExport(includeHistory, exportAllData);
      
      // Create Excel file using the excel package
      final excel = Excel.createExcel();
      
      // Remove the default sheet
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }
      
      // For each table, create a separate sheet
      for (final table in tables) {
        // Get data for this table
        final data = await _getTableData(table);
        if (data.isEmpty) continue;
        
        // Create a sheet for this table
        final sheetName = _formatSheetName(table);
        excel.copy('Sheet1', sheetName); // Create a new sheet (even if Sheet1 doesn't exist)
        final sheet = excel[sheetName];
        
        // Add headers
        final headers = data.first.keys.toList();
        for (var i = 0; i < headers.length; i++) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value = headers[i];
        }
        
        // Add data rows
        for (var rowIndex = 0; rowIndex < data.length; rowIndex++) {
          final rowData = data[rowIndex];
          
          for (var colIndex = 0; colIndex < headers.length; colIndex++) {
            final header = headers[colIndex];
            final value = rowData[header];
            
            final cell = sheet.cell(CellIndex.indexByColumnRow(
              columnIndex: colIndex, 
              rowIndex: rowIndex + 1
            ));
            
            if (value == null) {
              cell.value = '';
            }
            // Convert timestamps to dates
            else if (header.toLowerCase().contains('date') && value is String) {
              try {
                // Try to parse the string as a date
                final date = DateTime.parse(value);
                cell.value = date;
                // Set date format - use the format method directly
                cell.cellStyle = CellStyle();
                cell.cellStyle?.horizontalAlignment = HorizontalAlign.Center;
              } catch (e) {
                // If it can't be parsed as a date, just use the string
                cell.value = value;
              }
            }
            else if (value is int) {
              cell.value = value;
            }
            else if (value is double) {
              cell.value = value;
            }
            else {
              cell.value = value.toString();
            }
          }
        }
        
        // Auto-fit columns for better readability
        for (var i = 0; i < headers.length; i++) {
          sheet.setColWidth(i, 15.0); // Using correct method name
        }
      }
      
      // Save Excel file
      final excelPath = path.join(dir.path, 'inventory_export_$timestamp.xlsx');
      final excelBytes = excel.save();
      if (excelBytes != null) {
        final excelFile = File(excelPath);
        await excelFile.writeAsBytes(excelBytes);
        return excelPath;
      } else {
        throw Exception('Failed to create Excel file');
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error exporting to Excel', e, stackTrace, 'ExportService');
      rethrow;
    }
  }

  String _formatSheetName(String tableName) {
    // Excel sheet names have restrictions: max 31 chars, no special chars, etc.
    final formatted = tableName
      .replaceAll('_', ' ')
      .replaceAll(RegExp(r'[^\w\s]'), '')
      .trim();
    
    // Capitalize first letter of each word
    final words = formatted.split(' ');
    final capitalizedWords = words.map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join('');
    
    // Truncate to 31 characters (Excel limit)
    return capitalizedWords.substring(0, capitalizedWords.length > 31 ? 31 : capitalizedWords.length);
  }
  

  // Helper Methods
  Future<Directory> _getExportDirectory({bool useExternalStorage = true, String? customDir}) async {
    // If a custom directory is provided, use it
    if (customDir != null) {
      final exportDir = Directory(customDir);
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }
      return exportDir;
    }
    
    Directory exportDir;
    
    if (useExternalStorage && Platform.isAndroid) {
      // Use Downloads folder for Android external storage
      try {
        // Get external storage directory
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          // Navigate up to find the Download directory
          // Usually /storage/emulated/0/Download
          final String downloadPath = externalDir.path.split('/Android')[0] + '/Download/FoodInventoryExports';
          exportDir = Directory(downloadPath);
        } else {
          // Fallback to app documents directory
          final documentsDir = await getApplicationDocumentsDirectory();
          exportDir = Directory(path.join(documentsDir.path, 'exports'));
        }
      } catch (e) {
        // Fallback to app documents directory
        final documentsDir = await getApplicationDocumentsDirectory();
        exportDir = Directory(path.join(documentsDir.path, 'exports'));
      }
    } else {
      // Use app documents directory for iOS or if external storage not requested
      final documentsDir = await getApplicationDocumentsDirectory();
      exportDir = Directory(path.join(documentsDir.path, 'exports'));
    }
    
    // Create the directory if it doesn't exist
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    
    return exportDir;
  }

  Future<Directory?> chooseExportDirectory() async {
    try {
      // Ensure we have permissions first
      final hasPermission = await checkAndRequestStoragePermissions();
      if (!hasPermission) {
        throw Exception('Storage permission denied. Please enable in app settings.');
      }
      
      // Use file_picker to let the user select a directory
      final result = await FilePicker.platform.getDirectoryPath();
      
      if (result != null) {
        final selectedDir = Directory(result);
        
        // Create an exports subfolder inside the selected directory
        final exportDir = Directory(path.join(selectedDir.path, 'FoodInventoryExports'));
        if (!await exportDir.exists()) {
          await exportDir.create(recursive: true);
        }
        
        return exportDir;
      }
      
      return null;
    } catch (e, stackTrace) {
      // Log the error and rethrow for better handling
      ErrorHandler.logError('Error choosing export directory', e, stackTrace, 'ExportService');
      rethrow;
    }
  }

  String _getTimestamp() {
    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMdd_HHmmss');
    return formatter.format(now);
  }

  List<String> _getTablesToExport(bool includeHistory, bool exportAllData) {
    final List<String> tables = [
      DatabaseService.tableItemDefinitions,
      DatabaseService.tableItemInstances,
      DatabaseService.tableShipments,
      DatabaseService.tableShipmentItems,
    ];
    
    if (includeHistory) {
      tables.add(DatabaseService.tableInventoryMovements);
    }
    
    // Add any additional tables for a full export
    if (exportAllData) {
      // Add other tables like settings, etc.
    }
    
    return tables;
  }

  // Update the getTableData method to properly format date values
  Future<List<Map<String, dynamic>>> _getTableData(String table) async {
    try {
      final db = _databaseService.database;
      final rawData = await db.query(table);
      
      // Process data for CSV export - handle date conversions
      final processedData = rawData.map((row) {
        final Map<String, dynamic> processedRow = {};
        
        row.forEach((key, value) {
          // Check if this field is likely a timestamp (milliseconds since epoch)
          if ((key.toLowerCase().contains('date') || key.toLowerCase().contains('timestamp')) && 
              value is int && value > 946684800000) { // Jan 1, 2000 as a sanity check
            // Convert timestamp to readable date string
            final dateTime = DateTime.fromMillisecondsSinceEpoch(value);
            processedRow[key] = DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
          } 
          // Handle boolean values stored as integers (0/1)
          else if (value is int && (key.toLowerCase().startsWith('is') || key.toLowerCase().contains('enabled'))) {
            processedRow[key] = value == 1 ? 'true' : 'false';
          }
          else {
            processedRow[key] = value;
          }
        });
        
        return processedRow;
      }).toList();
      
      return processedData;
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error getting table data for export', e, stackTrace, 'ExportService');
      return [];
    }
  }

  Future<void> _exportImages(String exportPath) async {
    try {
      // Create images directory
      final imagesDir = Directory(path.join(exportPath, 'images'));
      await imagesDir.create(recursive: true);
      
      // Get item definitions with images
      final db = _databaseService.database;
      final items = await db.query(
        DatabaseService.tableItemDefinitions,
        where: 'imageUrl IS NOT NULL',
      );
      
      // Copy each image file
      for (final item in items) {
        final imagePath = item['imageUrl'] as String?;
        if (imagePath == null || imagePath.isEmpty) continue;
        
        final imageFile = File(imagePath);
        if (await imageFile.exists()) {
          final fileName = path.basename(imagePath);
          final destPath = path.join(imagesDir.path, fileName);
          await imageFile.copy(destPath);
        }
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error exporting images', e, stackTrace, 'ExportService');
      // Continue with export even if images fail
    }
  }

  // Helper method to create a ZIP file
  Future<void> _createZipFile(String sourceDirPath, String zipFilePath) async {
    try {
      // Get the Dart process executable
      final process = await Process.run('zip', ['-r', zipFilePath, '.'], 
        workingDirectory: sourceDirPath);
      
      if (process.exitCode != 0) {
        // If zip command fails, use a fallback method (just copy directory in this case)
        final sourceDir = Directory(sourceDirPath);
        final zipFile = File(zipFilePath);
        if (await zipFile.exists()) {
          await zipFile.delete();
        }
        
        // Create a simple manifest file listing the CSV files
        final manifestContent = StringBuffer();
        manifestContent.writeln('# Food Inventory Export');
        manifestContent.writeln('# Generated: ${DateTime.now()}');
        manifestContent.writeln('');
        
        // List all files in the export directory
        await for (final entity in sourceDir.list()) {
          if (entity is File) {
            final relativePath = path.relative(entity.path, from: sourceDirPath);
            manifestContent.writeln(relativePath);
            
            // Copy each file to the zip path with a modified name
            final targetFile = File(path.join(path.dirname(zipFilePath), 
              'export_${path.basename(entity.path)}'));
            await entity.copy(targetFile.path);
          }
        }
        
        // Create manifest
        final manifestFile = File(path.join(path.dirname(zipFilePath), 'export_manifest.txt'));
        await manifestFile.writeAsString(manifestContent.toString());
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error creating zip file', e, stackTrace, 'ExportService');
      // If zipping fails, we'll just return the export directory path
      throw Exception('Failed to create zip file: $e');
    }
  }
}