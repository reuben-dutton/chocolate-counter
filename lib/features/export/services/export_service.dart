import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:csv/csv.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:food_inventory/common/services/database_service.dart';
import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/data/models/inventory_movement.dart';
import 'package:food_inventory/features/export/models/export_mode.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'package:excel/excel.dart';
import 'dart:convert';

/// Service for exporting the app's data
class ExportService {
  final DatabaseService _databaseService;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  ExportService(this._databaseService);

  /// Request storage permissions based on platform
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      final sdkVersion = androidInfo.version.sdkInt;
      
      // Android 10 (SDK 29) and higher use the storage access framework
      if (sdkVersion >= 29) {
        // On newer Android versions, we use the Storage Access Framework
        // which doesn't require special permissions for specific folders
        return true;
      } else {
        // For older Android versions
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    } else if (Platform.isIOS) {
      // iOS doesn't require explicit permission for document picker
      return true;
    }
    
    return false;
  }

  /// Export data in the selected format
  Future<String> exportData({
    required ExportMode mode,
    required bool includeImages,
    required String outputDirectory,
  }) async {
    try {
      // Request permissions
      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        throw Exception('Storage permission denied');
      }
      
      // Create a temporary directory for the export
      final tempDir = await Directory.systemTemp.createTemp('inventory_export_');
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
      final exportName = 'inventory-export-${mode.name}-$timestamp';
      final exportDir = Directory(path.join(tempDir.path, exportName));
      await exportDir.create(recursive: true);
      
      // Export based on selected mode
      switch (mode) {
        case ExportMode.csv:
          await _exportToCsv(exportDir.path);
        case ExportMode.excel:
          await _exportToExcel(exportDir.path);
        case ExportMode.sqlite:
          await _exportToSqlite(exportDir.path);
        case ExportMode.json:
          await _exportToJson(exportDir.path);
      }
      
      // Add README
      await _createReadme(exportDir.path, mode);
      
      // Add manifest
      await _createManifest(exportDir.path, mode);
      
      // Include images if requested
      if (includeImages) {
        await _exportImages(exportDir.path);
      }
      
      // Create zip file
      final zipPath = path.join(outputDirectory, '$exportName.zip');
      await _createZipArchive(exportDir.path, zipPath);
      
      // Clean up temp directory
      await tempDir.delete(recursive: true);
      
      return zipPath;
    } catch (e, stackTrace) {
      ErrorHandler.logError('Export error', e, stackTrace, 'ExportService');
      rethrow;
    }
  }

  /// Export data to CSV files
  Future<void> _exportToCsv(String exportDir) async {
    final db = _databaseService.database;
    
    // Create a directory for the CSV files
    final csvDir = Directory(path.join(exportDir, 'csv'));
    await csvDir.create();
    
    // Export all tables
    final tables = [
      DatabaseService.tableItemDefinitions,
      DatabaseService.tableItemInstances,
      DatabaseService.tableInventoryMovements,
      DatabaseService.tableShipments,
      DatabaseService.tableShipmentItems,
    ];
    
    for (final table in tables) {
      // Get data
      final rows = await db.query(table);
      
      if (rows.isEmpty) continue;
      
      // Get column names from first row
      final columns = rows.first.keys.toList();
      
      // Create CSV data
      final csvData = [
        columns, // Header row
        ...rows.map((row) => columns.map((col) => row[col]).toList()),
      ];
      
      // Convert to CSV string
      final csv = const ListToCsvConverter().convert(csvData);
      
      // Write to file
      final file = File(path.join(csvDir.path, '$table.csv'));
      await file.writeAsString(csv);
    }
    
    // Export enums (not stored in the database)
    await _exportEnums(csvDir.path);
  }

  /// Export data to Excel file
  Future<void> _exportToExcel(String exportDir) async {
    final db = _databaseService.database;
    
    // Create Excel workbook
    final excel = Excel.createExcel();
    
    // Default sheet that comes with new Excel file
    excel.delete('Sheet1');
    
    // Export all tables
    final tables = [
      DatabaseService.tableItemDefinitions,
      DatabaseService.tableItemInstances,
      DatabaseService.tableInventoryMovements,
      DatabaseService.tableShipments,
      DatabaseService.tableShipmentItems,
    ];
    
    for (final table in tables) {
      // Create sheet for table
      final sheet = excel[table];
      
      // Get data
      final rows = await db.query(table);
      
      if (rows.isEmpty) continue;
      
      // Get column names from first row
      final columns = rows.first.keys.toList();
      
      // Add header row
      for (var i = 0; i < columns.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value = columns[i];
      }
      
      // Add data rows
      for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
        final row = rows[rowIndex];
        for (var colIndex = 0; colIndex < columns.length; colIndex++) {
          final value = row[columns[colIndex]];
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: rowIndex + 1)).value = value;
        }
      }
    }
    
    // Add enums sheet
    _addEnumsToExcel(excel);
    
    // Save Excel file
    final excelBytes = excel.encode();
    if (excelBytes != null) {
      final file = File(path.join(exportDir, 'inventory_data.xlsx'));
      await file.writeAsBytes(excelBytes);
    }
  }

  /// Export database to SQLite file
  Future<void> _exportToSqlite(String exportDir) async {
    final dbPath = _databaseService.database.path;
    final dbFile = File(dbPath);
    
    // Create a directory for the database file
    final sqliteDir = Directory(path.join(exportDir, 'sqlite'));
    await sqliteDir.create();
    
    // Copy the database file
    await dbFile.copy(path.join(sqliteDir.path, 'inventory_data.db'));
    
    // Export enum reference files
    await _exportEnumReferences(sqliteDir.path);
  }

  /// Export data to JSON files
  Future<void> _exportToJson(String exportDir) async {
    final db = _databaseService.database;
    
    // Create a directory for the JSON files
    final jsonDir = Directory(path.join(exportDir, 'json'));
    await jsonDir.create();
    
    // Export all tables
    final tables = [
      DatabaseService.tableItemDefinitions,
      DatabaseService.tableItemInstances,
      DatabaseService.tableInventoryMovements,
      DatabaseService.tableShipments,
      DatabaseService.tableShipmentItems,
    ];
    
    for (final table in tables) {
      // Get data
      final rows = await db.query(table);
      
      if (rows.isEmpty) continue;
      
      // Convert to JSON string
      final jsonString = jsonEncode(rows);
      
      // Write to file
      final file = File(path.join(jsonDir.path, '$table.json'));
      await file.writeAsString(jsonString);
    }
    
    // Export enums as JSON
    await _exportEnumsAsJson(jsonDir.path);
  }

  /// Export images
  Future<void> _exportImages(String exportDir) async {
    // Create a directory for the images
    final imagesDir = Directory(path.join(exportDir, 'images'));
    await imagesDir.create();
    
    try {
      // Get all item definitions
      final db = _databaseService.database;
      final items = await db.query(DatabaseService.tableItemDefinitions);
      
      // Copy images that are locally stored (not URLs)
      for (final item in items) {
        final imageUrl = item['imageUrl'] as String?;
        if (imageUrl != null && !imageUrl.startsWith('http')) {
          final imageFile = File(imageUrl);
          if (await imageFile.exists()) {
            final fileName = path.basename(imageUrl);
            await imageFile.copy(path.join(imagesDir.path, fileName));
          }
        }
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error exporting images', e, stackTrace, 'ExportService');
      // Don't fail the whole export if images fail
    }
  }

  /// Create zip archive of the export directory
  Future<void> _createZipArchive(String sourceDir, String zipPath) async {
    try {
      final encoder = ZipFileEncoder();
      encoder.create(zipPath);
      await encoder.addDirectory(Directory(sourceDir));
      encoder.close();
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error creating zip archive', e, stackTrace, 'ExportService');
      rethrow;
    }
  }

  /// Create README file
  Future<void> _createReadme(String exportDir, ExportMode mode) async {
    final readme = StringBuffer();
    
    readme.writeln('# Food Inventory Export');
    readme.writeln('');
    readme.writeln('## Export Information');
    readme.writeln('Date: ${DateTime.now().toLocal()}');
    readme.writeln('Format: ${_getModeDescription(mode)}');
    readme.writeln('');
    readme.writeln('## Tables');
    readme.writeln('The export contains the following tables:');
    readme.writeln('');
    readme.writeln('- `item_definitions`: Definitions of inventory items');
    readme.writeln('- `item_instances`: Actual inventory items (stock and inventory)');
    readme.writeln('- `inventory_movements`: Records of inventory changes');
    readme.writeln('- `shipments`: Shipment records');
    readme.writeln('- `shipment_items`: Items within shipments');
    readme.writeln('');
    readme.writeln('## Enum References');
    readme.writeln('The export also includes reference files for interpreting enum values:');
    readme.writeln('');
    readme.writeln('- `movement_types.txt`: Inventory movement type definitions');
    readme.writeln('');
    readme.writeln('## Usage Notes');
    readme.writeln('- Date fields are stored as milliseconds since epoch (Unix timestamp)');
    readme.writeln('- Boolean fields are stored as 1 (true) or 0 (false)');
    
    // Add format-specific notes
    switch (mode) {
      case ExportMode.csv:
        readme.writeln('- CSV files use comma as delimiter and double quotes as quote character');
        break;
      case ExportMode.excel:
        readme.writeln('- Excel file contains one sheet per table and an additional sheet for enum references');
        break;
      case ExportMode.sqlite:
        readme.writeln('- SQLite database file can be opened with any SQLite browser or client');
        break;
      case ExportMode.json:
        readme.writeln('- JSON files contain arrays of objects representing each table\'s records');
        break;
    }

    await File(path.join(exportDir, 'README.md')).writeAsString(readme.toString());
  }

  /// Create manifest file
  Future<void> _createManifest(String exportDir, ExportMode mode) async {
    final manifest = StringBuffer();
    
    manifest.writeln('Food Inventory Export Manifest');
    manifest.writeln('=============================');
    manifest.writeln('');
    manifest.writeln('Export Date: ${DateTime.now().toLocal()}');
    manifest.writeln('Export Format: ${_getModeDescription(mode)}');
    manifest.writeln('');
    
    // Add database statistics
    final db = _databaseService.database;
    final tables = [
      DatabaseService.tableItemDefinitions,
      DatabaseService.tableItemInstances,
      DatabaseService.tableInventoryMovements,
      DatabaseService.tableShipments,
      DatabaseService.tableShipmentItems,
    ];
    
    manifest.writeln('Database Statistics');
    manifest.writeln('-------------------');
    
    for (final table in tables) {
      final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $table'));
      manifest.writeln('$table: ${count ?? 0} records');
    }
    
    manifest.writeln('');
    manifest.writeln('File Contents');
    manifest.writeln('-------------');
    
    // List directories and files based on mode
    switch (mode) {
      case ExportMode.csv:
        manifest.writeln('- csv/: Directory containing CSV files');
        for (final table in tables) {
          manifest.writeln('  - $table.csv: Data from the $table table');
        }
        manifest.writeln('  - movement_types.csv: Enum values for movement types');
      case ExportMode.excel:
        manifest.writeln('- inventory_data.xlsx: Excel file containing all data');
        manifest.writeln('  - Sheets:');
        for (final table in tables) {
          manifest.writeln('    - $table: Data from the $table table');
        }
        manifest.writeln('    - enums: Reference for enum values');
      case ExportMode.sqlite:
        manifest.writeln('- sqlite/: Directory containing SQLite database');
        manifest.writeln('  - inventory_data.db: SQLite database file');
        manifest.writeln('  - enum_references/: Directory containing enum reference files');
      case ExportMode.json:
        manifest.writeln('- json/: Directory containing JSON files');
        for (final table in tables) {
          manifest.writeln('  - $table.json: Data from the $table table');
        }
        manifest.writeln('  - enums.json: Reference for enum values');
    }
    
    manifest.writeln('');
    manifest.writeln('- README.md: Information about the export');
    manifest.writeln('- manifest.txt: This file');
    manifest.writeln('- images/: Directory containing item images (if included)');

    await File(path.join(exportDir, 'manifest.txt')).writeAsString(manifest.toString());
  }

  /// Export enum reference files (CSV)
  Future<void> _exportEnums(String directoryPath) async {
    // Movement types enum
    final movementTypes = [
      {'id': MovementType.stockSale.index, 'name': 'Stock Sale', 'description': 'Decrease in stock (customer purchase)'},
      {'id': MovementType.inventoryToStock.index, 'name': 'Inventory to Stock', 'description': 'Move from inventory to stock'},
      {'id': MovementType.shipmentToInventory.index, 'name': 'Shipment to Inventory', 'description': 'Addition from a new shipment'},
    ];
    
    // Create CSV data
    final csvData = [
      ['id', 'name', 'description'], // Header row
      ...movementTypes.map((type) => [type['id'], type['name'], type['description']]),
    ];
    
    // Convert to CSV string
    final csv = const ListToCsvConverter().convert(csvData);
    
    // Write to file
    final file = File(path.join(directoryPath, 'movement_types.csv'));
    await file.writeAsString(csv);
  }

  /// Add enums to Excel file
  void _addEnumsToExcel(Excel excel) {
    // Create sheet for enums
    final sheet = excel['enums'];
    
    // Movement types
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = 'Movement Types';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value = 'id';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 1)).value = 'name';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 1)).value = 'description';
    
    final movementTypes = [
      {'id': MovementType.stockSale.index, 'name': 'Stock Sale', 'description': 'Decrease in stock (customer purchase)'},
      {'id': MovementType.inventoryToStock.index, 'name': 'Inventory to Stock', 'description': 'Move from inventory to stock'},
      {'id': MovementType.shipmentToInventory.index, 'name': 'Shipment to Inventory', 'description': 'Addition from a new shipment'},
    ];
    
    for (var i = 0; i < movementTypes.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 2)).value = movementTypes[i]['id'];
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 2)).value = movementTypes[i]['name'];
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 2)).value = movementTypes[i]['description'];
    }
  }

  /// Export enums as JSON
  Future<void> _exportEnumsAsJson(String directoryPath) async {
    final enums = {
      'movementTypes': [
        {'id': MovementType.stockSale.index, 'name': 'Stock Sale', 'description': 'Decrease in stock (customer purchase)'},
        {'id': MovementType.inventoryToStock.index, 'name': 'Inventory to Stock', 'description': 'Move from inventory to stock'},
        {'id': MovementType.shipmentToInventory.index, 'name': 'Shipment to Inventory', 'description': 'Addition from a new shipment'},
      ],
    };
    
    // Convert to JSON string
    final jsonString = jsonEncode(enums);
    
    // Write to file
    final file = File(path.join(directoryPath, 'enums.json'));
    await file.writeAsString(jsonString);
  }

  /// Export enum reference files for SQLite
  Future<void> _exportEnumReferences(String directoryPath) async {
    // Create a directory for enum references
    final enumDir = Directory(path.join(directoryPath, 'enum_references'));
    await enumDir.create();
    
    // Movement types
    final movementTypesFile = File(path.join(enumDir.path, 'movement_types.txt'));
    final movementTypesContent = StringBuffer();
    
    movementTypesContent.writeln('MOVEMENT_TYPE_STOCK_SALE = ${MovementType.stockSale.index} -- Decrease in stock (customer purchase)');
    movementTypesContent.writeln('MOVEMENT_TYPE_INVENTORY_TO_STOCK = ${MovementType.inventoryToStock.index} -- Move from inventory to stock');
    movementTypesContent.writeln('MOVEMENT_TYPE_SHIPMENT_TO_INVENTORY = ${MovementType.shipmentToInventory.index} -- Addition from a new shipment');
    
    await movementTypesFile.writeAsString(movementTypesContent.toString());
  }
  
  /// Get a human-readable description of the export mode
  String _getModeDescription(ExportMode mode) {
    switch (mode) {
      case ExportMode.csv:
        return 'CSV (Comma-Separated Values)';
      case ExportMode.excel:
        return 'Excel Spreadsheet';
      case ExportMode.sqlite:
        return 'SQLite Database';
      case ExportMode.json:
        return 'JSON (JavaScript Object Notation)';
    }
  }
}