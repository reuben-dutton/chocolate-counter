import 'package:food_inventory/data/models/item_definition.dart';
import 'package:food_inventory/data/repositories/base_repository.dart';
import 'package:food_inventory/common/services/database_service.dart';
import 'package:sqflite/sqflite.dart';

class ItemDefinitionRepository extends BaseRepository<ItemDefinition> {
  ItemDefinitionRepository(DatabaseService databaseService)
      : super(databaseService, DatabaseService.tableItemDefinitions);

  @override
  ItemDefinition fromMap(Map<String, dynamic> map) {
    return ItemDefinition.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(ItemDefinition entity) {
    return entity.toMap();
  }

  @override
  int? getId(ItemDefinition entity) {
    return entity.id;
  }
  
  /// Get all item definitions sorted by name
  Future<List<ItemDefinition>> getAllSorted({Transaction? txn}) async {
    return getAll(orderBy: 'name ASC', txn: txn);
  }
  
  /// Get item definition by ID with transaction support
  @override
  Future<ItemDefinition?> getById(int id, {Transaction? txn}) async {
    final db = txn ?? databaseService.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isEmpty) {
      return null;
    }
    
    return fromMap(maps.first);
  }
  
  /// Find item definition by barcode
  Future<ItemDefinition?> findByBarcode(String barcode, {Transaction? txn}) async {
    final items = await getWhere(
      where: 'barcode = ?',
      whereArgs: [barcode],
      txn: txn,
    );
    
    return items.isNotEmpty ? items.first : null;
  }
  
  /// Search item definitions by name
  Future<List<ItemDefinition>> searchByName(String query, {Transaction? txn}) async {
    return getWhere(
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'name ASC',
      txn: txn,
    );
  }
}