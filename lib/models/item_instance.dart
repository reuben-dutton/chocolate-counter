import 'package:food_inventory/models/item_definition.dart';

class ItemInstance {
  final int? id;
  final int itemDefinitionId;
  final int quantity;
  final DateTime? expirationDate;
  final bool isInStock; // true = stock, false = inventory
  final int? shipmentItemId; // Reference to originating shipment item

  // Transient property (not stored in DB directly)
  final ItemDefinition? itemDefinition;

  ItemInstance({
    this.id,
    required this.itemDefinitionId,
    required this.quantity,
    this.expirationDate,
    required this.isInStock,
    this.shipmentItemId,
    this.itemDefinition,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemDefinitionId': itemDefinitionId,
      'quantity': quantity,
      'expirationDate': expirationDate?.millisecondsSinceEpoch,
      'isInStock': isInStock ? 1 : 0,
      'shipmentItemId': shipmentItemId,
    };
  }

  factory ItemInstance.fromMap(Map<String, dynamic> map, {ItemDefinition? itemDef}) {
    return ItemInstance(
      id: map['id'],
      itemDefinitionId: map['itemDefinitionId'],
      quantity: map['quantity'],
      expirationDate: map['expirationDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['expirationDate']) 
          : null,
      isInStock: map['isInStock'] == 1,
      shipmentItemId: map['shipmentItemId'],
      itemDefinition: itemDef,
    );
  }

  ItemInstance copyWith({
    int? id,
    int? itemDefinitionId,
    int? quantity,
    DateTime? expirationDate,
    bool? isInStock,
    int? shipmentItemId,
    ItemDefinition? itemDefinition,
  }) {
    return ItemInstance(
      id: id ?? this.id,
      itemDefinitionId: itemDefinitionId ?? this.itemDefinitionId,
      quantity: quantity ?? this.quantity,
      expirationDate: expirationDate ?? this.expirationDate,
      isInStock: isInStock ?? this.isInStock,
      shipmentItemId: shipmentItemId ?? this.shipmentItemId,
      itemDefinition: itemDefinition ?? this.itemDefinition,
    );
  }
}