import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
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

// Define events
abstract class InventoryEvent extends Equatable {
  const InventoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadInventoryItems extends InventoryEvent {
  const LoadInventoryItems();
}

class LoadItemDetail extends InventoryEvent {
  final int itemId;
  
  const LoadItemDetail(this.itemId);
  
  @override
  List<Object?> get props => [itemId];
}

class CreateItemDefinition extends InventoryEvent {
  final ItemDefinition itemDefinition;
  
  const CreateItemDefinition(this.itemDefinition);
  
  @override
  List<Object?> get props => [itemDefinition];
}

class UpdateItemDefinition extends InventoryEvent {
  final ItemDefinition itemDefinition;
  
  const UpdateItemDefinition(this.itemDefinition);
  
  @override
  List<Object?> get props => [itemDefinition];
}

class DeleteItemDefinition extends InventoryEvent {
  final int id;
  
  const DeleteItemDefinition(this.id);
  
  @override
  List<Object?> get props => [id];
}

class RecordStockSale extends InventoryEvent {
  final int itemDefinitionId;
  final int decreaseAmount;
  
  const RecordStockSale(this.itemDefinitionId, this.decreaseAmount);
  
  @override
  List<Object?> get props => [itemDefinitionId, decreaseAmount];
}

class MoveInventoryToStock extends InventoryEvent {
  final int itemDefinitionId;
  final int moveAmount;
  
  const MoveInventoryToStock(this.itemDefinitionId, this.moveAmount);
  
  @override
  List<Object?> get props => [itemDefinitionId, moveAmount];
}

// Define state
class InventoryState extends Equatable {
  final bool isLoading;
  final List<InventoryItemWithCounts> items;
  final ItemDetailData? itemDetail;
  final AppError? error;
  final bool operationSuccess;

  const InventoryState({
    this.isLoading = false,
    this.items = const [],
    this.itemDetail,
    this.error,
    this.operationSuccess = false,
  });

  InventoryState copyWith({
    bool? isLoading,
    List<InventoryItemWithCounts>? items,
    ItemDetailData? itemDetail,
    AppError? error,
    bool? operationSuccess,
  }) {
    return InventoryState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      itemDetail: itemDetail ?? this.itemDetail,
      error: error ?? this.error,
      operationSuccess: operationSuccess ?? this.operationSuccess,
    );
  }

  @override
  List<Object?> get props => [isLoading, items, itemDetail, error, operationSuccess];
}

/// BLoC for inventory management
class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final InventoryService _inventoryService;

  InventoryBloc(this._inventoryService) : super(const InventoryState()) {
    on<LoadInventoryItems>(_onLoadInventoryItems);
    on<LoadItemDetail>(_onLoadItemDetail);
    on<CreateItemDefinition>(_onCreateItemDefinition);
    on<UpdateItemDefinition>(_onUpdateItemDefinition);
    on<DeleteItemDefinition>(_onDeleteItemDefinition);
    on<RecordStockSale>(_onRecordStockSale);
    on<MoveInventoryToStock>(_onMoveInventoryToStock);
  }

  Future<void> _onLoadInventoryItems(
    LoadInventoryItems event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null, operationSuccess: false));
      
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
      
      emit(state.copyWith(isLoading: false, items: itemsWithCounts));
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error loading item list', e, stackTrace, 'InventoryBloc');
      emit(state.copyWith(
        isLoading: false,
        error: AppError(
          message: 'Failed to load item list',
          error: e,
          stackTrace: stackTrace,
          source: 'InventoryBloc'
        ),
      ));
    }
  }

  Future<void> _onLoadItemDetail(
    LoadItemDetail event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null, operationSuccess: false));
      
      final counts = await _inventoryService.getItemCounts(event.itemId);
      final instances = await _inventoryService.getItemInstances(event.itemId);
      final movements = await _inventoryService.getItemMovements(event.itemId);
      
      final itemDetail = ItemDetailData(
        counts: counts,
        instances: instances,
        movements: movements,
      );
      
      emit(state.copyWith(isLoading: false, itemDetail: itemDetail));
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error loading item detail', e, stackTrace, 'InventoryBloc');
      emit(state.copyWith(
        isLoading: false,
        error: AppError(
          message: 'Failed to load item details',
          error: e,
          stackTrace: stackTrace,
          source: 'InventoryBloc'
        ),
      ));
    }
  }

  Future<void> _onCreateItemDefinition(
    CreateItemDefinition event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null, operationSuccess: false));
      
      await _inventoryService.createItemDefinition(event.itemDefinition);
      
      emit(state.copyWith(isLoading: false, operationSuccess: true));
      // Refresh the items list after creation
      add(const LoadInventoryItems());
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error creating item definition', e, stackTrace, 'InventoryBloc');
      emit(state.copyWith(
        isLoading: false,
        error: AppError(
          message: 'Failed to create item',
          error: e,
          stackTrace: stackTrace,
          source: 'InventoryBloc'
        ),
        operationSuccess: false,
      ));
    }
  }

  Future<void> _onUpdateItemDefinition(
    UpdateItemDefinition event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null, operationSuccess: false));
      
      await _inventoryService.updateItemDefinition(event.itemDefinition);
      
      emit(state.copyWith(isLoading: false, operationSuccess: true));
      // Refresh the items list after update
      add(const LoadInventoryItems());
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error updating item definition', e, stackTrace, 'InventoryBloc');
      emit(state.copyWith(
        isLoading: false,
        error: AppError(
          message: 'Failed to update item',
          error: e,
          stackTrace: stackTrace,
          source: 'InventoryBloc'
        ),
        operationSuccess: false,
      ));
    }
  }

  Future<void> _onDeleteItemDefinition(
    DeleteItemDefinition event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null, operationSuccess: false));
      
      await _inventoryService.deleteItemDefinition(event.id);
      
      emit(state.copyWith(isLoading: false, operationSuccess: true));
      // Refresh the items list after deletion
      add(const LoadInventoryItems());
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error deleting item definition', e, stackTrace, 'InventoryBloc');
      emit(state.copyWith(
        isLoading: false,
        error: AppError(
          message: 'Failed to delete item',
          error: e,
          stackTrace: stackTrace,
          source: 'InventoryBloc'
        ),
        operationSuccess: false,
      ));
    }
  }

  Future<void> _onRecordStockSale(
    RecordStockSale event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null, operationSuccess: false));
      
      await _inventoryService.updateStockCount(event.itemDefinitionId, event.decreaseAmount);
      
      emit(state.copyWith(isLoading: false, operationSuccess: true));
      // Refresh item detail
      add(LoadItemDetail(event.itemDefinitionId));
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error updating stock count', e, stackTrace, 'InventoryBloc');
      emit(state.copyWith(
        isLoading: false,
        error: AppError(
          message: 'Failed to update stock count',
          error: e,
          stackTrace: stackTrace,
          source: 'InventoryBloc'
        ),
        operationSuccess: false,
      ));
    }
  }

  Future<void> _onMoveInventoryToStock(
    MoveInventoryToStock event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null, operationSuccess: false));
      
      await _inventoryService.moveInventoryToStock(event.itemDefinitionId, event.moveAmount);
      
      emit(state.copyWith(isLoading: false, operationSuccess: true));
      // Refresh item detail
      add(LoadItemDetail(event.itemDefinitionId));
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error moving inventory to stock', e, stackTrace, 'InventoryBloc');
      emit(state.copyWith(
        isLoading: false,
        error: AppError(
          message: 'Failed to move items to stock',
          error: e,
          stackTrace: stackTrace,
          source: 'InventoryBloc'
        ),
        operationSuccess: false,
      ));
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
}