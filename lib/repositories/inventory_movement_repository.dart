import 'package:food_inventory/models/inventory_movement.dart';
import 'package:food_inventory/repositories/base_repository.dart';
import 'package:food_inventory/repositories/item_definition_repository.dart';
import 'package:food_inventory/services/database_service.dart';
import 'package:sqflite/sqflite.dart';

class InventoryMovementRepository extends BaseRepository<InventoryMovement> {
  final ItemDefinitionRepository _itemDefinitionRepository;

  InventoryMovementRepository(
    DatabaseService databaseService,
    this._itemDefinitionRepository,
  ) : super(databaseService, DatabaseService.tableInventoryMovements);

  @override
  InventoryMovement fromMap(Map<String, dynamic> map) {
    return InventoryMovement.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(InventoryMovement entity) {
    return entity.toMap();
  }

  @override
  int? getId(InventoryMovement entity) {
    return entity.id;
  }
  
  /// Record a stock sale movement with transaction support
  Future<int> recordStockSale(int itemDefinitionId, int quantity, DateTime timestamp, {Transaction? txn}) async {
    final movement = InventoryMovement.createStockSale(
      itemDefinitionId: itemDefinitionId,
      quantity: quantity,
      timestamp: timestamp,
    );
    
    return create(movement, txn: txn);
  }
  
  /// Record an inventory to stock movement with transaction support
  Future<int> recordInventoryToStock(int itemDefinitionId, int quantity, DateTime timestamp, {Transaction? txn}) async {
    final movement = InventoryMovement.createInventoryToStock(
      itemDefinitionId: itemDefinitionId,
      quantity: quantity,
      timestamp: timestamp,
    );
    
    return create(movement, txn: txn);
  }

  Future<int> recordShipmentToInventory(int itemDefinitionId, int quantity, DateTime timestamp, {Transaction? txn}) async {
    final movement = InventoryMovement.createShipmentToInventory(
      itemDefinitionId: itemDefinitionId,
      quantity: quantity,
      timestamp: timestamp,
    );

    return create(movement, txn: txn);
  }
  
  /// Get all movements for a specific item with item definitions
  Future<List<InventoryMovement>> getMovementsForItem(int itemDefinitionId, {Transaction? txn}) async {
    final movements = await getWhere(
      where: 'itemDefinitionId = ?',
      whereArgs: [itemDefinitionId],
      orderBy: 'timestamp DESC',
      txn: txn,
    );
    
    if (movements.isEmpty) {
      return [];
    }
    
    // Important: Pass the transaction to getById if it's provided
    final itemDefinition = await _itemDefinitionRepository.getById(itemDefinitionId, txn: txn);
    
    // Attach the item definition to each movement
    return movements.map((movement) {
      return InventoryMovement(
        id: movement.id,
        itemDefinitionId: movement.itemDefinitionId,
        quantity: movement.quantity,
        timestamp: movement.timestamp,
        type: movement.type,
        itemDefinition: itemDefinition,
      );
    }).toList();
  }
  
  /// Clear movement history for an item
  Future<int> clearMovementsForItem(int itemDefinitionId, {Transaction? txn}) async {
    final db = txn ?? databaseService.database;
    
    return await db.delete(
      tableName,
      where: 'itemDefinitionId = ?',
      whereArgs: [itemDefinitionId],
    );
  }
}