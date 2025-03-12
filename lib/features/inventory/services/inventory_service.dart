import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/data/factories/inventory_movement_factory.dart';
import 'package:food_inventory/data/factories/item_instance_factory.dart';
import 'package:food_inventory/data/models/inventory_movement.dart';
import 'package:food_inventory/data/models/item_definition.dart';
import 'package:food_inventory/data/models/item_instance.dart';
import 'package:food_inventory/data/repositories/inventory_movement_repository.dart';
import 'package:food_inventory/data/repositories/item_definition_repository.dart';
import 'package:food_inventory/data/repositories/item_instance_repository.dart';
import 'package:sqflite/sqflite.dart';

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

  /// Run a function within a transaction
  Future<R> withTransaction<R>(Future<R> Function(Transaction txn) action) async {
    return _itemDefinitionRepository.withTransaction(action);
  }

  /// Get all item definitions with their current counts
  Future<List<ItemDefinition>> getAllItemDefinitions({Transaction? txn}) async {
    try {
      return _itemDefinitionRepository.getAllSorted(txn: txn);
    } catch (e, stackTrace) {
      ErrorHandler.logError('Failed to get all item definitions', e, stackTrace, 'InventoryService');
      rethrow;
    }
  }
  
  /// Get a specific item definition
  Future<ItemDefinition?> getItemDefinition(int id, {Transaction? txn}) async {
    try {
      return _itemDefinitionRepository.getById(id, txn: txn);
    } catch (e, stackTrace) {
      ErrorHandler.logError('Failed to get item definition', e, stackTrace, 'InventoryService');
      rethrow;
    }
  }
  
  /// Create a new item definition
  Future<int> createItemDefinition(ItemDefinition item, {Transaction? txn}) async {
    try {
      return _itemDefinitionRepository.create(item, txn: txn);
    } catch (e, stackTrace) {
      ErrorHandler.logError('Failed to create item definition', e, stackTrace, 'InventoryService');
      rethrow;
    }
  }
  
  /// Update an existing item definition
  Future<int> updateItemDefinition(ItemDefinition item, {Transaction? txn}) async {
    try {
      return _itemDefinitionRepository.update(item, txn: txn);
    } catch (e, stackTrace) {
      ErrorHandler.logError('Failed to update item definition', e, stackTrace, 'InventoryService');
      rethrow;
    }
  }
  
  /// Delete an item definition and all related data
  Future<int> deleteItemDefinition(int id, {Transaction? txn}) async {
    try {
      return _itemDefinitionRepository.delete(id, txn: txn);
    } catch (e, stackTrace) {
      ErrorHandler.logError('Failed to delete item definition', e, stackTrace, 'InventoryService');
      rethrow;
    }
  }
  
  /// Get all item instances for a specific item definition
  Future<List<ItemInstance>> getItemInstances(int itemDefinitionId, {Transaction? txn}) async {
    try {
      return _itemInstanceRepository.getInstancesForItem(itemDefinitionId, txn: txn);
    } catch (e, stackTrace) {
      ErrorHandler.logError('Failed to get item instances', e, stackTrace, 'InventoryService');
      rethrow;
    }
  }
  
  /// Get current counts for an item (stock and inventory)
  Future<Map<String, int>> getItemCounts(int itemDefinitionId, {Transaction? txn}) async {
    try {
      return _itemInstanceRepository.getItemCounts(itemDefinitionId, txn: txn);
    } catch (e, stackTrace) {
      ErrorHandler.logError('Failed to get item counts', e, stackTrace, 'InventoryService');
      rethrow;
    }
  }
  
  /// Add a new item to inventory
  Future<int> addToInventory(
    int itemDefinitionId,
    int quantity,
    DateTime? expirationDate, {
    int? shipmentItemId,
    Transaction? txn,
  }) async {
    try {
      return _itemInstanceFactory.addToInventory(
        itemDefinitionId: itemDefinitionId,
        quantity: quantity,
        expirationDate: expirationDate,
        shipmentItemId: shipmentItemId,
        txn: txn,
      );
    } catch (e, stackTrace) {
      ErrorHandler.logError('Failed to add item to inventory', e, stackTrace, 'InventoryService');
      rethrow;
    }
  }
  
// Update stock count (record sale)
  Future<void> updateStockCount(
    int itemDefinitionId, 
    int decreaseAmount, {
    DateTime? timestamp,
    Transaction? txn,
  }) async {
    final actualTimestamp = timestamp ?? DateTime.now();
    
    try {
      if (txn != null) {
        await _updateStock(itemDefinitionId, decreaseAmount, actualTimestamp, txn);
      } else {
        await _itemInstanceRepository.withTransaction((transaction) async {
          await _updateStock(itemDefinitionId, decreaseAmount, actualTimestamp, transaction);
        });
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError('Failed to update stock count', e, stackTrace, 'InventoryService');
      rethrow;
    }
  }
  
  // Helper method for stock update operations
  Future<void> _updateStock(
    int itemDefinitionId,
    int decreaseAmount,
    DateTime timestamp,
    Transaction txn
  ) async {
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
    InventoryMovement newMovement = _movementFactory.createStockSaleMovement(
      itemDefinitionId: itemDefinitionId,
      quantity: decreaseAmount,
      timestamp: timestamp,
    );

    await _movementFactory.save(newMovement, txn: txn);
  }
  
// Move items from inventory to stock
  Future<void> moveInventoryToStock(
    int itemDefinitionId,
    int moveAmount, {
    DateTime? timestamp,
    Transaction? txn,
  }) async {
    final actualTimestamp = timestamp ?? DateTime.now();
    
    try {
      if (txn != null) {
        await _moveToStock(itemDefinitionId, moveAmount, actualTimestamp, txn);
      } else {
        await _itemInstanceRepository.withTransaction((transaction) async {
          await _moveToStock(itemDefinitionId, moveAmount, actualTimestamp, transaction);
        });
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError('Failed to move inventory to stock', e, stackTrace, 'InventoryService');
      rethrow;
    }
  }
  
  // Helper method for movement operations
  Future<void> _moveToStock(
    int itemDefinitionId,
    int moveAmount,
    DateTime timestamp,
    Transaction txn
  ) async {
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
    InventoryMovement newMovement = _movementFactory.createInventoryToStockMovement(
      itemDefinitionId: itemDefinitionId,
      quantity: moveAmount,
      timestamp: timestamp,
    );

    await _movementFactory.save(newMovement, txn: txn);
  }
  
  /// Get movement history for an item
  Future<List<InventoryMovement>> getItemMovements(int itemDefinitionId, {Transaction? txn}) async {
    try {
      return _inventoryMovementRepository.getMovementsForItem(itemDefinitionId, txn: txn);
    } catch (e, stackTrace) {
      ErrorHandler.logError('Failed to get item movements', e, stackTrace, 'InventoryService');
      rethrow;
    }
  }
  
  /// Clear movement history for an item
  Future<int> clearMovementHistory(int itemDefinitionId, {Transaction? txn}) async {
    try {
      return _inventoryMovementRepository.clearMovementsForItem(itemDefinitionId, txn: txn);
    } catch (e, stackTrace) {
      ErrorHandler.logError('Failed to clear movement history', e, stackTrace, 'InventoryService');
      rethrow;
    }
  }
  
  /// Search items by name
  Future<List<ItemDefinition>> searchItems(String query, {Transaction? txn}) async {
    try {
      if (query.isEmpty) {
        return getAllItemDefinitions(txn: txn);
      }
      return _itemDefinitionRepository.searchByName(query, txn: txn);
    } catch (e, stackTrace) {
      ErrorHandler.logError('Failed to search items', e, stackTrace, 'InventoryService');
      rethrow;
    }
  }
  
  /// Find item by barcode
  Future<ItemDefinition?> findItemByBarcode(String barcode, {Transaction? txn}) async {
    try {
      return _itemDefinitionRepository.findByBarcode(barcode, txn: txn);
    } catch (e, stackTrace) {
      ErrorHandler.logError('Failed to find item by barcode', e, stackTrace, 'InventoryService');
      rethrow;
    }
  }
}