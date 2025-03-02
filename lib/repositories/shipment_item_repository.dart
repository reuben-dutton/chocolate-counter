import 'package:food_inventory/models/item_definition.dart';
import 'package:food_inventory/models/shipment_item.dart';
import 'package:food_inventory/repositories/base_repository.dart';
import 'package:food_inventory/repositories/item_definition_repository.dart';
import 'package:food_inventory/services/database_service.dart';

class ShipmentItemRepository extends BaseRepository<ShipmentItem> {
  final ItemDefinitionRepository _itemDefinitionRepository;

  ShipmentItemRepository(
    DatabaseService databaseService,
    this._itemDefinitionRepository,
  ) : super(databaseService, DatabaseService.tableShipmentItems);

  @override
  ShipmentItem fromMap(Map<String, dynamic> map) {
    return ShipmentItem.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(ShipmentItem entity) {
    return entity.toMap();
  }

  @override
  int? getId(ShipmentItem entity) {
    return entity.id;
  }
  
  /// Get all shipment items for a specific shipment with their item definitions
  Future<List<ShipmentItem>> getItemsForShipment(int shipmentId) async {
    final items = await getWhere(
      where: 'shipmentId = ?',
      whereArgs: [shipmentId],
    );
    
    if (items.isEmpty) {
      return [];
    }
    
    // Get all unique item definition IDs
    final itemDefinitionIds = items
        .map((item) => item.itemDefinitionId)
        .toSet()
        .toList();
    
    // Fetch all item definitions in a single operation
    final Map<int, ItemDefinition> itemDefinitions = {};
    for (final id in itemDefinitionIds) {
      final def = await _itemDefinitionRepository.getById(id);
      if (def != null) {
        itemDefinitions[id] = def;
      }
    }
    
    // Attach the item definitions to each shipment item
    return items.map((item) {
      return ShipmentItem(
        id: item.id,
        shipmentId: item.shipmentId,
        itemDefinitionId: item.itemDefinitionId,
        quantity: item.quantity,
        expirationDate: item.expirationDate,
        itemDefinition: itemDefinitions[item.itemDefinitionId],
      );
    }).toList();
  }
  
  /// Update the expiration date for a shipment item
  Future<int> updateExpirationDate(int id, DateTime? expirationDate) async {
    final db = databaseService.database;
    
    return await db.update(
      tableName,
      {'expirationDate': expirationDate?.millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}