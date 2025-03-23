import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/data/models/inventory_movement.dart';
import 'package:food_inventory/features/inventory/event_bus/inventory_event_bus.dart';
import 'package:food_inventory/features/inventory/services/inventory_service.dart';

// States
abstract class StockManagementState extends Equatable {
  final AppError? error;
  
  const StockManagementState({this.error});
  
  @override
  List<Object?> get props => [error];
}

class StockManagementInitial extends StockManagementState {
  const StockManagementInitial();
}

class StockManagementLoading extends StockManagementState {
  const StockManagementLoading();
}

class StockOperationSuccess extends StockManagementState {
  final String operationType;
  final int itemId;
  
  const StockOperationSuccess({
    required this.operationType,
    required this.itemId,
    super.error,
  });
  
  @override
  List<Object?> get props => [operationType, itemId, error];
}

class StockOperationFailure extends StockManagementState {
  final String operationType;
  
  const StockOperationFailure({
    required this.operationType,
    required super.error,
  });
  
  @override
  List<Object?> get props => [operationType, error];
}

// Cubit
class StockManagementCubit extends Cubit<StockManagementState> {
  final InventoryService _inventoryService;
  final InventoryEventBus _eventBus;

  StockManagementCubit(
    this._inventoryService,
    this._eventBus
  ) : super(const StockManagementInitial());

  Future<void> recordStockSale(int itemDefinitionId, int decreaseAmount) async {
    try {
      emit(const StockManagementLoading());
      
      // Transaction is managed inside the service method
      await _inventoryService.updateStockCount(itemDefinitionId, decreaseAmount);
      
      // Notify about inventory change
      _eventBus.emit(InventoryDataChanged(itemDefinitionId: itemDefinitionId));
      
      emit(StockOperationSuccess(
        operationType: 'stockSale',
        itemId: itemDefinitionId,
      ));
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error updating stock count', e, stackTrace, 'StockManagementCubit');
      emit(StockOperationFailure(
        operationType: 'stockSale',
        error: AppError(
          message: 'Failed to update stock count',
          error: e,
          stackTrace: stackTrace,
          source: 'StockManagementCubit'
        ),
      ));
    }
  }

  Future<void> moveInventoryToStock(int itemDefinitionId, int moveAmount) async {
    try {
      emit(const StockManagementLoading());
      
      // Transaction is managed inside the service method
      await _inventoryService.moveInventoryToStock(itemDefinitionId, moveAmount);
      
      // Notify about inventory change
      _eventBus.emit(InventoryDataChanged(itemDefinitionId: itemDefinitionId));
      
      emit(StockOperationSuccess(
        operationType: 'moveToStock',
        itemId: itemDefinitionId,
      ));
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error moving inventory to stock', e, stackTrace, 'StockManagementCubit');
      emit(StockOperationFailure(
        operationType: 'moveToStock',
        error: AppError(
          message: 'Failed to move items to stock',
          error: e,
          stackTrace: stackTrace,
          source: 'StockManagementCubit'
        ),
      ));
    }
  }

  void clearOperationState() {
    emit(const StockManagementInitial());
  }
}