import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/data/models/shipment.dart';
import 'package:food_inventory/data/models/shipment_item.dart';
import 'package:food_inventory/features/shipments/services/shipment_service.dart';

// Define events
abstract class ShipmentEvent extends Equatable {
  const ShipmentEvent();

  @override
  List<Object?> get props => [];
}

class InitializeShipmentsScreen extends ShipmentEvent {
  const InitializeShipmentsScreen();
}

class LoadShipments extends ShipmentEvent {
  const LoadShipments();
}

class LoadShipmentItems extends ShipmentEvent {
  final int shipmentId;
  
  const LoadShipmentItems(this.shipmentId);
  
  @override
  List<Object?> get props => [shipmentId];
}

class CreateShipment extends ShipmentEvent {
  final Shipment shipment;
  
  const CreateShipment(this.shipment);
  
  @override
  List<Object?> get props => [shipment];
}

class DeleteShipment extends ShipmentEvent {
  final int id;
  
  const DeleteShipment(this.id);
  
  @override
  List<Object?> get props => [id];
}

class UpdateShipmentItemExpiration extends ShipmentEvent {
  final int shipmentItemId;
  final DateTime? expirationDate;
  final int shipmentId;
  
  const UpdateShipmentItemExpiration({
    required this.shipmentItemId, 
    required this.expirationDate,
    required this.shipmentId,
  });
  
  @override
  List<Object?> get props => [shipmentItemId, expirationDate, shipmentId];
}

class ClearOperationState extends ShipmentEvent {
  const ClearOperationState();
}

// Split into more focused states
abstract class ShipmentState extends Equatable {
  final AppError? error;
  
  const ShipmentState({this.error});
  
  @override
  List<Object?> get props => [error];
}

class ShipmentInitial extends ShipmentState {
  const ShipmentInitial();
}

class ShipmentLoading extends ShipmentState {
  const ShipmentLoading();
}

class ShipmentsLoaded extends ShipmentState {
  final List<Shipment> shipments;
  
  const ShipmentsLoaded(this.shipments, {super.error});
  
  @override
  List<Object?> get props => [shipments, error];
  
  ShipmentsLoaded copyWith({
    List<Shipment>? shipments,
    AppError? error,
  }) {
    return ShipmentsLoaded(
      shipments ?? this.shipments,
      error: error ?? this.error,
    );
  }
}

class ShipmentItemsLoaded extends ShipmentState {
  final List<ShipmentItem> shipmentItems;
  
  const ShipmentItemsLoaded(this.shipmentItems, {super.error});
  
  @override
  List<Object?> get props => [shipmentItems, error];
  
  ShipmentItemsLoaded copyWith({
    List<ShipmentItem>? shipmentItems,
    AppError? error,
  }) {
    return ShipmentItemsLoaded(
      shipmentItems ?? this.shipmentItems,
      error: error ?? this.error,
    );
  }
}

class OperationResult extends ShipmentState {
  final bool success;
  final OperationType operationType;
  
  const OperationResult({
    required this.success,
    required this.operationType,
    super.error,
  });
  
  @override
  List<Object?> get props => [success, operationType, error];
}

enum OperationType { delete, update, create }

/// BLoC for shipment management
class ShipmentBloc extends Bloc<ShipmentEvent, ShipmentState> {
  final ShipmentService _shipmentService;

  ShipmentBloc(this._shipmentService) : super(const ShipmentInitial()) {
    on<InitializeShipmentsScreen>(_onInitializeShipmentsScreen);
    on<LoadShipments>(_onLoadShipments);
    on<LoadShipmentItems>(_onLoadShipmentItems);
    on<CreateShipment>(_onCreateShipment);
    on<DeleteShipment>(_onDeleteShipment);
    on<UpdateShipmentItemExpiration>(_onUpdateShipmentItemExpiration);
    on<ClearOperationState>(_onClearOperationState);
  }

  Future<void> _onInitializeShipmentsScreen(
    InitializeShipmentsScreen event,
    Emitter<ShipmentState> emit,
  ) async {
    // Only load if we're not already loading and don't have data
    if (state is! ShipmentsLoaded && state is! ShipmentLoading) {
      add(const LoadShipments());
    }
  }

  Future<void> _onLoadShipments(
    LoadShipments event,
    Emitter<ShipmentState> emit,
  ) async {
    try {
      emit(const ShipmentLoading());
      
      // Use transaction for consistent read
      await _shipmentService.withTransaction((txn) async {
        final shipmentList = await _shipmentService.getAllShipments(txn: txn);
        emit(ShipmentsLoaded(shipmentList));
      });
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error loading shipments', e, stackTrace, 'ShipmentBloc');
      
      // If we already had shipments loaded, keep them but add the error
      if (state is ShipmentsLoaded) {
        emit((state as ShipmentsLoaded).copyWith(
          error: AppError(
            message: 'Failed to load shipments',
            error: e,
            stackTrace: stackTrace,
            source: 'ShipmentBloc'
          ),
        ));
      } else {
        emit(ShipmentsLoaded(
          const [],
          error: AppError(
            message: 'Failed to load shipments',
            error: e,
            stackTrace: stackTrace,
            source: 'ShipmentBloc'
          ),
        ));
      }
    }
  }

  Future<void> _onLoadShipmentItems(
    LoadShipmentItems event,
    Emitter<ShipmentState> emit,
  ) async {
    try {
      emit(const ShipmentLoading());
      
      // Use transaction for consistent read
      await _shipmentService.withTransaction((txn) async {
        final items = await _shipmentService.getShipmentItems(event.shipmentId, txn: txn);
        emit(ShipmentItemsLoaded(items));
      });
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error loading shipment items', e, stackTrace, 'ShipmentBloc');
      
      // If we already had items loaded, keep them but add the error
      if (state is ShipmentItemsLoaded) {
        emit((state as ShipmentItemsLoaded).copyWith(
          error: AppError(
            message: 'Failed to load shipment items',
            error: e,
            stackTrace: stackTrace,
            source: 'ShipmentBloc'
          ),
        ));
      } else {
        emit(ShipmentItemsLoaded(
          const [],
          error: AppError(
            message: 'Failed to load shipment items',
            error: e,
            stackTrace: stackTrace,
            source: 'ShipmentBloc'
          ),
        ));
      }
    }
  }

  Future<void> _onCreateShipment(
    CreateShipment event,
    Emitter<ShipmentState> emit,
  ) async {
    try {
      emit(const ShipmentLoading());
      
      // Transaction is managed inside the service method
      await _shipmentService.createShipment(event.shipment);
      
      emit(const OperationResult(success: true, operationType: OperationType.create));
      add(const LoadShipments());
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error creating shipment', e, stackTrace, 'ShipmentBloc');
      emit(OperationResult(
        success: false,
        operationType: OperationType.create,
        error: AppError(
          message: 'Failed to create shipment',
          error: e,
          stackTrace: stackTrace,
          source: 'ShipmentBloc'
        ),
      ));
    }
  }

  Future<void> _onDeleteShipment(
    DeleteShipment event,
    Emitter<ShipmentState> emit,
  ) async {
    try {
      emit(const ShipmentLoading());
      
      // Transaction is managed inside the service method
      await _shipmentService.deleteShipment(event.id);
      
      emit(const OperationResult(success: true, operationType: OperationType.delete));
      add(const LoadShipments());
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error deleting shipment', e, stackTrace, 'ShipmentBloc');
      emit(OperationResult(
        success: false,
        operationType: OperationType.delete,
        error: AppError(
          message: 'Failed to delete shipment',
          error: e,
          stackTrace: stackTrace,
          source: 'ShipmentBloc'
        ),
      ));
    }
  }

Future<void> _onUpdateShipmentItemExpiration(
    UpdateShipmentItemExpiration event,
    Emitter<ShipmentState> emit,
  ) async {
    try {
      emit(const ShipmentLoading());
      
      // First update the expiration date
      await _shipmentService.updateShipmentItemExpiration(
        event.shipmentItemId, 
        event.expirationDate
      );
      
      // Then load the items with a fresh transaction
      final items = await _shipmentService.getShipmentItems(event.shipmentId);
      
      // First emit operation result
      emit(const OperationResult(success: true, operationType: OperationType.update));
      
      // Then emit updated items
      emit(ShipmentItemsLoaded(items));
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error updating shipment item expiration', e, stackTrace, 'ShipmentBloc');
      emit(OperationResult(
        success: false,
        operationType: OperationType.update,
        error: AppError(
          message: 'Failed to update expiration date',
          error: e,
          stackTrace: stackTrace,
          source: 'ShipmentBloc'
        ),
      ));
    }
  }

  void _onClearOperationState(
    ClearOperationState event,
    Emitter<ShipmentState> emit,
  ) {
    // If we're in OperationResult state, go back to initial state
    // to avoid sticky operation result
    if (state is OperationResult) {
      emit(const ShipmentInitial());
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