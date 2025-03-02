import 'package:food_inventory/models/inventory_movement.dart';
import 'package:food_inventory/models/item_definition.dart';
import 'package:food_inventory/repositories/base_repository.dart';
import 'package:food_inventory/repositories/item_definition_repository.dart';
import 'package:food_inventory/services/database_service.dart';

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
  Future<List<InventoryMovement>> getMovementsForItem(int itemDefinitionId) async {
    final movements = await getWhere(
      where: 'itemDefinitionId = ?',
      whereArgs: [itemDefinitionId],
      orderBy: 'timestamp DESC',
    );
    
    if (movements.isEmpty) {
      return [];
    }
    
    // Get the item definition
    final itemDefinition = await _itemDefinitionRepository.getById(itemDefinitionId);
    
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
  
  /// Record a stock sale movement
  Future<int> recordStockSale(int itemDefinitionId, int quantity, DateTime timestamp) async {
    final movement = InventoryMovement(
      itemDefinitionId: itemDefinitionId,
      quantity: quantity,
      timestamp: timestamp,
      type: MovementType.stockSale,
    );
    
    return create(movement);
  }
  
  /// Record an inventory to stock movement
  Future<int> recordInventoryToStock(int itemDefinitionId, int quantity, DateTime timestamp) async {
    final movement = InventoryMovement(
      itemDefinitionId: itemDefinitionId,
      quantity: quantity,
      timestamp: timestamp,
      type: MovementType.inventoryToStock,
    );
    
    return create(movement);
  }
  
  /// Clear movement history for an item
  Future<int> clearMovementsForItem(int itemDefinitionId) async {
    return databaseService.database.delete(
      tableName,
      where: 'itemDefinitionId = ?',
      whereArgs: [itemDefinitionId],
    );
  }
}