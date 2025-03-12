import 'package:food_inventory/data/models/inventory_movement.dart';
import 'package:food_inventory/data/repositories/base_repository.dart';
import 'package:food_inventory/data/repositories/item_definition_repository.dart';
import 'package:food_inventory/common/services/database_service.dart';
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
  
/// Get all movements for a specific item with item definitions
  Future<List<InventoryMovement>> getMovementsForItem(int itemDefinitionId, {Transaction? txn}) async {
    // Get movements using the transaction-aware method from base repository
    final movements = await getWhere(
      where: 'itemDefinitionId = ?',
      whereArgs: [itemDefinitionId],
      orderBy: 'timestamp DESC',
      txn: txn,
    );
    
    if (movements.isEmpty) {
      return [];
    }
    
    return _withTransactionIfNeeded(txn, (transaction) async {
      // Get item definition using the same transaction
      final itemDefinition = await _itemDefinitionRepository.getById(itemDefinitionId, txn: transaction);
      
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
    });
  }
  
  /// Clear movement history for an item
  Future<int> clearMovementsForItem(int itemDefinitionId, {Transaction? txn}) async {
    return _withTransactionIfNeeded(txn, (db) async {
      return await db.delete(
        tableName,
        where: 'itemDefinitionId = ?',
        whereArgs: [itemDefinitionId],
      );
    });
  }

  // Helper method for transaction management
  Future<T> _withTransactionIfNeeded<T>(
    Transaction? txn,
    Future<T> Function(Transaction) operation
  ) async {
    if (txn != null) {
      return await operation(txn);
    } else {
      return await withTransaction(operation);
    }
  }
}