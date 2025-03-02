import 'package:food_inventory/models/item_instance.dart';
import 'package:food_inventory/models/shipment.dart';
import 'package:food_inventory/models/shipment_item.dart';
import 'package:food_inventory/repositories/item_instance_repository.dart';
import 'package:food_inventory/repositories/shipment_item_repository.dart';
import 'package:food_inventory/repositories/shipment_repository.dart';
import 'package:food_inventory/services/inventory_service.dart';

/// Service for managing shipments and related operations
class ShipmentService {
  final ShipmentRepository _shipmentRepository;
  final ShipmentItemRepository _shipmentItemRepository;
  final ItemInstanceRepository _itemInstanceRepository;
  final InventoryService _inventoryService;

  ShipmentService(
    this._shipmentRepository,
    this._shipmentItemRepository,
    this._itemInstanceRepository,
    this._inventoryService,
  );

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
    final db = _shipmentRepository.databaseService.database;
    
    return await db.transaction((txn) async {
      // Create the shipment
      final shipmentMap = _shipmentRepository.toMap(shipment);
      shipmentMap.remove('id');
      
      final shipmentId = await txn.insert(
        _shipmentRepository.tableName,
        shipmentMap,
      );
      
      // Process each shipment item
      for (final item in shipment.items) {
        // Create a new ShipmentItem with updated shipmentId
        final itemMap = _shipmentItemRepository.toMap(item);
        itemMap.remove('id');
        itemMap['shipmentId'] = shipmentId;
        
        // Insert into shipment_items table
        final shipmentItemId = await txn.insert(
          _shipmentItemRepository.tableName,
          itemMap,
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
          _itemInstanceRepository.tableName,
          _itemInstanceRepository.toMap(itemInstance)..remove('id'),
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
    final db = _shipmentRepository.databaseService.database;
    
    await db.transaction((txn) async {
      // Update the shipment item
      await _shipmentItemRepository.updateExpirationDate(shipmentItemId, expirationDate);
      
      // Update linked inventory items
      await _itemInstanceRepository.updateExpirationForShipmentItem(shipmentItemId, expirationDate);
    });
  }
  
  /// Get a specific shipment item by ID
  Future<ShipmentItem?> getShipmentItem(int id) async {
    return _shipmentItemRepository.getById(id);
  }
}