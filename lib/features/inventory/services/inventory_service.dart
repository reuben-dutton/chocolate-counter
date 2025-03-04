import 'package:food_inventory/data/factories/inventory_movement_factory.dart';
import 'package:food_inventory/data/factories/item_instance_factory.dart';
import 'package:food_inventory/data/models/inventory_movement.dart';
import 'package:food_inventory/data/models/item_definition.dart';
import 'package:food_inventory/data/models/item_instance.dart';
import 'package:food_inventory/data/repositories/inventory_movement_repository.dart';
import 'package:food_inventory/data/repositories/item_definition_repository.dart';
import 'package:food_inventory/data/repositories/item_instance_repository.dart';


/// Service for managing inventory-related operations
class InventoryService {
  final ItemDefinitionRepository _itemDefinitionRepository;
  final ItemInstanceRepository _itemInstanceRepository;
  final InventoryMovementRepository _inventoryMovementRepository;
  final ItemInstanceFactory _itemInstanceFactory;
  final InventoryMovementFactory _movementFactory;

  InventoryService(
    this._itemDefinitionRepository,
    this._itemInstanceRepository,
    this._inventoryMovementRepository,
  ) : 
    _itemInstanceFactory = ItemInstanceFactory(_itemInstanceRepository, _itemDefinitionRepository),
    _movementFactory = InventoryMovementFactory(_inventoryMovementRepository);

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
    return _itemInstanceFactory.addToInventory(
      itemDefinitionId: itemDefinitionId,
      quantity: quantity,
      expirationDate: expirationDate,
      shipmentItemId: shipmentItemId,
    );
  }
  
  // Update stock count (record sale)
  Future<void> updateStockCount(
    int itemDefinitionId, 
    int decreaseAmount, {
    DateTime? timestamp,
  }) async {
    final actualTimestamp = timestamp ?? DateTime.now();
    
    await _itemInstanceRepository.withTransaction((txn) async {
      // Fetch stock items INSIDE the transaction
      final stockItems = await _itemInstanceRepository.getStockInstances(itemDefinitionId, txn: txn);
      
      var remainingDecrease = decreaseAmount;
      
      // Loop through stock items and decrease quantities
      for (final instance in stockItems) {
        if (remainingDecrease <= 0) break;
        
        if (instance.quantity <= remainingDecrease) {
          // Remove the entire item instance
          await _itemInstanceRepository.delete(instance.id!, txn: txn);
          remainingDecrease -= instance.quantity;
        } else {
          // Partially decrease the item instance
          final updatedInstance = instance.copyWith(
            quantity: instance.quantity - remainingDecrease,
          );
          
          await _itemInstanceRepository.update(updatedInstance, txn: txn);
          remainingDecrease = 0;
        }
      }
      
      // Record the movement
      await _movementFactory.recordStockSale(
        itemDefinitionId: itemDefinitionId,
        quantity: decreaseAmount,
        timestamp: actualTimestamp,
        txn: txn
      );
    });
  }
  
  // Move items from inventory to stock
  Future<void> moveInventoryToStock(
    int itemDefinitionId,
    int moveAmount, {
    DateTime? timestamp,
  }) async {
    final actualTimestamp = timestamp ?? DateTime.now();
    
    await _itemInstanceRepository.withTransaction((txn) async {
      // Fetch inventory items INSIDE the transaction
      final inventoryItems = await _itemInstanceRepository.getInventoryInstances(itemDefinitionId, txn: txn);
      
      var remainingMove = moveAmount;
      
      // Loop through inventory items and move quantities to stock
      for (final instance in inventoryItems) {
        if (remainingMove <= 0) break;
        
        if (instance.quantity <= remainingMove) {
          // Move the entire item instance to stock
          final updatedInstance = instance.copyWith(
            isInStock: true, // Now in stock
          );
          
          await _itemInstanceRepository.update(updatedInstance, txn: txn);
          remainingMove -= instance.quantity;
        } else {
          // Split the item instance
          // First, reduce the inventory instance quantity
          final updatedInventoryInstance = instance.copyWith(
            quantity: instance.quantity - remainingMove,
          );
          
          await _itemInstanceRepository.update(updatedInventoryInstance, txn: txn);
          
          // Then create a new stock instance for the moved quantity
          await _itemInstanceFactory.addToStock(
            itemDefinitionId: instance.itemDefinitionId,
            quantity: remainingMove,
            expirationDate: instance.expirationDate,
            shipmentItemId: instance.shipmentItemId,
            txn: txn
          );
          
          remainingMove = 0;
        }
      }
      
      // Record the inventory-to-stock movement
      await _movementFactory.recordInventoryToStock(
        itemDefinitionId: itemDefinitionId,
        quantity: moveAmount,
        timestamp: actualTimestamp,
        txn: txn
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