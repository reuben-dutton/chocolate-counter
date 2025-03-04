import 'package:food_inventory/data/models/item_definition.dart';

class InventoryMovement {
  final int? id;
  final int itemDefinitionId;
  final int quantity;
  final DateTime timestamp;
  final MovementType type;
  
  // Transient property
  final ItemDefinition? itemDefinition;

  InventoryMovement({
    this.id,
    required this.itemDefinitionId,
    required this.quantity,
    required this.timestamp,
    required this.type,
    this.itemDefinition,
  });

  // Factory method for creating a stock sale movement
  static InventoryMovement createStockSale({
    int? id,
    required int itemDefinitionId,
    required int quantity,
    DateTime? timestamp,
    ItemDefinition? itemDefinition,
  }) {
    return InventoryMovement(
      id: id,
      itemDefinitionId: itemDefinitionId,
      quantity: quantity,
      timestamp: timestamp ?? DateTime.now(),
      type: MovementType.stockSale,
      itemDefinition: itemDefinition,
    );
  }

  // Factory method for creating an inventory-to-stock movement
  static InventoryMovement createInventoryToStock({
    int? id,
    required int itemDefinitionId,
    required int quantity,
    DateTime? timestamp,
    ItemDefinition? itemDefinition,
  }) {
    return InventoryMovement(
      id: id,
      itemDefinitionId: itemDefinitionId,
      quantity: quantity,
      timestamp: timestamp ?? DateTime.now(),
      type: MovementType.inventoryToStock,
      itemDefinition: itemDefinition,
    );
  }
  
  // Factory method for creating an inventory-to-stock movement
  static InventoryMovement createShipmentToInventory({
    int? id,
    required int itemDefinitionId,
    required int quantity,
    DateTime? timestamp,
    ItemDefinition? itemDefinition,
  }) {
    return InventoryMovement(
      id: id,
      itemDefinitionId: itemDefinitionId,
      quantity: quantity,
      timestamp: timestamp ?? DateTime.now(),
      type: MovementType.shipmentToInventory,
      itemDefinition: itemDefinition,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemDefinitionId': itemDefinitionId,
      'quantity': quantity,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'type': type.index,
    };
  }

  factory InventoryMovement.fromMap(Map<String, dynamic> map, {ItemDefinition? itemDef}) {
    return InventoryMovement(
      id: map['id'],
      itemDefinitionId: map['itemDefinitionId'],
      quantity: map['quantity'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      type: MovementType.values[map['type']],
      itemDefinition: itemDef,
    );
  }
}

enum MovementType {
  stockSale,           // Decrease in stock (customer purchase)
  inventoryToStock,    // Move from inventory to stock
  shipmentToInventory, // Addition from a new shipment
}