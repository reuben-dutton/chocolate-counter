import 'package:food_inventory/models/shipment_item.dart';

class Shipment {
  final int? id;
  final String? name;
  final DateTime date;
  final List<ShipmentItem> items;

  Shipment({
    this.id,
    this.name,
    required this.date,
    required this.items,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'date': date.millisecondsSinceEpoch,
    };
  }

  factory Shipment.fromMap(Map<String, dynamic> map, {List<ShipmentItem> shipmentItems = const []}) {
    return Shipment(
      id: map['id'],
      name: map['name'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      items: shipmentItems,
    );
  }
}