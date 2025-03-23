import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/data/factories/inventory_movement_factory.dart';
import 'package:food_inventory/data/factories/item_instance_factory.dart';
import 'package:food_inventory/data/models/shipment.dart';
import 'package:food_inventory/data/models/shipment_item.dart';
import 'package:food_inventory/data/models/inventory_movement.dart';
import 'package:food_inventory/data/repositories/item_instance_repository.dart';
import 'package:food_inventory/data/repositories/shipment_item_repository.dart';
import 'package:food_inventory/data/repositories/shipment_repository.dart';
import 'package:sqflite/sqflite.dart';

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

  /// Run a function within a transaction
  Future<R> withTransaction<R>(Future<R> Function(Transaction txn) action) async {
    return _shipmentRepository.withTransaction(action);
  }

  /// Get all shipments with their items
  Future<List<Shipment>> getAllShipments({Transaction? txn}) async {
    try {
      return _shipmentRepository.getAllWithItems(txn: txn);
    } catch (e, stackTrace) {
      ErrorHandler.logError('Failed to get all shipments', e, stackTrace, 'ShipmentService');
      rethrow;
    }
  }
  
  /// Get a specific shipment with its items
  Future<Shipment?> getShipment(int id, {Transaction? txn}) async {
    try {
      return _shipmentRepository.getWithItems(id, txn: txn);
    } catch (e, stackTrace) {
      ErrorHandler.logError('Failed to get shipment', e, stackTrace, 'ShipmentService');
      rethrow;
    }
  }
  
  /// Get all items for a specific shipment
  Future<List<ShipmentItem>> getShipmentItems(int shipmentId, {Transaction? txn}) async {
    try {
      return _shipmentItemRepository.getItemsForShipment(shipmentId, txn: txn);
    } catch (e, stackTrace) {
      ErrorHandler.logError('Failed to get shipment items', e, stackTrace, 'ShipmentService');
      rethrow;
    }
  }
  
  /// Create a new shipment and add inventory items
  Future<int> createShipment(Shipment shipment, {Transaction? txn}) async {
    try {
      return withTransaction((transaction) async {
        return await _createShipmentInternal(shipment, transaction);
      });
    } catch (e, stackTrace) {
      ErrorHandler.logError('Failed to create shipment', e, stackTrace, 'ShipmentService');
      rethrow;
    }
  }
  
  // Helper method to perform shipment creation within a transaction
  Future<int> _createShipmentInternal(Shipment shipment, Transaction txn) async {
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
        unitPrice: item.unitPrice,
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
  }
  
  /// Delete a shipment (inventory items are not affected)
  Future<int> deleteShipment(int id, {Transaction? txn}) async {
    try {
      return _shipmentRepository.delete(id, txn: txn);
    } catch (e, stackTrace) {
      ErrorHandler.logError('Failed to delete shipment', e, stackTrace, 'ShipmentService');
      rethrow;
    }
  }
  
  /// Update the expiration date of a shipment item and linked inventory items
  Future<void> updateShipmentItemExpiration(int shipmentItemId, DateTime? expirationDate, {Transaction? txn}) async {
    try {
      return withTransaction((transaction) async {
        await _updateExpiration(shipmentItemId, expirationDate, transaction);
      });
    } catch (e, stackTrace) {
      ErrorHandler.logError('Failed to update shipment item expiration', e, stackTrace, 'ShipmentService');
      rethrow;
    }
  }
  
  // Helper method to perform the actual update operations within a transaction
  Future<void> _updateExpiration(int shipmentItemId, DateTime? expirationDate, Transaction txn) async {
    // First check if the shipment item exists
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
  }
  
  /// Get a specific shipment item by ID
  Future<ShipmentItem?> getShipmentItem(int id, {Transaction? txn}) async {
    try {
      return _shipmentItemRepository.getById(id, txn: txn);
    } catch (e, stackTrace) {
      ErrorHandler.logError('Failed to get shipment item', e, stackTrace, 'ShipmentService');
      rethrow;
    }
  }
}