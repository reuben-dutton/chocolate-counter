import 'dart:async';
import 'package:food_inventory/data/models/item_definition.dart';

/// Base class for inventory events
abstract class InventoryEvent {
  const InventoryEvent();
}

/// Event for general inventory data changes
class InventoryDataChanged extends InventoryEvent {
  final int itemDefinitionId;
  
  const InventoryDataChanged({required this.itemDefinitionId});
}

/// Event for item definition creation
class ItemDefinitionCreated extends InventoryEvent {
  final ItemDefinition itemDefinition;
  
  const ItemDefinitionCreated(this.itemDefinition);
}

/// Event for item definition updates
class ItemDefinitionUpdated extends InventoryEvent {
  final ItemDefinition itemDefinition;
  
  const ItemDefinitionUpdated(this.itemDefinition);
}

/// Event for item definition deletion
class ItemDefinitionDeleted extends InventoryEvent {
  final int id;
  
  const ItemDefinitionDeleted(this.id);
}

/// Event bus for inventory-related events
class InventoryEventBus {
  // Singleton pattern
  static final InventoryEventBus _instance = InventoryEventBus._internal();
  factory InventoryEventBus() => _instance;
  InventoryEventBus._internal();

  // Broadcast stream controller
  final _controller = StreamController<InventoryEvent>.broadcast();
  
  /// Stream that components can subscribe to
  Stream<InventoryEvent> get stream => _controller.stream;
  
  /// Emit an event
  void emit(InventoryEvent event) {
    _controller.add(event);
  }
  
  /// Clean up resources
  void dispose() {
    _controller.close();
  }
}