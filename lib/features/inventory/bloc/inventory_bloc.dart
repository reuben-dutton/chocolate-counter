import 'dart:async';

import 'package:food_inventory/common/bloc/bloc_base.dart';
import 'package:food_inventory/data/models/inventory_movement.dart';
import 'package:food_inventory/data/models/item_definition.dart';
import 'package:food_inventory/data/models/item_instance.dart';
import 'package:food_inventory/features/inventory/services/inventory_service.dart';

/// Data class for inventory item with counts
class InventoryItemWithCounts {
  final ItemDefinition itemDefinition;
  final int stockCount;
  final int inventoryCount;
  final bool isEmptyItem;

  InventoryItemWithCounts({
    required this.itemDefinition,
    required this.stockCount,
    required this.inventoryCount,
  }) : isEmptyItem = stockCount == 0 && inventoryCount == 0;
}

/// Data class for item detail
class ItemDetailData {
  final Map<String, int> counts;
  final List<ItemInstance> instances;
  final List<InventoryMovement> movements;

  ItemDetailData({
    required this.counts,
    required this.instances,
    required this.movements,
  });
}

/// BLoC for inventory management
class InventoryBloc extends BlocBase {
  final InventoryService _inventoryService;
  bool _isLoading = false;

  // Stream for all inventory items with counts
  final _inventoryItemsController = StreamController<List<InventoryItemWithCounts>>.broadcast();
  Stream<List<InventoryItemWithCounts>> get inventoryItems => _inventoryItemsController.stream;

  // Stream for loading state
  final _loadingController = StreamController<bool>.broadcast();
  Stream<bool> get isLoading => _loadingController.stream;

  // Stream for item detail data
  final _itemDetailController = StreamController<ItemDetailData>.broadcast();
  Stream<ItemDetailData> get itemDetailData => _itemDetailController.stream;

  InventoryBloc(this._inventoryService);

  /// Load all inventory items with counts
  Future<void> loadInventoryItems() async {
    if (_isLoading) return;
    
    _isLoading = true;
    _loadingController.add(true);
    
    try {
      final items = await _inventoryService.getAllItemDefinitions();
      
      final List<InventoryItemWithCounts> itemsWithCounts = [];
      for (final item in items) {
        final counts = await _inventoryService.getItemCounts(item.id!);
        itemsWithCounts.add(InventoryItemWithCounts(
          itemDefinition: item,
          stockCount: counts['stock'] ?? 0,
          inventoryCount: counts['inventory'] ?? 0,
        ));
      }
      
      _inventoryItemsController.add(itemsWithCounts);
    } catch (e) {
      print('Error loading inventory items: $e');
      _inventoryItemsController.add([]);
    } finally {
      _isLoading = false;
      _loadingController.add(false);
    }
  }

  /// Load detailed data for a specific item
  Future<void> loadItemDetail(int itemId) async {
    if (_isLoading) return;
    
    _isLoading = true;
    _loadingController.add(true);
    
    try {
      final counts = await _inventoryService.getItemCounts(itemId);
      final instances = await _inventoryService.getItemInstances(itemId);
      final movements = await _inventoryService.getItemMovements(itemId);
      
      _itemDetailController.add(ItemDetailData(
        counts: counts,
        instances: instances,
        movements: movements,
      ));
    } catch (e) {
      print('Error loading item detail: $e');
    } finally {
      _isLoading = false;
      _loadingController.add(false);
    }
  }

  /// Create a new item definition
  Future<bool> createItemDefinition(ItemDefinition itemDefinition) async {
    try {
      await _inventoryService.createItemDefinition(itemDefinition);
      await loadInventoryItems(); // Refresh the list
      return true;
    } catch (e) {
      print('Error creating item definition: $e');
      return false;
    }
  }

  /// Update an existing item definition
  Future<bool> updateItemDefinition(ItemDefinition itemDefinition) async {
    try {
      await _inventoryService.updateItemDefinition(itemDefinition);
      await loadInventoryItems(); // Refresh the list
      return true;
    } catch (e) {
      print('Error updating item definition: $e');
      return false;
    }
  }

  /// Delete an item definition
  Future<bool> deleteItemDefinition(int id) async {
    try {
      await _inventoryService.deleteItemDefinition(id);
      await loadInventoryItems(); // Refresh the list
      return true;
    } catch (e) {
      print('Error deleting item definition: $e');
      return false;
    }
  }

  /// Update stock count (record sale)
  Future<bool> updateStockCount(int itemDefinitionId, int decreaseAmount) async {
    try {
      await _inventoryService.recordStockSale(itemDefinitionId, decreaseAmount);
      await loadItemDetail(itemDefinitionId); // Refresh the item detail
      return true;
    } catch (e) {
      print('Error updating stock count: $e');
      return false;
    }
  }

  /// Move items from inventory to stock
  Future<bool> moveInventoryToStock(int itemDefinitionId, int moveAmount) async {
    try {
      await _inventoryService.moveInventoryToStock(itemDefinitionId, moveAmount);
      await loadItemDetail(itemDefinitionId); // Refresh the item detail
      return true;
    } catch (e) {
      print('Error moving inventory to stock: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _inventoryItemsController.close();
    _loadingController.close();
    _itemDetailController.close();
  }
}