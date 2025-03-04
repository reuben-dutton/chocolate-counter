import 'package:food_inventory/data/models/inventory_movement.dart';
import 'package:food_inventory/data/repositories/inventory_movement_repository.dart';
import 'package:sqflite/sqflite.dart';

class InventoryMovementFactory {
  final InventoryMovementRepository _repository;

  InventoryMovementFactory(this._repository);

  Future<int> recordStockSale({
    required int itemDefinitionId,
    required int quantity,
    DateTime? timestamp,
    Transaction? txn,
  }) async {
    final movement = InventoryMovement.createStockSale(
      itemDefinitionId: itemDefinitionId,
      quantity: quantity,
      timestamp: timestamp,
    );
    
    return await _repository.create(movement, txn: txn);
  }

  Future<int> recordInventoryToStock({
    required int itemDefinitionId,
    required int quantity,
    DateTime? timestamp,
    Transaction? txn,
  }) async {
    final movement = InventoryMovement.createInventoryToStock(
      itemDefinitionId: itemDefinitionId,
      quantity: quantity,
      timestamp: timestamp,
    );
    
    return await _repository.create(movement, txn: txn);
  }

  Future<int> recordShipmentToInventory({
    required int itemDefinitionId,
    required int quantity,
    DateTime? timestamp,
    Transaction? txn,
  }) async {
    final movement = InventoryMovement.createShipmentToInventory(
      itemDefinitionId: itemDefinitionId,
      quantity: quantity,
      timestamp: timestamp,
    );

    return await _repository.create(movement, txn: txn);
  }
}