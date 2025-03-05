import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/data/factories/inventory_movement_factory.dart';
import 'package:food_inventory/data/factories/item_instance_factory.dart';
import 'package:food_inventory/data/models/shipment.dart';
import 'package:food_inventory/data/models/shipment_item.dart';
import 'package:food_inventory/data/models/inventory_movement.dart';
import 'package:food_inventory/data/repositories/item_instance_repository.dart';
import 'package:food_inventory/data/repositories/shipment_item_repository.dart';
import 'package:food_inventory/data/repositories/shipment_repository.dart';

/// Service for managing shipments and related operations
class ShipmentService {
  final ShipmentRepository _shipmentRepository;
  final ShipmentItemRepository _shipmentItemRepository;
  final ItemInstanceRepository _itemInstanceRepository;
  final ItemInstanceFactory _itemInstanceFactory;
  final InventoryMovementFactory _movementFactory;

  ShipmentService(
    this._shipmentRepository,
    this._shipmentItemRepository,
    this._itemInstanceRepository,
    this._movementFactory,
  ) : _itemInstanceFactory = ItemInstanceFactory(_itemInstanceRepository, null);

  /// Get all shipments with their items
  Future<List<Shipment>> getAllShipments() async {
    try {
      return _shipmentRepository.getAllWithItems();
    } catch (e, stackTrace) {
      ErrorHandler.logError('Failed to get all shipments', e, stackTrace, 'ShipmentService');
      rethrow;
    }
  }
  
  /// Get a specific shipment with its items
  Future<Shipment?> getShipment(int id) async {
    try {
      return _shipmentRepository.getWithItems(id);
    } catch (e, stackTrace) {
      ErrorHandler.logError('Failed to get shipment', e, stackTrace, 'ShipmentService');
      rethrow;
    }
  }
  
  /// Get all items for a specific shipment
  Future<List<ShipmentItem>> getShipmentItems(int shipmentId) async {
    try {
      return _shipmentItemRepository.getItemsForShipment(shipmentId);
    } catch (e, stackTrace) {
      ErrorHandler.logError('Failed to get shipment items', e, stackTrace, 'ShipmentService');
      rethrow;
    }
  }
  
  /// Create a new shipment and add inventory items
  Future<int> createShipment(Shipment shipment) async {
    try {
      return await _shipmentRepository.databaseService.database.transaction((txn) async {
        // Create the shipment using the transaction
        final shipmentMap = _shipmentRepository.toMap(shipment);
        shipmentMap.remove('id');
        
        final shipmentId = await txn.insert(
          _shipmentRepository.tableName,
          shipmentMap,
        );
        
        // Process each shipment item
        for (final item in shipment.items) {
          // Create a new ShipmentItem with updated shipmentId
          final shipmentItem = ShipmentItem.create(
            shipmentId: shipmentId,
            itemDefinitionId: item.itemDefinitionId,
            quantity: item.quantity,
            expirationDate: item.expirationDate,
            itemDefinition: item.itemDefinition
          );
          
          final itemMap = _shipmentItemRepository.toMap(shipmentItem);
          itemMap.remove('id');
          
          // Insert into shipment_items table
          final shipmentItemId = await txn.insert(
            _shipmentItemRepository.tableName,
            itemMap,
          );
          
          // Create inventory item with reference to shipment item
          await _itemInstanceFactory.addToInventory(
            itemDefinitionId: item.itemDefinitionId,
            quantity: item.quantity,
            expirationDate: item.expirationDate,
            shipmentItemId: shipmentItemId,
            txn: txn
          );

          // Record inventory movement for this item
          InventoryMovement newMovement = _movementFactory.createShipmentToInventoryMovement(
            itemDefinitionId: item.itemDefinitionId,
            quantity: item.quantity,
            timestamp: shipment.date,
          );

          await _movementFactory.save(newMovement, txn: txn);
        }
        
        return shipmentId;
      });
    } catch (e, stackTrace) {
      ErrorHandler.logError('Failed to create shipment', e, stackTrace, 'ShipmentService');
      rethrow;
    }
  }
  
  /// Delete a shipment (inventory items are not affected)
  Future<int> deleteShipment(int id) async {
    try {
      return _shipmentRepository.delete(id);
    } catch (e, stackTrace) {
      ErrorHandler.logError('Failed to delete shipment', e, stackTrace, 'ShipmentService');
      rethrow;
    }
  }
  
  /// Update the expiration date of a shipment item and linked inventory items
  Future<void> updateShipmentItemExpiration(int shipmentItemId, DateTime? expirationDate) async {
    try {
      await _shipmentItemRepository.databaseService.database.transaction((txn) async {
        // First check if the shipment item exists within the transaction
        final shipmentItem = await _shipmentItemRepository.getById(shipmentItemId, txn: txn);
        if (shipmentItem == null) {
          throw Exception('Shipment item not found');
        }
        
        // Update the shipment item
        await _shipmentItemRepository.updateExpirationDate(shipmentItemId, expirationDate, txn: txn);
        
        // Update linked inventory items
        await _itemInstanceRepository.updateExpirationDatesByShipmentItemId(
          shipmentItemId, 
          expirationDate,
          txn: txn
        );
      });
    } catch (e, stackTrace) {
      ErrorHandler.logError('Failed to update shipment item expiration', e, stackTrace, 'ShipmentService');
      rethrow;
    }
  }
  
  /// Get a specific shipment item by ID
  Future<ShipmentItem?> getShipmentItem(int id) async {
    try {
      return _shipmentItemRepository.getById(id);
    } catch (e, stackTrace) {
      ErrorHandler.logError('Failed to get shipment item', e, stackTrace, 'ShipmentService');
      rethrow;
    }
  }
}