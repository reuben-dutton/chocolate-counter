import 'package:food_inventory/factories/item_instance_factory.dart';
import 'package:food_inventory/models/item_instance.dart';
import 'package:food_inventory/models/shipment.dart';
import 'package:food_inventory/models/shipment_item.dart';
import 'package:food_inventory/repositories/item_instance_repository.dart';
import 'package:food_inventory/repositories/shipment_item_repository.dart';
import 'package:food_inventory/repositories/shipment_repository.dart';
import 'package:food_inventory/services/inventory_service.dart';
import 'package:sqflite/sqflite.dart';

/// Service for managing shipments and related operations
class ShipmentService {
  final ShipmentRepository _shipmentRepository;
  final ShipmentItemRepository _shipmentItemRepository;
  final ItemInstanceRepository _itemInstanceRepository;
  final InventoryService _inventoryService;
  final ItemInstanceFactory _itemInstanceFactory;

  ShipmentService(
    this._shipmentRepository,
    this._shipmentItemRepository,
    this._itemInstanceRepository,
    this._inventoryService,
  ) : _itemInstanceFactory = ItemInstanceFactory(_itemInstanceRepository, null);

  /// Get all shipments with their items
  Future<List<Shipment>> getAllShipments() async {
    return _shipmentRepository.getAllWithItems();
  }
  
  /// Get a specific shipment with its items
  Future<Shipment?> getShipment(int id) async {
    return _shipmentRepository.getWithItems(id);
  }
  
  /// Get all items for a specific shipment
  Future<List<ShipmentItem>> getShipmentItems(int shipmentId) async {
    return _shipmentItemRepository.getItemsForShipment(shipmentId);
  }
  
  /// Create a new shipment and add inventory items
  Future<int> createShipment(Shipment shipment) async {
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
      }
      
      return shipmentId;
    });
  }
  
  /// Delete a shipment (inventory items are not affected)
  Future<int> deleteShipment(int id) async {
    return _shipmentRepository.delete(id);
  }
  
  /// Update the expiration date of a shipment item and linked inventory items
  Future<void> updateShipmentItemExpiration(int shipmentItemId, DateTime? expirationDate) async {
    await _shipmentItemRepository.databaseService.database.transaction((txn) async {
      // Update the shipment item
      await _shipmentItemRepository.updateExpirationDate(shipmentItemId, expirationDate, txn: txn);
      
      // Update linked inventory items
      await _itemInstanceRepository.updateExpirationForShipmentItem(
        shipmentItemId, 
        expirationDate,
        txn: txn
      );
    });
  }
  
  /// Get a specific shipment item by ID
  Future<ShipmentItem?> getShipmentItem(int id) async {
    return _shipmentItemRepository.getById(id);
  }
}