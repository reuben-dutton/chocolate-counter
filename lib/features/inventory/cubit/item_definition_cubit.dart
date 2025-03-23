import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/data/models/item_definition.dart';
import 'package:food_inventory/data/repositories/item_definition_repository.dart';
import 'package:food_inventory/data/repositories/item_instance_repository.dart';
import 'package:food_inventory/features/inventory/event_bus/inventory_event_bus.dart';

// States
abstract class ItemDefinitionState extends Equatable {
  final AppError? error;
  
  const ItemDefinitionState({this.error});
  
  @override
  List<Object?> get props => [error];
}

class ItemDefinitionInitial extends ItemDefinitionState {
  const ItemDefinitionInitial();
}

class ItemDefinitionLoading extends ItemDefinitionState {
  const ItemDefinitionLoading();
}

class ItemDefinitionLoaded extends ItemDefinitionState {
  final List<InventoryItemWithCounts> items;
  
  const ItemDefinitionLoaded(this.items, {super.error});
  
  @override
  List<Object?> get props => [items, error];
  
  ItemDefinitionLoaded copyWith({
    List<InventoryItemWithCounts>? items,
    AppError? error,
  }) {
    return ItemDefinitionLoaded(
      items ?? this.items,
      error: error ?? this.error,
    );
  }
}

class OperationResult extends ItemDefinitionState {
  final bool success;
  final String operationType;
  
  const OperationResult({
    required this.success,
    required this.operationType,
    super.error,
  });
  
  @override
  List<Object?> get props => [success, operationType, error];
}

// Data class for inventory item with counts (moved from original InventoryBloc)
class InventoryItemWithCounts {
  final ItemDefinition itemDefinition;
  final int stockCount;
  final int inventoryCount;
  final bool isEmptyItem;
  final DateTime? earliestExpirationDate;

  InventoryItemWithCounts({
    required this.itemDefinition,
    required this.stockCount,
    required this.inventoryCount,
    this.earliestExpirationDate,
  }) : isEmptyItem = stockCount == 0 && inventoryCount == 0;
}

// Cubit
class ItemDefinitionCubit extends Cubit<ItemDefinitionState> {
  final ItemDefinitionRepository _itemDefinitionRepository;
  final ItemInstanceRepository _itemInstanceRepository;
  final InventoryEventBus _eventBus;

  ItemDefinitionCubit(
    this._itemDefinitionRepository, 
    this._itemInstanceRepository,
    this._eventBus
  ) : super(const ItemDefinitionInitial()) {
    // Listen for inventory changes to refresh data when needed
    _eventBus.stream.listen(_handleInventoryEvent);
  }

  void _handleInventoryEvent(InventoryEvent event) {
    if (event is InventoryDataChanged || 
        event is ItemDefinitionCreated || 
        event is ItemDefinitionUpdated || 
        event is ItemDefinitionDeleted) {
      loadItems();
    }
  }

  Future<void> loadItems() async {
    try {
      emit(const ItemDefinitionLoading());
      
      // Use transaction for consistent read
      final items = await _itemDefinitionRepository.withTransaction((txn) async {
        final allItems = await _itemDefinitionRepository.getAllSorted(txn: txn);
        
        final List<InventoryItemWithCounts> itemsWithCounts = [];
        for (final item in allItems) {
          final counts = await _itemInstanceRepository.getItemCounts(item.id!, txn: txn);
          final instances = await _itemInstanceRepository.getInstancesForItem(item.id!, txn: txn);
          
          // Find earliest expiration date
          DateTime? earliestDate;
          for (final instance in instances) {
            if (instance.expirationDate != null) {
              if (earliestDate == null || instance.expirationDate!.isBefore(earliestDate)) {
                earliestDate = instance.expirationDate;
              }
            }
          }
          
          itemsWithCounts.add(InventoryItemWithCounts(
            itemDefinition: item,
            stockCount: counts['stock'] ?? 0,
            inventoryCount: counts['inventory'] ?? 0,
            earliestExpirationDate: earliestDate,
          ));
        }
        
        // Sort items
        itemsWithCounts.sort((a, b) {
          bool aIsEmpty = a.stockCount == 0 && a.inventoryCount == 0;
          bool bIsEmpty = b.stockCount == 0 && b.inventoryCount == 0;
          
          if (aIsEmpty == bIsEmpty) {
            return a.itemDefinition.name.compareTo(b.itemDefinition.name);
          }
          
          return aIsEmpty ? 1 : -1;
        });
        
        return itemsWithCounts;
      });
      
      emit(ItemDefinitionLoaded(items));
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error loading item list', e, stackTrace, 'ItemDefinitionCubit');
      
      // If we already had items loaded, keep them but add the error
      if (state is ItemDefinitionLoaded) {
        emit((state as ItemDefinitionLoaded).copyWith(
          error: AppError(
            message: 'Failed to load item list',
            error: e,
            stackTrace: stackTrace,
            source: 'ItemDefinitionCubit'
          ),
        ));
      } else {
        emit(ItemDefinitionLoaded(
          const [],
          error: AppError(
            message: 'Failed to load item list',
            error: e,
            stackTrace: stackTrace,
            source: 'ItemDefinitionCubit'
          ),
        ));
      }
    }
  }

  Future<void> createItemDefinition(ItemDefinition itemDefinition) async {
    try {
      emit(const ItemDefinitionLoading());
      
      // Use transaction for atomic operation
      await _itemDefinitionRepository.withTransaction((txn) async {
        await _itemDefinitionRepository.create(itemDefinition, txn: txn);
      });
      
      // Notify other components about the change
      _eventBus.emit(ItemDefinitionCreated(itemDefinition));
      
      emit(const OperationResult(success: true, operationType: 'create'));
      loadItems();
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error creating item definition', e, stackTrace, 'ItemDefinitionCubit');
      emit(OperationResult(
        success: false,
        operationType: 'create',
        error: AppError(
          message: 'Failed to create item',
          error: e,
          stackTrace: stackTrace,
          source: 'ItemDefinitionCubit'
        ),
      ));
    }
  }

  Future<void> updateItemDefinition(ItemDefinition itemDefinition) async {
    try {
      emit(const ItemDefinitionLoading());
      
      // Use transaction for atomic operation
      await _itemDefinitionRepository.withTransaction((txn) async {
        await _itemDefinitionRepository.update(itemDefinition, txn: txn);
      });
      
      // Notify other components about the change
      _eventBus.emit(ItemDefinitionUpdated(itemDefinition));
      
      emit(const OperationResult(success: true, operationType: 'update'));
      loadItems();
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error updating item definition', e, stackTrace, 'ItemDefinitionCubit');
      emit(OperationResult(
        success: false,
        operationType: 'update',
        error: AppError(
          message: 'Failed to update item',
          error: e,
          stackTrace: stackTrace,
          source: 'ItemDefinitionCubit'
        ),
      ));
    }
  }

  Future<void> deleteItemDefinition(int id) async {
    try {
      emit(const ItemDefinitionLoading());
      
      // Use transaction for atomic deletion (will cascade to related records)
      await _itemDefinitionRepository.withTransaction((txn) async {
        await _itemDefinitionRepository.delete(id, txn: txn);
      });
      
      // Notify other components about the change
      _eventBus.emit(ItemDefinitionDeleted(id));
      
      emit(const OperationResult(success: true, operationType: 'delete'));
      loadItems();
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error deleting item definition', e, stackTrace, 'ItemDefinitionCubit');
      emit(OperationResult(
        success: false,
        operationType: 'delete',
        error: AppError(
          message: 'Failed to delete item',
          error: e,
          stackTrace: stackTrace,
          source: 'ItemDefinitionCubit'
        ),
      ));
    }
  }

  void clearOperationState() {
    if (state is OperationResult) {
      emit(const ItemDefinitionInitial());
    }
  }

  @override
  Future<void> close() {
    // Cleanup
    return super.close();
  }
}