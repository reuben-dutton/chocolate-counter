import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/common/services/error_handler.dart';
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

  StockManagementCubit(
    this._inventoryService,
  ) : super(const StockManagementInitial());

  Future<void> recordStockSale(int itemDefinitionId, int decreaseAmount) async {
    try {
      emit(const StockManagementLoading());
      
      // Transaction is managed inside the service method
      // The service now handles both event bus notifications
      await _inventoryService.updateStockCount(itemDefinitionId, decreaseAmount);
      
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
      // The service now handles both event bus notifications
      await _inventoryService.moveInventoryToStock(itemDefinitionId, moveAmount);
      
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