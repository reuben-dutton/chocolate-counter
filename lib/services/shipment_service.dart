import 'package:food_inventory/models/item_definition.dart';
import 'package:food_inventory/models/item_instance.dart';
import 'package:food_inventory/models/shipment.dart';
import 'package:food_inventory/models/shipment_item.dart';
import 'package:food_inventory/services/database_service.dart';


class ShipmentService {
  final DatabaseService _databaseService;
  
  ShipmentService(this._databaseService, _inventoryService);
  
  /// Returns all shipments ordered by date (newest first)
  Future<List<Shipment>> getAllShipments() async {
    final db = _databaseService.database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseService.tableShipments,
        orderBy: 'date DESC',
      );
      
      return Future.wait(
        maps.map((map) async {
          final shipmentId = map['id'] as int;
          final items = await getShipmentItems(shipmentId);
          return Shipment.fromMap(map, shipmentItems: items);
        }).toList(),
      );
    } catch (e) {
      print('Error fetching shipments: $e');
      return [];
    }
  }
  
  /// Returns a single shipment by ID with its items
  Future<Shipment?> getShipment(int id) async {
    final db = _databaseService.database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseService.tableShipments,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (maps.isEmpty) {
        return null;
      }
      
      final items = await getShipmentItems(id);
      return Shipment.fromMap(maps.first, shipmentItems: items);
    } catch (e) {
      print('Error fetching shipment: $e');
      return null;
    }
  }
  
  /// Returns items in a shipment with their related item definitions
  Future<List<ShipmentItem>> getShipmentItems(int shipmentId) async {
    final db = _databaseService.database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseService.tableShipmentItems,
        where: 'shipmentId = ?',
        whereArgs: [shipmentId],
      );
      
      if (maps.isEmpty) {
        return [];
      }
      
      // Get all unique item definition IDs
      final itemDefinitionIds = maps
          .map((map) => map['itemDefinitionId'] as int)
          .toSet()
          .toList();
      
      // Fetch all item definitions in a single query for efficiency
      final List<Map<String, dynamic>> itemDefMaps = await db.query(
          DatabaseService.tableItemDefinitions,
          where: 'id IN (${List.filled(itemDefinitionIds.length, '?').join(', ')})',
          whereArgs: itemDefinitionIds,
      );
      
      // Create a map of item definition ID to item definition for lookup
      final itemDefinitions = {
        for (var map in itemDefMaps)
          map['id'] as int: ItemDefinition.fromMap(map)
      };
      
      return List.generate(maps.length, (i) {
        final map = maps[i];
        final itemDefId = map['itemDefinitionId'] as int;
        return ShipmentItem.fromMap(
          map,
          itemDef: itemDefinitions[itemDefId],
        );
      });
    } catch (e) {
      print('Error fetching shipment items: $e');
      return [];
    }
  }
  
  /// Creates a new shipment and adds inventory items for each shipment item
  /// Links inventory items to their originating shipment items
  Future<int> createShipment(Shipment shipment) async {
    final db = _databaseService.database;
    
    try {
      // Use a single transaction for all operations to ensure data consistency
      return await db.transaction((txn) async {
        // Insert shipment
        final shipmentId = await txn.insert(
          DatabaseService.tableShipments,
          shipment.toMap()..remove('id'),
        );
        
        // Process each shipment item
        for (final item in shipment.items) {
          // Create a new ShipmentItem with updated shipmentId
          final newItem = ShipmentItem(
            shipmentId: shipmentId,
            itemDefinitionId: item.itemDefinitionId,
            quantity: item.quantity,
            expirationDate: item.expirationDate,
            itemDefinition: item.itemDefinition,
          );
          
          // Insert into shipment_items table
          final shipmentItemId = await txn.insert(
            DatabaseService.tableShipmentItems,
            newItem.toMap()..remove('id'),
          );
          
          // Create inventory item with reference to shipment item
          final itemInstance = ItemInstance(
            itemDefinitionId: item.itemDefinitionId,
            quantity: item.quantity,
            expirationDate: item.expirationDate,
            isInStock: false, // Add to inventory, not stock
            shipmentItemId: shipmentItemId,
          );
          
          await txn.insert(
            DatabaseService.tableItemInstances,
            itemInstance.toMap()..remove('id'),
          );
        }
        
        return shipmentId;
      });
    } catch (e) {
      print('Error creating shipment: $e');
      rethrow; // Re-throw to let UI handle the error
    }
  }
  
  /// Deletes a shipment and its items (inventory items are not affected)
  Future<int> deleteShipment(int id) async {
    final db = _databaseService.database;
    
    try {
      // Delete the shipment (cascade will delete shipment items)
      return await db.delete(
        DatabaseService.tableShipments,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error deleting shipment: $e');
      return 0;
    }
  }
  
  /// Updates the expiration date of a shipment item and all linked inventory items
  Future<int> updateShipmentItemExpiration(int shipmentItemId, DateTime? expirationDate) async {
    final db = _databaseService.database;
    
    try {
      return await db.transaction((txn) async {
        // Update the shipment item expiration date
        final result = await txn.update(
          DatabaseService.tableShipmentItems,
          {'expirationDate': expirationDate?.millisecondsSinceEpoch},
          where: 'id = ?',
          whereArgs: [shipmentItemId],
        );
        
        // Update all linked inventory items
        await txn.update(
          DatabaseService.tableItemInstances,
          {'expirationDate': expirationDate?.millisecondsSinceEpoch},
          where: 'shipmentItemId = ?',
          whereArgs: [shipmentItemId],
        );
        
        return result;
      });
    } catch (e) {
      print('Error updating expiration date: $e');
      return 0;
    }
  }
  
  /// Get a specific shipment item by ID with its item definition
  Future<ShipmentItem?> getShipmentItem(int shipmentItemId) async {
    final db = _databaseService.database;
    
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseService.tableShipmentItems,
        where: 'id = ?',
        whereArgs: [shipmentItemId],
        limit: 1,
      );
      
      if (maps.isEmpty) {
        return null;
      }
      
      final map = maps.first;
      final itemDefId = map['itemDefinitionId'] as int;
      
      // Get the item definition
      final List<Map<String, dynamic>> itemDefMaps = await db.query(
        DatabaseService.tableItemDefinitions,
        where: 'id = ?',
        whereArgs: [itemDefId],
        limit: 1,
      );
      
      ItemDefinition? itemDef;
      if (itemDefMaps.isNotEmpty) {
        itemDef = ItemDefinition.fromMap(itemDefMaps.first);
      }
      
      return ShipmentItem.fromMap(map, itemDef: itemDef);
    } catch (e) {
      print('Error fetching shipment item: $e');
      return null;
    }
  }
}