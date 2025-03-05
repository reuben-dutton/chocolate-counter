import 'dart:async';

import 'package:flutter/material.dart';
import 'package:food_inventory/common/bloc/bloc_base.dart';
import 'package:food_inventory/common/services/error_handler.dart';
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

  // Stream for errors
  final _errorController = StreamController<AppError>.broadcast();
  Stream<AppError> get errors => _errorController.stream;

  InventoryBloc(this._inventoryService);

  // Load all inventory items with counts
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
      
      // Sort items - push items with 0 stock and 0 inventory to the bottom
      itemsWithCounts.sort((a, b) {
        // If both items have zero counts or both have non-zero counts, sort alphabetically
        bool aIsEmpty = a.stockCount == 0 && a.inventoryCount == 0;
        bool bIsEmpty = b.stockCount == 0 && b.inventoryCount == 0;
        
        if (aIsEmpty == bIsEmpty) {
          return a.itemDefinition.name.compareTo(b.itemDefinition.name);
        }
        
        // Empty items go to the bottom
        return aIsEmpty ? 1 : -1;
      });
      
      _inventoryItemsController.add(itemsWithCounts);
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error loading item list', e, stackTrace, 'InventoryBloc');
      _errorController.add(AppError(
        message: 'Failed to load item list',
        error: e,
        stackTrace: stackTrace,
        source: 'InventoryBloc'
      ));
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
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error loading item detail', e, stackTrace, 'InventoryBloc');
      _errorController.add(AppError(
        message: 'Failed to load item details',
        error: e,
        stackTrace: stackTrace,
        source: 'InventoryBloc'
      ));
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
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error creating item definition', e, stackTrace, 'InventoryBloc');
      _errorController.add(AppError(
        message: 'Failed to create item',
        error: e,
        stackTrace: stackTrace,
        source: 'InventoryBloc'
      ));
      return false;
    }
  }

  /// Update an existing item definition
  Future<bool> updateItemDefinition(ItemDefinition itemDefinition) async {
    try {
      await _inventoryService.updateItemDefinition(itemDefinition);
      await loadInventoryItems(); // Refresh the list
      return true;
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error updating item definition', e, stackTrace, 'InventoryBloc');
      _errorController.add(AppError(
        message: 'Failed to update item',
        error: e,
        stackTrace: stackTrace,
        source: 'InventoryBloc'
      ));
      return false;
    }
  }

  /// Delete an item definition
  Future<bool> deleteItemDefinition(int id) async {
    try {
      await _inventoryService.deleteItemDefinition(id);
      await loadInventoryItems(); // Refresh the list
      return true;
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error deleting item definition', e, stackTrace, 'InventoryBloc');
      _errorController.add(AppError(
        message: 'Failed to delete item',
        error: e,
        stackTrace: stackTrace,
        source: 'InventoryBloc'
      ));
      return false;
    }
  }

  /// Update stock count (record sale)
  Future<bool> recordStockSale(int itemDefinitionId, int decreaseAmount) async {
    try {
      await _inventoryService.updateStockCount(itemDefinitionId, decreaseAmount);
      await loadItemDetail(itemDefinitionId); // Refresh the item detail
      return true;
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error updating stock count', e, stackTrace, 'InventoryBloc');
      _errorController.add(AppError(
        message: 'Failed to update stock count',
        error: e,
        stackTrace: stackTrace,
        source: 'InventoryBloc'
      ));
      return false;
    }
  }

  /// Move items from inventory to stock
  Future<bool> moveInventoryToStock(int itemDefinitionId, int moveAmount) async {
    try {
      await _inventoryService.moveInventoryToStock(itemDefinitionId, moveAmount);
      await loadItemDetail(itemDefinitionId); // Refresh the item detail
      return true;
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error moving inventory to stock', e, stackTrace, 'InventoryBloc');
      _errorController.add(AppError(
        message: 'Failed to move items to stock',
        error: e,
        stackTrace: stackTrace,
        source: 'InventoryBloc'
      ));
      return false;
    }
  }

  /// Handle an error with a BuildContext for UI feedback
  void handleError(BuildContext context, AppError error) {
    ErrorHandler.showErrorSnackBar(
      context, 
      error.message,
      error: error.error
    );
  }

  @override
  void dispose() {
    _inventoryItemsController.close();
    _loadingController.close();
    _itemDetailController.close();
    _errorController.close();
  }
}