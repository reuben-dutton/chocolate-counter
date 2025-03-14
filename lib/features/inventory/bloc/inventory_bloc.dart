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

class InitializeInventoryScreen extends InventoryEvent {
  const InitializeInventoryScreen();
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

class ClearOperationState extends InventoryEvent {
  const ClearOperationState();
}

// Split into more focused states
abstract class InventoryState extends Equatable {
  final AppError? error;
  
  const InventoryState({this.error});
  
  @override
  List<Object?> get props => [error];
}

class InventoryInitial extends InventoryState {
  const InventoryInitial();
}

class InventoryLoading extends InventoryState {
  const InventoryLoading();
}

class InventoryItemsLoaded extends InventoryState {
  final List<InventoryItemWithCounts> items;
  
  const InventoryItemsLoaded(this.items, {super.error});
  
  @override
  List<Object?> get props => [items, error];
  
  InventoryItemsLoaded copyWith({
    List<InventoryItemWithCounts>? items,
    AppError? error,
  }) {
    return InventoryItemsLoaded(
      items ?? this.items,
      error: error ?? this.error,
    );
  }
}

class ItemDetailLoaded extends InventoryState {
  final ItemDetailData itemDetail;
  
  const ItemDetailLoaded(this.itemDetail, {super.error});
  
  @override
  List<Object?> get props => [itemDetail, error];
  
  ItemDetailLoaded copyWith({
    ItemDetailData? itemDetail,
    AppError? error,
  }) {
    return ItemDetailLoaded(
      itemDetail ?? this.itemDetail,
      error: error ?? this.error,
    );
  }
}

class OperationResult extends InventoryState {
  final bool success;
  
  const OperationResult({
    required this.success,
    super.error,
  });
  
  @override
  List<Object?> get props => [success, error];
}

/// BLoC for inventory management
class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final InventoryService _inventoryService;

  InventoryBloc(this._inventoryService) : super(const InventoryInitial()) {
    on<InitializeInventoryScreen>(_onInitializeInventoryScreen);
    on<LoadInventoryItems>(_onLoadInventoryItems);
    on<LoadItemDetail>(_onLoadItemDetail);
    on<CreateItemDefinition>(_onCreateItemDefinition);
    on<UpdateItemDefinition>(_onUpdateItemDefinition);
    on<DeleteItemDefinition>(_onDeleteItemDefinition);
    on<RecordStockSale>(_onRecordStockSale);
    on<MoveInventoryToStock>(_onMoveInventoryToStock);
    on<ClearOperationState>(_onClearOperationState);
  }

  Future<void> _onInitializeInventoryScreen(
    InitializeInventoryScreen event,
    Emitter<InventoryState> emit,
  ) async {
    // Only load if we're not already loading and don't have data
    if (state is! InventoryItemsLoaded && state is! InventoryLoading) {
      add(const LoadInventoryItems());
    }
  }

  Future<void> _onLoadInventoryItems(
    LoadInventoryItems event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      emit(const InventoryLoading());
      
      // Use transaction for consistent read
      await _inventoryService.withTransaction((txn) async {
        final items = await _inventoryService.getAllItemDefinitions(txn: txn);
        
        final List<InventoryItemWithCounts> itemsWithCounts = [];
        for (final item in items) {
          final counts = await _inventoryService.getItemCounts(item.id!, txn: txn);
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
        
        emit(InventoryItemsLoaded(itemsWithCounts));
      });
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error loading item list', e, stackTrace, 'InventoryBloc');
      
      // If we already had items loaded, keep them but add the error
      if (state is InventoryItemsLoaded) {
        emit((state as InventoryItemsLoaded).copyWith(
          error: AppError(
            message: 'Failed to load item list',
            error: e,
            stackTrace: stackTrace,
            source: 'InventoryBloc'
          ),
        ));
      } else {
        emit(InventoryItemsLoaded(
          const [],
          error: AppError(
            message: 'Failed to load item list',
            error: e,
            stackTrace: stackTrace,
            source: 'InventoryBloc'
          ),
        ));
      }
    }
  }

  Future<void> _onLoadItemDetail(
    LoadItemDetail event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      emit(const InventoryLoading());
      
      // Use transaction for consistent read
      await _inventoryService.withTransaction((txn) async {
        final counts = await _inventoryService.getItemCounts(event.itemId, txn: txn);
        final instances = await _inventoryService.getItemInstances(event.itemId, txn: txn);
        final movements = await _inventoryService.getItemMovements(event.itemId, txn: txn);
        
        final itemDetail = ItemDetailData(
          counts: counts,
          instances: instances,
          movements: movements,
        );
        
        emit(ItemDetailLoaded(itemDetail));
      });
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error loading item detail', e, stackTrace, 'InventoryBloc');
      
      // If we already had item detail loaded, keep it but add the error
      if (state is ItemDetailLoaded) {
        emit((state as ItemDetailLoaded).copyWith(
          error: AppError(
            message: 'Failed to load item details',
            error: e,
            stackTrace: stackTrace,
            source: 'InventoryBloc'
          ),
        ));
      } else {
        emit(InventoryItemsLoaded([], error: AppError(
          message: 'Failed to load item details',
          error: e,
          stackTrace: stackTrace,
          source: 'InventoryBloc'
        )));
      }
    }
  }
  
  Future<void> _onCreateItemDefinition(
    CreateItemDefinition event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      emit(const InventoryLoading());
      
      // Use transaction for atomic operation
      await _inventoryService.withTransaction((txn) async {
        await _inventoryService.createItemDefinition(event.itemDefinition, txn: txn);
      });
      
      emit(const OperationResult(success: true));
      add(const LoadInventoryItems());
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error creating item definition', e, stackTrace, 'InventoryBloc');
      emit(OperationResult(
        success: false,
        error: AppError(
          message: 'Failed to create item',
          error: e,
          stackTrace: stackTrace,
          source: 'InventoryBloc'
        ),
      ));
    }
  }

  Future<void> _onUpdateItemDefinition(
    UpdateItemDefinition event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      emit(const InventoryLoading());
      
      // Use transaction for atomic operation
      await _inventoryService.withTransaction((txn) async {
        await _inventoryService.updateItemDefinition(event.itemDefinition, txn: txn);
      });
      
      emit(const OperationResult(success: true));
      add(const LoadInventoryItems());
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error updating item definition', e, stackTrace, 'InventoryBloc');
      emit(OperationResult(
        success: false,
        error: AppError(
          message: 'Failed to update item',
          error: e,
          stackTrace: stackTrace,
          source: 'InventoryBloc'
        ),
      ));
    }
  }

  Future<void> _onDeleteItemDefinition(
    DeleteItemDefinition event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      emit(const InventoryLoading());
      
      // Use transaction for atomic deletion (will cascade to related records)
      await _inventoryService.withTransaction((txn) async {
        await _inventoryService.deleteItemDefinition(event.id, txn: txn);
      });
      
      emit(const OperationResult(success: true));
      add(const LoadInventoryItems());
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error deleting item definition', e, stackTrace, 'InventoryBloc');
      emit(OperationResult(
        success: false,
        error: AppError(
          message: 'Failed to delete item',
          error: e,
          stackTrace: stackTrace,
          source: 'InventoryBloc'
        ),
      ));
    }
  }

  Future<void> _onRecordStockSale(
    RecordStockSale event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      emit(const InventoryLoading());
      
      // Transaction is managed inside the service method
      await _inventoryService.updateStockCount(event.itemDefinitionId, event.decreaseAmount);
      
      emit(const OperationResult(success: true));
      add(LoadItemDetail(event.itemDefinitionId));
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error updating stock count', e, stackTrace, 'InventoryBloc');
      emit(OperationResult(
        success: false,
        error: AppError(
          message: 'Failed to update stock count',
          error: e,
          stackTrace: stackTrace,
          source: 'InventoryBloc'
        ),
      ));
    }
  }

  Future<void> _onMoveInventoryToStock(
    MoveInventoryToStock event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      emit(const InventoryLoading());
      
      // Transaction is managed inside the service method
      await _inventoryService.moveInventoryToStock(event.itemDefinitionId, event.moveAmount);
      
      emit(const OperationResult(success: true));
      add(LoadItemDetail(event.itemDefinitionId));
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error moving inventory to stock', e, stackTrace, 'InventoryBloc');
      emit(OperationResult(
        success: false,
        error: AppError(
          message: 'Failed to move items to stock',
          error: e,
          stackTrace: stackTrace,
          source: 'InventoryBloc'
        ),
      ));
    }
  }

  void _onClearOperationState(
    ClearOperationState event,
    Emitter<InventoryState> emit,
  ) {
    // If we're in OperationResult state, go back to initial state
    // to avoid sticky operation result
    if (state is OperationResult) {
      emit(const InventoryInitial());
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