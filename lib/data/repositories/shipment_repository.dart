import 'package:food_inventory/data/models/shipment.dart';
import 'package:food_inventory/data/repositories/base_repository.dart';
import 'package:food_inventory/data/repositories/shipment_item_repository.dart';
import 'package:food_inventory/common/services/database_service.dart';
import 'package:sqflite/sqflite.dart';

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
  Future<List<Shipment>> getAllWithItems({Transaction? txn}) async {
    return withTransactionIfNeeded(txn, (transaction) async {
      final shipments = await getAll(orderBy: 'date DESC', txn: transaction);
      
      return Future.wait(
        shipments.map((shipment) async {
          final items = await _shipmentItemRepository.getItemsForShipment(shipment.id!, txn: transaction);
          return Shipment(
            id: shipment.id,
            name: shipment.name,
            date: shipment.date,
            items: items,
          );
        }).toList(),
      );
    });
  }
  
  /// Get a shipment with its items
  Future<Shipment?> getWithItems(int id, {Transaction? txn}) async {
    return withTransactionIfNeeded(txn, (transaction) async {
      final shipment = await getById(id, txn: transaction);
      
      if (shipment == null) {
        return null;
      }
      
      final items = await _shipmentItemRepository.getItemsForShipment(id, txn: transaction);
      
      return Shipment(
        id: shipment.id,
        name: shipment.name,
        date: shipment.date,
        items: items,
      );
    });
  }
}