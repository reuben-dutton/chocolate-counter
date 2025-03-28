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
import 'package:food_inventory/data/models/inventory_movement.dart';

enum ExportFormat { csv, json, sqlite, excel }

class ExportService {
  final DatabaseService _databaseService;

  ExportService(this._databaseService);

  // This method helps determine if we have proper storage permissions
  // Improved checkAndRequestStoragePermissions method
  Future<bool> checkAndRequestStoragePermissions() async {
    try {
      if (Platform.isAndroid) {
        // Get Android version information
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;
        final isEmulator = !androidInfo.isPhysicalDevice;
        
        // Try more aggressively for permissions
        if (sdkInt >= 30) { // Android 11+
          // For emulators, just proceed as if we have permission
          if (isEmulator) {
            return true;
          }
          
          // Try all possible permissions
          try {
            // First try storage permission
            var storageStatus = await Permission.storage.request();
            if (storageStatus.isGranted) {
              return true;
            }
            
            // If that fails, try external storage permission
            var externalStorageStatus = await Permission.manageExternalStorage.request();
            if (externalStorageStatus.isGranted) {
              return true;
            }
            
            // Try other relevant permissions
            var mediaStatus = await Permission.mediaLibrary.request();
            if (mediaStatus.isGranted) {
              return true;
            }
            
            // Last resort: check if we at least have some form of storage access
            return await Permission.storage.isGranted || 
                  await Permission.manageExternalStorage.isGranted || 
                  await Permission.mediaLibrary.isGranted;
          } catch (e) {
            print('Error requesting permissions: $e');
            // Attempt without checking permissions as a fallback
            return true;
          }
        } else { // Android 10 and below
          var status = await Permission.storage.request();
          return status.isGranted;
        }
      }
      
      // For iOS and other platforms, we don't need special permissions for app directories
      return true;
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error checking storage permissions', e, stackTrace, 'ExportService');
      // Fallback to assuming we have permissions in case of errors
      return true;
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
      final zipFileName = 'inventoryexport_csv_$timestamp.zip';
      final zipPath = path.join(dir.path, zipFileName);
      
      // Create a temporary directory to store CSV files before zipping
      final tempDir = await Directory.systemTemp.createTemp('export_temp');
      
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
        final file = File(path.join(tempDir.path, '$table.csv'));
        await file.writeAsString(csv);
      }

      // Create a README file with enum interpretations
      await _createEnumReadmeFile(tempDir.path);

      // Handle images if requested
      if (includeImages) {
        await _exportImages(tempDir.path);
      }

      // Create the ZIP file using a basic implementation
      await _createZipFile(tempDir.path, zipPath);
      
      // Clean up the temporary export directory
      await tempDir.delete(recursive: true);
      
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
      final zipFileName = 'inventoryexport_json_$timestamp.zip';
      final zipPath = path.join(dir.path, zipFileName);
      
      // Create a temporary directory to store JSON files before zipping
      final tempDir = await Directory.systemTemp.createTemp('export_temp');

      // Define tables to export
      final tables = _getTablesToExport(includeHistory, exportAllData);

      // Create a single JSON structure
      final Map<String, dynamic> exportData = {};

      // Export each table
      for (final table in tables) {
        final data = await _getTableData(table);
        exportData[table] = data;
      }

      // Add enum interpretations to the JSON
      exportData['_enums'] = _getEnumInterpretations();

      // Write the JSON file
      final file = File(path.join(tempDir.path, 'inventory_data.json'));
      await file.writeAsString(jsonEncode(exportData));

      // Handle images if requested
      if (includeImages) {
        await _exportImages(tempDir.path);
      }
      
      // Create the ZIP file
      await _createZipFile(tempDir.path, zipPath);
      
      // Clean up the temporary directory
      await tempDir.delete(recursive: true);

      return zipPath;
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
      final zipFileName = 'inventoryexport_sqlite_$timestamp.zip';
      final zipPath = path.join(dir.path, zipFileName);
      
      // Create a temporary directory for files before zipping
      final tempDir = await Directory.systemTemp.createTemp('export_temp');
      
      // Database file path
      final dbPath = _databaseService.database.path;
      final dbFile = File(dbPath);
      
      // Copy the database file to temp directory
      final databaseFilePath = path.join(tempDir.path, 'food_inventory.db');
      await dbFile.copy(databaseFilePath);

      // Create a README file with enum interpretations
      await _createEnumReadmeFile(tempDir.path);
      
      // Handle images if requested
      if (includeImages) {
        await _exportImages(tempDir.path);
      }
      
      // Create the ZIP file
      await _createZipFile(tempDir.path, zipPath);
      
      // Clean up the temporary directory
      await tempDir.delete(recursive: true);
      
      return zipPath;
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
      // First check permissions
      bool hasPermission = await checkAndRequestStoragePermissions();
      if (!hasPermission) {
        throw Exception('Storage permission denied. Please enable in app settings.');
      }
      
      // Get app document directory
      final dir = await _getExportDirectory(
        useExternalStorage: true,
        customDir: customExportDir
      );
      
      final timestamp = _getTimestamp();
      String fileName = 'inventoryexport_excel_$timestamp';
      final zipFileName = '$fileName.zip';
      final zipPath = path.join(dir.path, zipFileName);
      
      // Create a temporary directory for files before zipping
      final tempDir = await Directory.systemTemp.createTemp('export_temp');
      
      try {
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
          excel.copy('Sheet1', sheetName); // Create a new sheet
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
                  // Set date format
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
            sheet.setColWidth(i, 15.0);
          }
        }
        
        // Add an Enums sheet with interpretations
        _addEnumSheet(excel);
        
        // Save Excel file
        final excelPath = path.join(tempDir.path, 'inventory_export.xlsx');
        final excelBytes = excel.save();
        if (excelBytes != null) {
          final excelFile = File(excelPath);
          await excelFile.writeAsBytes(excelBytes);
        } else {
          throw Exception('Failed to create Excel file');
        }

        // Create a README file with enum interpretations
        await _createEnumReadmeFile(tempDir.path);
        
        // Handle images if requested
        if (includeImages) {
          await _exportImages(tempDir.path);
        }
        
        // Create the ZIP file
        try {
          await _createZipFile(tempDir.path, zipPath);
        } catch (e) {
          if (e is Exception && e.toString().contains('files were exported to')) {
            // This is our fallback case where files were exported individually
            // Extract the path from the exception message
            final match = RegExp(r'files were exported to (.+)').firstMatch(e.toString());
            if (match != null && match.groupCount >= 1) {
              final fallbackPath = match.group(1)!;
              return fallbackPath; // Return the fallback directory path
            }
          }
          // If it's not our fallback exception, rethrow it
          rethrow;
        }
        
        // Clean up the temporary directory
        await tempDir.delete(recursive: true);
        
        return zipPath;
      } catch (e) {
        // Make sure to clean up the temporary directory if an error occurs
        try {
          await tempDir.delete(recursive: true);
        } catch (_) {}
        rethrow;
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error exporting to Excel', e, stackTrace, 'ExportService');
      rethrow;
    }
  }

  // Add a sheet with enum values to Excel
  void _addEnumSheet(Excel excel) {
    // Create a new sheet for enums
    excel.copy('Sheet1', 'Enums'); 
    final sheet = excel['Enums'];
    
    // Headers
    final headers = ['Enum Name', 'Index', 'Value', 'Description'];
    for (var i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value = headers[i];
    }
    
    // Get enum interpretations
    final enumsMap = _getEnumInterpretations();
    
    int rowIndex = 1;
    
    // Add each enum with its values
    enumsMap.forEach((enumName, values) {
      for (var entry in values.entries) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = enumName;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = entry.key;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = entry.value;
        
        // Add description if available
        String description = _getEnumDescription(enumName, entry.value);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = description;
        
        rowIndex++;
      }
      // Add an empty row between enums
      rowIndex++;
    });
    
    // Auto-fit columns
    for (var i = 0; i < headers.length; i++) {
      sheet.setColWidth(i, 20.0);
    }
  }

  // Get descriptions for enum values
  String _getEnumDescription(String enumName, String value) {
    switch (enumName) {
      case 'MovementType':
        switch (value) {
          case 'stockSale': return 'Decrease in stock from customer purchase';
          case 'inventoryToStock': return 'Movement from inventory to stock';
          case 'shipmentToInventory': return 'Addition from a new shipment';
          default: return '';
        }
      default:
        return '';
    }
  }

  // Create a README file with enum interpretations
  Future<void> _createEnumReadmeFile(String directoryPath) async {
    final readmeContent = StringBuffer();
    readmeContent.writeln('# Food Inventory Export - Enum Interpretations');
    readmeContent.writeln('Generated: ${DateTime.now()}\n');
    
    final enumsMap = _getEnumInterpretations();
    
    enumsMap.forEach((enumName, values) {
      readmeContent.writeln('## $enumName');
      readmeContent.writeln('| Index | Value | Description |');
      readmeContent.writeln('| ----- | ----- | ----------- |');
      
      values.forEach((index, value) {
        String description = _getEnumDescription(enumName, value);
        readmeContent.writeln('| $index | $value | $description |');
      });
      
      readmeContent.writeln('\n');
    });
    
    // Add database structure information
    readmeContent.writeln('## Database Structure');
    readmeContent.writeln('The database contains the following tables:');
    readmeContent.writeln('- item_definitions: Parent table for inventory items');
    readmeContent.writeln('- item_instances: Actual inventory/stock items');
    readmeContent.writeln('- inventory_movements: Tracks stock changes');
    readmeContent.writeln('- shipments: Parent table for shipment items');
    readmeContent.writeln('- shipment_items: Links shipments to item definitions');
    
    final readmeFile = File(path.join(directoryPath, 'README.md'));
    await readmeFile.writeAsString(readmeContent.toString());
  }

  // Get a map of all enum interpretations
  Map<String, Map<int, String>> _getEnumInterpretations() {
    final enums = <String, Map<int, String>>{};
    
    // Movement Types
    final movementTypes = <int, String>{};
    for (var i = 0; i < MovementType.values.length; i++) {
      movementTypes[i] = MovementType.values[i].toString().split('.').last;
    }
    enums['MovementType'] = movementTypes;
    
    // Add any other enums that might be important for data interpretation
    
    return enums;
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
  // Alternative export directory selection that defaults to app directory if external fails
  Future<Directory> _getExportDirectory({bool useExternalStorage = true, String? customDir}) async {
    // If a custom directory is provided, use it
    if (customDir != null) {
      final exportDir = Directory(customDir);
      try {
        if (!await exportDir.exists()) {
          await exportDir.create(recursive: true);
        }
        // Verify we can write to this directory
        final testFile = File('${exportDir.path}/test_write.tmp');
        await testFile.writeAsString('test');
        await testFile.delete();
        return exportDir;
      } catch (e) {
        print('Error using custom directory: $e, falling back to app directory');
        // Fall through to default directory if custom directory fails
      }
    }
    
    Directory exportDir;
    
    if (useExternalStorage && Platform.isAndroid) {
      try {
        // Try multiple approaches to get a writable directory
        
        // First try: Get the download directory
        try {
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            // Navigate up to find the Download directory
            final String downloadPath = externalDir.path.split('/Android')[0] + '/Download';
            exportDir = Directory(downloadPath);
            
            // Test if we can write to this directory
            if (await _canWriteToDirectory(exportDir)) {
              return exportDir;
            }
          }
        } catch (e) {
          print('Error accessing download directory: $e');
        }
        
        // Second try: Use application documents directory
        try {
          final documentsDir = await getApplicationDocumentsDirectory();
          exportDir = Directory(documentsDir.path);
          if (await _canWriteToDirectory(exportDir)) {
            return exportDir;
          }
        } catch (e) {
          print('Error accessing application documents directory: $e');
        }
        
        // Third try: Use temporary directory as last resort
        final tempDir = await getTemporaryDirectory();
        return tempDir;
        
      } catch (e) {
        // Fallback to application documents directory in case of any errors
        final documentsDir = await getApplicationDocumentsDirectory();
        return Directory(documentsDir.path);
      }
    } else {
      // Use app documents directory for iOS or if external storage not requested
      final documentsDir = await getApplicationDocumentsDirectory();
      return Directory(documentsDir.path);
    }
  }

  // Helper method to check if we can write to a directory
  Future<bool> _canWriteToDirectory(Directory dir) async {
    try {
      // Create the directory if it doesn't exist
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      
      // Try to write a test file
      final testFile = File('${dir.path}/test_write.tmp');
      await testFile.writeAsString('test');
      await testFile.delete();
      return true;
    } catch (e) {
      print('Cannot write to directory ${dir.path}: $e');
      return false;
    }
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
        return selectedDir;
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
  // Updated _createZipFile method with enhanced error handling and fallback
  Future<void> _createZipFile(String sourceDirPath, String zipFilePath) async {
    try {
      // Ensure we have proper permissions first
      bool hasPermission = await checkAndRequestStoragePermissions();
      if (!hasPermission) {
        throw Exception('Storage permission denied. Please enable in app settings.');
      }
      
      // Create parent directory if it doesn't exist
      final zipDir = Directory(path.dirname(zipFilePath));
      if (!await zipDir.exists()) {
        await zipDir.create(recursive: true);
      }
      
      // Check if we can write to the target directory
      try {
        final testFile = File('${path.dirname(zipFilePath)}/test_write_permission.tmp');
        await testFile.writeAsString('test');
        await testFile.delete();
      } catch (e) {
        throw Exception('Cannot write to the selected directory. Please choose another location.');
      }
      
      // Attempt to use the zip command first
      try {
        final process = await Process.run('zip', ['-r', zipFilePath, '.'], 
          workingDirectory: sourceDirPath);
        
        if (process.exitCode != 0) {
          throw Exception('Zip command failed: ${process.stderr}');
        }
        
        // Verify the zip file was created
        final zipFile = File(zipFilePath);
        if (!await zipFile.exists()) {
          throw Exception('Zip file was not created');
        }
        
        return; // Zip was successful, exit early
      } catch (e) {
        print('Native zip failed, falling back to manual copy: $e');
        // Continue to fallback method
      }
      
      // Fallback method: copy files individually to a directory with "_files" suffix
      final fallbackDirName = zipFilePath.replaceAll('.zip', '_files');
      final fallbackDir = Directory(fallbackDirName);
      if (await fallbackDir.exists()) {
        await fallbackDir.delete(recursive: true);
      }
      await fallbackDir.create(recursive: true);
      
      // Create a manifest file
      final manifestContent = StringBuffer();
      manifestContent.writeln('# Food Inventory Export');
      manifestContent.writeln('# Generated: ${DateTime.now()}');
      manifestContent.writeln('# Note: Zip creation failed, files exported individually');
      manifestContent.writeln('');
      
      // Copy all files from the source directory
      final sourceDir = Directory(sourceDirPath);
      await for (final entity in sourceDir.list(recursive: true)) {
        if (entity is File) {
          final relativePath = path.relative(entity.path, from: sourceDirPath);
          manifestContent.writeln(relativePath);
          
          // Create subdirectories if needed
          final targetPath = path.join(fallbackDirName, relativePath);
          final targetDir = Directory(path.dirname(targetPath));
          if (!await targetDir.exists()) {
            await targetDir.create(recursive: true);
          }
          
          // Copy the file
          await entity.copy(targetPath);
        }
      }
      
      // Write manifest file
      final manifestFile = File(path.join(fallbackDirName, 'export_manifest.txt'));
      await manifestFile.writeAsString(manifestContent.toString());
      
      // Return the fallback directory instead of a zip file
      throw Exception('Zip creation failed, but files were exported to $fallbackDirName');
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error creating zip file', e, stackTrace, 'ExportService');
      throw Exception('Failed to create zip file: $e');
    }
  }
}