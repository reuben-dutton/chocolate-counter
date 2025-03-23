import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/data/models/inventory_movement.dart';
import 'package:food_inventory/data/models/item_instance.dart';
import 'package:food_inventory/features/inventory/event_bus/inventory_event_bus.dart';
import 'package:food_inventory/features/inventory/services/inventory_service.dart';

// Data class for item detail
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

// States
abstract class ItemDetailState extends Equatable {
  final AppError? error;
  
  const ItemDetailState({this.error});
  
  @override
  List<Object?> get props => [error];
}

class ItemDetailInitial extends ItemDetailState {
  const ItemDetailInitial();
}

class ItemDetailLoading extends ItemDetailState {
  const ItemDetailLoading();
}

class ItemDetailLoaded extends ItemDetailState {
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

// Cubit
class ItemDetailCubit extends Cubit<ItemDetailState> {
  final InventoryService _inventoryService;
  final InventoryEventBus _eventBus;
  int? _currentItemId;

  ItemDetailCubit(
    this._inventoryService,
    this._eventBus
  ) : super(const ItemDetailInitial()) {
    // Listen for inventory changes to refresh data when needed
    _eventBus.stream.listen(_handleInventoryEvent);
  }

  void _handleInventoryEvent(InventoryEvent event) {
    if (_currentItemId != null && 
        event is InventoryDataChanged && 
        event.itemDefinitionId == _currentItemId) {
      loadItemDetail(_currentItemId!);
    }
  }

  Future<void> loadItemDetail(int itemId) async {
    try {
      _currentItemId = itemId;
      emit(const ItemDetailLoading());
      
      // Use transaction for consistent read
      final detail = await _inventoryService.withTransaction((txn) async {
        final counts = await _inventoryService.getItemCounts(itemId, txn: txn);
        final instances = await _inventoryService.getItemInstances(itemId, txn: txn);
        final movements = await _inventoryService.getItemMovements(itemId, txn: txn);
        
        return ItemDetailData(
          counts: counts,
          instances: instances,
          movements: movements,
        );
      });
      
      emit(ItemDetailLoaded(detail));
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error loading item detail', e, stackTrace, 'ItemDetailCubit');
      
      // If we already had item detail loaded, keep it but add the error
      if (state is ItemDetailLoaded) {
        emit((state as ItemDetailLoaded).copyWith(
          error: AppError(
            message: 'Failed to load item details',
            error: e,
            stackTrace: stackTrace,
            source: 'ItemDetailCubit'
          ),
        ));
      } else {
        emit(ItemDetailLoaded(
          ItemDetailData(counts: {}, instances: [], movements: []),
          error: AppError(
            message: 'Failed to load item details',
            error: e,
            stackTrace: stackTrace,
            source: 'ItemDetailCubit'
          ),
        ));
      }
    }
  }

  @override
  Future<void> close() {
    _currentItemId = null;
    return super.close();
  }
}