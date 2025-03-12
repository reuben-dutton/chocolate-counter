import 'package:food_inventory/data/models/item_instance.dart';
import 'package:food_inventory/data/repositories/base_repository.dart';
import 'package:food_inventory/data/repositories/item_definition_repository.dart';
import 'package:food_inventory/common/services/database_service.dart';
import 'package:sqflite/sqflite.dart';

class ItemInstanceRepository extends BaseRepository<ItemInstance> {
  final ItemDefinitionRepository _itemDefinitionRepository;

  ItemInstanceRepository(
    DatabaseService databaseService,
    this._itemDefinitionRepository,
  ) : super(databaseService, DatabaseService.tableItemInstances);

  @override
  ItemInstance fromMap(Map<String, dynamic> map) {
    return ItemInstance.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(ItemInstance entity) {
    return entity.toMap();
  }

  @override
  int? getId(ItemInstance entity) {
    return entity.id;
  }

  /// Get all instances for a specific item definition with their item details
  Future<List<ItemInstance>> getInstancesForItem(int itemDefinitionId, {Transaction? txn}) async {
    // Get instances with the transaction-aware method from base repository
    final instances = await getWhere(
      where: 'itemDefinitionId = ?',
      whereArgs: [itemDefinitionId],
      orderBy: 'expirationDate ASC',
      txn: txn,
    );
    
    if (instances.isEmpty) {
      return [];
    }
    
    return _withTransactionIfNeeded(txn, (transaction) async {
      final itemDefinition = await _itemDefinitionRepository.getById(itemDefinitionId, txn: transaction);
      
      // Attach the item definition to each instance
      return instances.map((instance) {
        return ItemInstance(
          id: instance.id,
          itemDefinitionId: instance.itemDefinitionId,
          quantity: instance.quantity,
          expirationDate: instance.expirationDate,
          isInStock: instance.isInStock,
          shipmentItemId: instance.shipmentItemId,
          itemDefinition: itemDefinition,
        );
      }).toList();
    });
  }
  
  /// Get summary counts for stock and inventory items
  Future<Map<String, int>> getItemCounts(int itemDefinitionId, {Transaction? txn}) async {
    return _withTransactionIfNeeded(txn, (db) async {
      try {
        // Get stock count - items with isInStock = 1
        final stockResult = await db.rawQuery('''
          SELECT COALESCE(SUM(quantity), 0) as count
          FROM ${DatabaseService.tableItemInstances}
          WHERE itemDefinitionId = ? AND isInStock = 1
        ''', [itemDefinitionId]);
        
        // Get inventory count - items with isInStock = 0
        final inventoryResult = await db.rawQuery('''
          SELECT COALESCE(SUM(quantity), 0) as count
          FROM ${DatabaseService.tableItemInstances}
          WHERE itemDefinitionId = ? AND isInStock = 0
        ''', [itemDefinitionId]);
        
        return {
          'stock': stockResult.first['count'] as int,
          'inventory': inventoryResult.first['count'] as int,
        };
      } catch (e) {
        print('Error getting item counts: $e');
        return {'stock': 0, 'inventory': 0};
      }
    });
  }
  
  /// Get instances for an item sorted by expiration date (for stock operations)
  Future<List<ItemInstance>> getStockInstances(int itemDefinitionId, {Transaction? txn}) async {
    return getWhere(
      where: 'itemDefinitionId = ? AND isInStock = 1',
      whereArgs: [itemDefinitionId],
      orderBy: 'CASE WHEN expirationDate IS NULL THEN 1 ELSE 0 END, expirationDate ASC',
      txn: txn,
    );
  }
  
  /// Get instances for an item sorted by expiration date (for inventory operations)
  Future<List<ItemInstance>> getInventoryInstances(int itemDefinitionId, {Transaction? txn}) async {
    return getWhere(
      where: 'itemDefinitionId = ? AND isInStock = 0',
      whereArgs: [itemDefinitionId],
      orderBy: 'CASE WHEN expirationDate IS NULL THEN 1 ELSE 0 END, expirationDate ASC',
      txn: txn,
    );
  }
  
  /// Update expiration dates for items linked to a shipment item
  Future<int> updateExpirationDatesByShipmentItemId(int shipmentItemId, DateTime? expirationDate, {Transaction? txn}) async {
    return _withTransactionIfNeeded(txn, (db) async {
      return await db.update(
        tableName,
        {'expirationDate': expirationDate?.millisecondsSinceEpoch},
        where: 'shipmentItemId = ?',
        whereArgs: [shipmentItemId],
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