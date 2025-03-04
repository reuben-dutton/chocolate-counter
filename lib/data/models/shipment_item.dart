import 'package:food_inventory/data/models/item_definition.dart';

class ShipmentItem {
  final int? id;
  final int shipmentId;
  final int itemDefinitionId;
  final int quantity;
  final DateTime? expirationDate;
  
  // Transient property
  final ItemDefinition? itemDefinition;

  ShipmentItem({
    this.id,
    required this.shipmentId,
    required this.itemDefinitionId,
    required this.quantity,
    this.expirationDate,
    this.itemDefinition,
  });

  // Factory method for creating a shipment item
  static ShipmentItem create({
    int? id,
    required int shipmentId,
    required int itemDefinitionId,
    required int quantity,
    DateTime? expirationDate,
    ItemDefinition? itemDefinition,
  }) {
    return ShipmentItem(
      id: id,
      shipmentId: shipmentId,
      itemDefinitionId: itemDefinitionId,
      quantity: quantity,
      expirationDate: expirationDate,
      itemDefinition: itemDefinition,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shipmentId': shipmentId,
      'itemDefinitionId': itemDefinitionId,
      'quantity': quantity,
      'expirationDate': expirationDate?.millisecondsSinceEpoch,
    };
  }

  factory ShipmentItem.fromMap(Map<String, dynamic> map, {ItemDefinition? itemDef}) {
    return ShipmentItem(
      id: map['id'],
      shipmentId: map['shipmentId'],
      itemDefinitionId: map['itemDefinitionId'],
      quantity: map['quantity'],
      expirationDate: map['expirationDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['expirationDate']) 
          : null,
      itemDefinition: itemDef,
    );
  }
  
  // Add copyWith method
  ShipmentItem copyWith({
    int? id,
    int? shipmentId,
    int? itemDefinitionId,
    int? quantity,
    DateTime? expirationDate,
    ItemDefinition? itemDefinition,
  }) {
    return ShipmentItem(
      id: id ?? this.id,
      shipmentId: shipmentId ?? this.shipmentId,
      itemDefinitionId: itemDefinitionId ?? this.itemDefinitionId,
      quantity: quantity ?? this.quantity,
      expirationDate: expirationDate ?? this.expirationDate,
      itemDefinition: itemDefinition ?? this.itemDefinition,
    );
  }
}