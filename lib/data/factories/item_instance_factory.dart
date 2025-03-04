import 'package:food_inventory/data/models/item_instance.dart';
import 'package:food_inventory/data/models/shipment_item.dart';
import 'package:food_inventory/data/repositories/item_definition_repository.dart';
import 'package:food_inventory/data/repositories/item_instance_repository.dart';
import 'package:sqflite/sqflite.dart';

class ItemInstanceFactory {
  final ItemInstanceRepository _repository;
  final ItemDefinitionRepository? _itemDefinitionRepository;

  ItemInstanceFactory(this._repository, this._itemDefinitionRepository);

  Future<ItemInstance?> createWithItemDefinition(ItemInstance instance) async {
    if (_itemDefinitionRepository == null) return instance;
    
    final itemDef = await _itemDefinitionRepository!.getById(instance.itemDefinitionId);
    return instance.copyWith(itemDefinition: itemDef);
  }

  Future<int> addToInventory({
    required int itemDefinitionId,
    required int quantity,
    DateTime? expirationDate,
    int? shipmentItemId,
    Transaction? txn,
  }) async {
    final instance = ItemInstance.createInventoryItem(
      itemDefinitionId: itemDefinitionId,
      quantity: quantity,
      expirationDate: expirationDate,
      shipmentItemId: shipmentItemId,
    );
    
    return await _repository.create(instance, txn: txn);
  }

  Future<int> addToStock({
    required int itemDefinitionId,
    required int quantity,
    DateTime? expirationDate,
    int? shipmentItemId,
    Transaction? txn,
  }) async {
    final instance = ItemInstance.createStockItem(
      itemDefinitionId: itemDefinitionId,
      quantity: quantity,
      expirationDate: expirationDate,
      shipmentItemId: shipmentItemId,
    );
    
    return await _repository.create(instance, txn: txn);
  }

  Future<int> createFromShipmentItem(ShipmentItem shipmentItem, {bool isInStock = false, Transaction? txn}) async {
    final instance = ItemInstance.fromShipmentItem(shipmentItem, isInStock: isInStock);
    return await _repository.create(instance, txn: txn);
  }
}