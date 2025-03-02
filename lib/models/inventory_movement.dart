import 'package:food_inventory/models/item_definition.dart';

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
}