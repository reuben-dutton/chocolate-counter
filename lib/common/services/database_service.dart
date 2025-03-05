import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:food_inventory/common/services/error_handler.dart';

class DatabaseService {
  static const String databaseName = 'food_inventory.db';
  static const int databaseVersion = 2;
  
  // Tables
  static const String tableItemDefinitions = 'item_definitions';
  static const String tableItemInstances = 'item_instances';
  static const String tableInventoryMovements = 'inventory_movements';
  static const String tableShipments = 'shipments';
  static const String tableShipmentItems = 'shipment_items';
  
  late Database _database;
  
  Future<void> initialize() async {
    try {
      final databasePath = await getDatabasesPath();
      final path = join(databasePath, databaseName);
      
      _database = await openDatabase(
        path,
        version: databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: (db) async {
          // Enable foreign keys
          await db.execute('PRAGMA foreign_keys = ON');
        },
      );
    } catch (e, stackTrace) {
      ErrorHandler.logError('Database initialization error', e, stackTrace, 'DatabaseService');
      rethrow;
    }
  }
  
  /// Creates the database schema with all tables and relationships
  Future<void> _onCreate(Database db, int version) async {
    try {
      // Item definitions table - parent table for inventory items
      await db.execute('''
        CREATE TABLE $tableItemDefinitions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          barcode TEXT,
          imageUrl TEXT
        )
      ''');
      
      // Shipments table - parent table for shipment items
      await db.execute('''
        CREATE TABLE $tableShipments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          date INTEGER NOT NULL
        )
      ''');
      
      // Shipment items table - links shipments to item definitions
      await db.execute('''
        CREATE TABLE $tableShipmentItems (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          shipmentId INTEGER NOT NULL,
          itemDefinitionId INTEGER NOT NULL,
          quantity INTEGER NOT NULL,
          expirationDate INTEGER,
          FOREIGN KEY (shipmentId) REFERENCES $tableShipments (id) ON DELETE CASCADE,
          FOREIGN KEY (itemDefinitionId) REFERENCES $tableItemDefinitions (id) ON DELETE CASCADE
        )
      ''');
      
      // Item instances table - actual inventory/stock items
      // Includes shipmentItemId to maintain relationship with origin shipment
      await db.execute('''
        CREATE TABLE $tableItemInstances (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          itemDefinitionId INTEGER NOT NULL,
          quantity INTEGER NOT NULL,
          expirationDate INTEGER,
          isInStock INTEGER NOT NULL,
          shipmentItemId INTEGER,
          FOREIGN KEY (itemDefinitionId) REFERENCES $tableItemDefinitions (id) ON DELETE CASCADE,
          FOREIGN KEY (shipmentItemId) REFERENCES $tableShipmentItems (id) ON DELETE SET NULL
        )
      ''');
      
      // Inventory movements table - tracks stock changes
      await db.execute('''
        CREATE TABLE $tableInventoryMovements (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          itemDefinitionId INTEGER NOT NULL,
          quantity INTEGER NOT NULL,
          timestamp INTEGER NOT NULL,
          type INTEGER NOT NULL,
          FOREIGN KEY (itemDefinitionId) REFERENCES $tableItemDefinitions (id) ON DELETE CASCADE
        )
      ''');
    } catch (e, stackTrace) {
      ErrorHandler.logError('Database creation error', e, stackTrace, 'DatabaseService');
      rethrow;
    }
  }
  
  /// Handles database migrations between versions
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      // Migration from version 1 to 2 - add shipmentItemId column to track relationships
      if (oldVersion < 2) {
        await db.execute('''
          ALTER TABLE $tableItemInstances ADD COLUMN shipmentItemId INTEGER
            REFERENCES $tableShipmentItems (id) ON DELETE SET NULL
        ''');
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError('Database upgrade error', e, stackTrace, 'DatabaseService');
      rethrow;
    }
  }
  
  Database get database => _database;
  
  /// Completely resets the database - for development and debugging only
  Future<void> resetDatabase() async {
    try {
      // Ensure database is closed
      if (_database.isOpen) {
        await _database.close();
      }
      
      // Get the full database path
      final databasePath = await getDatabasesPath();
      final path = join(databasePath, databaseName);
      
      // Delete the database file
      await deleteDatabase(path);
      
      // Reinitialize the database
      await initialize();
    } catch (e, stackTrace) {
      ErrorHandler.logError('Database reset error', e, stackTrace, 'DatabaseService');
      rethrow;
    }
  }
}