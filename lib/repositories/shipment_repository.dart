import 'package:food_inventory/models/shipment.dart';
import 'package:food_inventory/repositories/base_repository.dart';
import 'package:food_inventory/repositories/shipment_item_repository.dart';
import 'package:food_inventory/services/database_service.dart';

class ShipmentRepository extends BaseRepository<Shipment> {
  final ShipmentItemRepository _shipmentItemRepository;

  ShipmentRepository(
    DatabaseService databaseService,
    this._shipmentItemRepository,
  ) : super(databaseService, DatabaseService.tableShipments);

  @override
  Shipment fromMap(Map<String, dynamic> map) {
    return Shipment.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(Shipment entity) {
    return entity.toMap();
  }

  @override
  int? getId(Shipment entity) {
    return entity.id;
  }
  
  /// Get all shipments with their items
  Future<List<Shipment>> getAllWithItems() async {
    final shipments = await getAll(orderBy: 'date DESC');
    
    return Future.wait(
      shipments.map((shipment) async {
        final items = await _shipmentItemRepository.getItemsForShipment(shipment.id!);
        return Shipment(
          id: shipment.id,
          name: shipment.name,
          date: shipment.date,
          items: items,
        );
      }).toList(),
    );
  }
  
  /// Get a shipment with its items
  Future<Shipment?> getWithItems(int id) async {
    final shipment = await getById(id);
    
    if (shipment == null) {
      return null;
    }
    
    final items = await _shipmentItemRepository.getItemsForShipment(id);
    
    return Shipment(
      id: shipment.id,
      name: shipment.name,
      date: shipment.date,
      items: items,
    );
  }
  
  /// Create a shipment with its items
  Future<int> createWithItems(Shipment shipment) async {
    final db = databaseService.database;
    
    return await db.transaction((txn) async {
      // Create shipment
      final shipmentMap = toMap(shipment);
      shipmentMap.remove('id');
      
      final shipmentId = await txn.insert(tableName, shipmentMap);
      
      // Create shipment items
      for (final item in shipment.items) {
        final itemMap = _shipmentItemRepository.toMap(item);
        itemMap.remove('id');
        itemMap['shipmentId'] = shipmentId;
        
        await txn.insert(
          DatabaseService.tableShipmentItems,
          itemMap,
        );
      }
      
      return shipmentId;
    });
  }
}