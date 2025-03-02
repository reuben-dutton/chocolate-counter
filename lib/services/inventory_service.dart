import 'package:food_inventory/models/inventory_movement.dart';
import 'package:food_inventory/models/item_definition.dart';
import 'package:food_inventory/models/item_instance.dart';
import 'package:food_inventory/repositories/inventory_movement_repository.dart';
import 'package:food_inventory/repositories/item_definition_repository.dart';
import 'package:food_inventory/repositories/item_instance_repository.dart';

/// Service for managing inventory-related operations
class InventoryService {
  final ItemDefinitionRepository _itemDefinitionRepository;
  final ItemInstanceRepository _itemInstanceRepository;
  final InventoryMovementRepository _inventoryMovementRepository;

  InventoryService(
    this._itemDefinitionRepository,
    this._itemInstanceRepository,
    this._inventoryMovementRepository,
  );

  /// Get all item definitions with their current counts
  Future<List<ItemDefinition>> getAllItemDefinitions() async {
    return _itemDefinitionRepository.getAllSorted();
  }
  
  /// Get a specific item definition
  Future<ItemDefinition?> getItemDefinition(int id) async {
    return _itemDefinitionRepository.getById(id);
  }
  
  /// Create a new item definition
  Future<int> createItemDefinition(ItemDefinition item) async {
    return _itemDefinitionRepository.create(item);
  }
  
  /// Update an existing item definition
  Future<int> updateItemDefinition(ItemDefinition item) async {
    return _itemDefinitionRepository.update(item);
  }
  
  /// Delete an item definition and all related data
  Future<int> deleteItemDefinition(int id) async {
    return _itemDefinitionRepository.delete(id);
  }
  
  /// Get all item instances for a specific item definition
  Future<List<ItemInstance>> getItemInstances(int itemDefinitionId) async {
    return _itemInstanceRepository.getInstancesForItem(itemDefinitionId);
  }
  
  /// Get current counts for an item (stock and inventory)
  Future<Map<String, int>> getItemCounts(int itemDefinitionId) async {
    return _itemInstanceRepository.getItemCounts(itemDefinitionId);
  }
  
  /// Add a new item to inventory
  Future<int> addToInventory(
    int itemDefinitionId,
    int quantity,
    DateTime? expirationDate, {
    int? shipmentItemId,
  }) async {
    final itemInstance = ItemInstance(
      itemDefinitionId: itemDefinitionId,
      quantity: quantity,
      expirationDate: expirationDate,
      isInStock: false, // Add to inventory, not stock
      shipmentItemId: shipmentItemId,
    );
    
    return _itemInstanceRepository.create(itemInstance);
  }
  
  /// Update stock count (record sale)
  Future<void> updateStockCount(
    int itemDefinitionId, 
    int decreaseAmount, {
    DateTime? timestamp,
  }) async {
    final db = _itemInstanceRepository.databaseService.database;
    final actualTimestamp = timestamp ?? DateTime.now();
    
    await db.transaction((txn) async {
      // Get current stock items sorted by expiration date (earliest first)
      final stockItems = await _itemInstanceRepository.getStockInstances(itemDefinitionId);
      var remainingDecrease = decreaseAmount;
      
      // Loop through stock items and decrease quantities
      for (final instance in stockItems) {
        if (remainingDecrease <= 0) break;
        
        if (instance.quantity <= remainingDecrease) {
          // Remove the entire item instance
          await _itemInstanceRepository.delete(instance.id!);
          remainingDecrease -= instance.quantity;
        } else {
          // Partially decrease the item instance
          final updatedInstance = ItemInstance(
            id: instance.id,
            itemDefinitionId: instance.itemDefinitionId,
            quantity: instance.quantity - remainingDecrease,
            expirationDate: instance.expirationDate,
            isInStock: instance.isInStock,
            shipmentItemId: instance.shipmentItemId,
          );
          
          await _itemInstanceRepository.update(updatedInstance);
          remainingDecrease = 0;
        }
      }
      
      // Record the movement
      await _inventoryMovementRepository.recordStockSale(
        itemDefinitionId, 
        decreaseAmount, 
        actualTimestamp
      );
    });
  }
  
  /// Move items from inventory to stock
  Future<void> moveInventoryToStock(
    int itemDefinitionId,
    int moveAmount, {
    DateTime? timestamp,
  }) async {
    final db = _itemInstanceRepository.databaseService.database;
    final actualTimestamp = timestamp ?? DateTime.now();
    
    await db.transaction((txn) async {
      // Get current inventory items sorted by expiration date (earliest first)
      final inventoryItems = await _itemInstanceRepository.getInventoryInstances(itemDefinitionId);
      var remainingMove = moveAmount;
      
      // Loop through inventory items and move quantities to stock
      for (final instance in inventoryItems) {
        if (remainingMove <= 0) break;
        
        if (instance.quantity <= remainingMove) {
          // Move the entire item instance to stock
          final updatedInstance = ItemInstance(
            id: instance.id,
            itemDefinitionId: instance.itemDefinitionId,
            quantity: instance.quantity,
            expirationDate: instance.expirationDate,
            isInStock: true, // Now in stock
            shipmentItemId: instance.shipmentItemId,
          );
          
          await _itemInstanceRepository.update(updatedInstance);
          remainingMove -= instance.quantity;
        } else {
          // Split the item instance
          // First, reduce the inventory instance quantity
          final updatedInventoryInstance = ItemInstance(
            id: instance.id,
            itemDefinitionId: instance.itemDefinitionId,
            quantity: instance.quantity - remainingMove,
            expirationDate: instance.expirationDate,
            isInStock: false,
            shipmentItemId: instance.shipmentItemId,
          );
          
          await _itemInstanceRepository.update(updatedInventoryInstance);
          
          // Then create a new stock instance for the moved quantity
          final newStockInstance = ItemInstance(
            itemDefinitionId: instance.itemDefinitionId,
            quantity: remainingMove,
            expirationDate: instance.expirationDate,
            isInStock: true,
            shipmentItemId: instance.shipmentItemId,
          );
          
          await _itemInstanceRepository.create(newStockInstance);
          
          remainingMove = 0;
        }
      }
      
      // Record the inventory-to-stock movement
      await _inventoryMovementRepository.recordInventoryToStock(
        itemDefinitionId, 
        moveAmount, 
        actualTimestamp
      );
    });
  }
  
  /// Get movement history for an item
  Future<List<InventoryMovement>> getItemMovements(int itemDefinitionId) async {
    return _inventoryMovementRepository.getMovementsForItem(itemDefinitionId);
  }
  
  /// Clear movement history for an item
  Future<int> clearMovementHistory(int itemDefinitionId) async {
    return _inventoryMovementRepository.clearMovementsForItem(itemDefinitionId);
  }
  
  /// Search items by name
  Future<List<ItemDefinition>> searchItems(String query) async {
    if (query.isEmpty) {
      return getAllItemDefinitions();
    }
    return _itemDefinitionRepository.searchByName(query);
  }
  
  /// Find item by barcode
  Future<ItemDefinition?> findItemByBarcode(String barcode) async {
    return _itemDefinitionRepository.findByBarcode(barcode);
  }
}