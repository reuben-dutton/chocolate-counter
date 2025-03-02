import 'package:food_inventory/models/inventory_movement.dart';
import 'package:food_inventory/models/item_definition.dart';
import 'package:food_inventory/models/item_instance.dart';
import 'package:food_inventory/services/database_service.dart';

class InventoryService {
  final DatabaseService _databaseService;
  
  InventoryService(this._databaseService);
  
  // Item Definition methods
  Future<List<ItemDefinition>> getAllItemDefinitions() async {
    final db = _databaseService.database;
    
    // Get all item definitions
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseService.tableItemDefinitions,
      orderBy: 'name ASC',
    );
    
    // Convert to ItemDefinition objects
    final items = List.generate(maps.length, (i) {
      return ItemDefinition.fromMap(maps[i]);
    });
    
    // Fetch counts for each item
    final List<ItemDefinition> sortedItems = [];
    final List<ItemDefinition> zeroCountItems = [];
    
    for (final item in items) {
      if (item.id == null) continue;
      
      final counts = await getItemCounts(item.id!);
      final totalCount = counts['stock']! + counts['inventory']!;
      
      if (totalCount > 0) {
        sortedItems.add(item);
      } else {
        zeroCountItems.add(item);
      }
    }
    
    // Sort non-zero items by name and append zero-count items
    sortedItems.sort((a, b) => a.name.compareTo(b.name));
    zeroCountItems.sort((a, b) => a.name.compareTo(b.name));
    
    return [...sortedItems, ...zeroCountItems];
  }
  
  Future<ItemDefinition?> getItemDefinition(int id) async {
    final db = _databaseService.database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseService.tableItemDefinitions,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (maps.isEmpty) {
        return null;
      }
      
      return ItemDefinition.fromMap(maps.first);
    } catch (e) {
      print('Error getting item definition: $e');
      return null;
    }
  }
  
  Future<int> createItemDefinition(ItemDefinition item) async {
    final db = _databaseService.database;
    return await db.insert(
      DatabaseService.tableItemDefinitions,
      item.toMap()..remove('id'),
    );
  }
  
  Future<int> updateItemDefinition(ItemDefinition item) async {
    final db = _databaseService.database;
    return await db.update(
      DatabaseService.tableItemDefinitions,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }
  
  Future<int> deleteItemDefinition(int id) async {
    final db = _databaseService.database;
    
    // All associated records will be deleted by cascade constraints
    return await db.delete(
      DatabaseService.tableItemDefinitions,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  // Item Instance methods
  Future<List<ItemInstance>> getItemInstances(int itemDefinitionId) async {
    final db = _databaseService.database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseService.tableItemInstances,
        where: 'itemDefinitionId = ?',
        whereArgs: [itemDefinitionId],
      );
      
      final itemDef = await getItemDefinition(itemDefinitionId);
      
      return List.generate(maps.length, (i) {
        return ItemInstance.fromMap(maps[i], itemDef: itemDef);
      });
    } catch (e) {
      print('Error getting item instances: $e');
      return [];
    }
  }
  
  /// Returns a map with 'stock' and 'inventory' counts for an item definition
  Future<Map<String, int>> getItemCounts(int itemDefinitionId) async {
    final db = _databaseService.database;
    
    try {
      // Get stock count - items with isInStock = 1
      final stockResult = await db.rawQuery('''
        SELECT COALESCE(SUM(quantity), 0) as count
        FROM ${DatabaseService.tableItemInstances}
        WHERE itemDefinitionId = ? AND isInStock = 1
      ''', [itemDefinitionId]);
      
      // Get inventory count - items with isInStock = 0
      final inventoryResult = await db.rawQuery('''
        SELECT COALESCE(SUM(quantity), 0) as count
        FROM ${DatabaseService.tableItemInstances}
        WHERE itemDefinitionId = ? AND isInStock = 0
      ''', [itemDefinitionId]);
      
      return {
        'stock': stockResult.first['count'] as int,
        'inventory': inventoryResult.first['count'] as int,
      };
    } catch (e) {
      print('Error getting item counts: $e');
      return {'stock': 0, 'inventory': 0};
    }
  }
  
  /// Adds a new item to inventory with optional link to shipment item
  Future<int> addToInventory(
    int itemDefinitionId,
    int quantity,
    DateTime? expirationDate,
    {int? shipmentItemId}
  ) async {
    final db = _databaseService.database;
    
    // Create a new item instance in inventory with shipmentItemId reference
    final itemInstance = ItemInstance(
      itemDefinitionId: itemDefinitionId,
      quantity: quantity,
      expirationDate: expirationDate,
      isInStock: false, // Add to inventory, not stock
      shipmentItemId: shipmentItemId,
    );
    
    return await db.insert(
      DatabaseService.tableItemInstances,
      itemInstance.toMap()..remove('id'),
    );
  }
  
  /// Decreases stock count and records the movement
  Future<void> updateStockCount(
    int itemDefinitionId,
    int decreaseAmount, {
    DateTime? timestamp,
  }) async {
    final db = _databaseService.database;
    
    await db.transaction((txn) async {
      // Get current stock items sorted by expiration date (earliest first)
      final List<Map<String, dynamic>> stockItems = await txn.query(
        DatabaseService.tableItemInstances,
        where: 'itemDefinitionId = ? AND isInStock = 1',
        whereArgs: [itemDefinitionId],
        orderBy: 'CASE WHEN expirationDate IS NULL THEN 1 ELSE 0 END, expirationDate ASC',
      );
      
      var remainingDecrease = decreaseAmount;
      
      // Loop through stock items and decrease quantities
      for (final item in stockItems) {
        if (remainingDecrease <= 0) break;
        
        final instance = ItemInstance.fromMap(item);
        
        if (instance.quantity <= remainingDecrease) {
          // Remove the entire item instance
          await txn.delete(
            DatabaseService.tableItemInstances,
            where: 'id = ?',
            whereArgs: [instance.id],
          );
          remainingDecrease -= instance.quantity;
        } else {
          // Partially decrease the item instance
          await txn.update(
            DatabaseService.tableItemInstances,
            {'quantity': instance.quantity - remainingDecrease},
            where: 'id = ?',
            whereArgs: [instance.id],
          );
          remainingDecrease = 0;
        }
      }
      
      // Record the stock decrease as a movement
      final movement = InventoryMovement(
        itemDefinitionId: itemDefinitionId,
        quantity: decreaseAmount,
        timestamp: timestamp ?? DateTime.now(),
        type: MovementType.stockSale,
      );
      
      await txn.insert(
        DatabaseService.tableInventoryMovements,
        movement.toMap()..remove('id'),
      );
    });
  }
  
  /// Moves items from inventory to stock, preserving shipment relationships
  Future<void> moveInventoryToStock(
    int itemDefinitionId,
    int moveAmount, {
    DateTime? timestamp,
  }) async {
    final db = _databaseService.database;
    
    await db.transaction((txn) async {
      // Get current inventory items sorted by expiration date (earliest first)
      final List<Map<String, dynamic>> inventoryItems = await txn.query(
        DatabaseService.tableItemInstances,
        where: 'itemDefinitionId = ? AND isInStock = 0',
        whereArgs: [itemDefinitionId],
        orderBy: 'CASE WHEN expirationDate IS NULL THEN 1 ELSE 0 END, expirationDate ASC',
      );
      
      var remainingMove = moveAmount;
      
      // Loop through inventory items and move quantities to stock
      for (final item in inventoryItems) {
        if (remainingMove <= 0) break;
        
        final instance = ItemInstance.fromMap(item);
        
        if (instance.quantity <= remainingMove) {
          // Move the entire item instance to stock
          await txn.update(
            DatabaseService.tableItemInstances,
            {'isInStock': 1},
            where: 'id = ?',
            whereArgs: [instance.id],
          );
          remainingMove -= instance.quantity;
        } else {
          // Split the item instance
          // First, reduce the inventory instance quantity
          await txn.update(
            DatabaseService.tableItemInstances,
            {'quantity': instance.quantity - remainingMove},
            where: 'id = ?',
            whereArgs: [instance.id],
          );
          
          // Then create a new stock instance for the moved quantity
          final stockInstance = ItemInstance(
            itemDefinitionId: itemDefinitionId,
            quantity: remainingMove,
            expirationDate: instance.expirationDate,
            isInStock: true,
            shipmentItemId: instance.shipmentItemId, // Preserve shipment relationship
          );
          
          await txn.insert(
            DatabaseService.tableItemInstances,
            stockInstance.toMap()..remove('id'),
          );
          
          remainingMove = 0;
        }
      }
      
      // Record the inventory-to-stock movement
      final movement = InventoryMovement(
        itemDefinitionId: itemDefinitionId,
        quantity: moveAmount,
        timestamp: timestamp ?? DateTime.now(),
        type: MovementType.inventoryToStock,
      );
      
      await txn.insert(
        DatabaseService.tableInventoryMovements,
        movement.toMap()..remove('id'),
      );
    });
  }
  
  // Inventory Movement methods
  Future<List<InventoryMovement>> getItemMovements(int itemDefinitionId) async {
    final db = _databaseService.database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseService.tableInventoryMovements,
        where: 'itemDefinitionId = ?',
        whereArgs: [itemDefinitionId],
        orderBy: 'timestamp DESC',
      );
      
      final itemDef = await getItemDefinition(itemDefinitionId);
      
      return List.generate(maps.length, (i) {
        return InventoryMovement.fromMap(maps[i], itemDef: itemDef);
      });
    } catch (e) {
      print('Error getting item movements: $e');
      return [];
    }
  }
  
  Future<int> clearMovementHistory(int itemDefinitionId) async {
    final db = _databaseService.database;
    return await db.delete(
      DatabaseService.tableInventoryMovements,
      where: 'itemDefinitionId = ?',
      whereArgs: [itemDefinitionId],
    );
  }
}