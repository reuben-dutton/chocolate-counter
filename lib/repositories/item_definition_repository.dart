import 'package:food_inventory/models/item_definition.dart';
import 'package:food_inventory/repositories/base_repository.dart';
import 'package:food_inventory/services/database_service.dart';

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
  Future<List<ItemDefinition>> getAllSorted() async {
    return getAll(orderBy: 'name ASC');
  }
  
  /// Find item definition by barcode
  Future<ItemDefinition?> findByBarcode(String barcode) async {
    final items = await getWhere(
      where: 'barcode = ?',
      whereArgs: [barcode],
    );
    
    return items.isNotEmpty ? items.first : null;
  }
  
  /// Search item definitions by name
  Future<List<ItemDefinition>> searchByName(String query) async {
    return getWhere(
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'name ASC',
    );
  }
}