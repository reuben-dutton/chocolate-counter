import 'package:food_inventory/data/models/inventory_movement.dart';
import 'package:food_inventory/data/repositories/inventory_movement_repository.dart';
import 'package:sqflite/sqflite.dart';

class InventoryMovementFactory {
  final InventoryMovementRepository _repository;

  InventoryMovementFactory(this._repository);
  
  /// Creates a new inventory movement without persisting it
  InventoryMovement createStockSaleMovement({
    required int itemDefinitionId,
    required int quantity,
    DateTime? timestamp,
  }) {
    return InventoryMovement.createStockSale(
      itemDefinitionId: itemDefinitionId,
      quantity: quantity,
      timestamp: timestamp,
    );
  }
  
  /// Creates a new inventory-to-stock movement without persisting it
  InventoryMovement createInventoryToStockMovement({
    required int itemDefinitionId,
    required int quantity,
    DateTime? timestamp,
  }) {
    return InventoryMovement.createInventoryToStock(
      itemDefinitionId: itemDefinitionId,
      quantity: quantity,
      timestamp: timestamp,
    );
  }
  
  /// Creates a new shipment-to-inventory movement without persisting it
  InventoryMovement createShipmentToInventoryMovement({
    required int itemDefinitionId,
    required int quantity,
    DateTime? timestamp,
  }) {
    return InventoryMovement.createShipmentToInventory(
      itemDefinitionId: itemDefinitionId,
      quantity: quantity,
      timestamp: timestamp,
    );
  }

  /// Persists a movement to the repository
  Future<int> save(InventoryMovement movement, {Transaction? txn}) async {
    return await _repository.create(movement, txn: txn);
  }
}