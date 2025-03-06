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
  
  const UpdateShipmentItemExpiration(this.shipmentItemId, this.expirationDate);
  
  @override
  List<Object?> get props => [shipmentItemId, expirationDate];
}

// Define state
class ShipmentState extends Equatable {
  final bool isLoading;
  final List<Shipment> shipments;
  final List<ShipmentItem> shipmentItems;
  final AppError? error;
  final bool operationSuccess;

  const ShipmentState({
    this.isLoading = false,
    this.shipments = const [],
    this.shipmentItems = const [],
    this.error,
    this.operationSuccess = false,
  });

  ShipmentState copyWith({
    bool? isLoading,
    List<Shipment>? shipments,
    List<ShipmentItem>? shipmentItems,
    AppError? error,
    bool? operationSuccess,
  }) {
    return ShipmentState(
      isLoading: isLoading ?? this.isLoading,
      shipments: shipments ?? this.shipments,
      shipmentItems: shipmentItems ?? this.shipmentItems,
      error: error ?? this.error,
      operationSuccess: operationSuccess ?? this.operationSuccess,
    );
  }

  @override
  List<Object?> get props => [isLoading, shipments, shipmentItems, error, operationSuccess];
}

/// BLoC for shipment management
class ShipmentBloc extends Bloc<ShipmentEvent, ShipmentState> {
  final ShipmentService _shipmentService;

  ShipmentBloc(this._shipmentService) : super(const ShipmentState()) {
    on<LoadShipments>(_onLoadShipments);
    on<LoadShipmentItems>(_onLoadShipmentItems);
    on<CreateShipment>(_onCreateShipment);
    on<DeleteShipment>(_onDeleteShipment);
    on<UpdateShipmentItemExpiration>(_onUpdateShipmentItemExpiration);
  }

  Future<void> _onLoadShipments(
    LoadShipments event,
    Emitter<ShipmentState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null, operationSuccess: false));
      
      final shipmentList = await _shipmentService.getAllShipments();
      
      emit(state.copyWith(isLoading: false, shipments: shipmentList));
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error loading shipments', e, stackTrace, 'ShipmentBloc');
      emit(state.copyWith(
        isLoading: false,
        error: AppError(
          message: 'Failed to load shipments',
          error: e,
          stackTrace: stackTrace,
          source: 'ShipmentBloc'
        ),
      ));
    }
  }

  Future<void> _onLoadShipmentItems(
    LoadShipmentItems event,
    Emitter<ShipmentState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null, operationSuccess: false));
      
      final items = await _shipmentService.getShipmentItems(event.shipmentId);
      
      emit(state.copyWith(isLoading: false, shipmentItems: items));
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error loading shipment items', e, stackTrace, 'ShipmentBloc');
      emit(state.copyWith(
        isLoading: false,
        error: AppError(
          message: 'Failed to load shipment items',
          error: e,
          stackTrace: stackTrace,
          source: 'ShipmentBloc'
        ),
      ));
    }
  }

  Future<void> _onCreateShipment(
    CreateShipment event,
    Emitter<ShipmentState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null, operationSuccess: false));
      
      await _shipmentService.createShipment(event.shipment);
      
      emit(state.copyWith(isLoading: false, operationSuccess: true));
      // Refresh the shipments list
      add(const LoadShipments());
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error creating shipment', e, stackTrace, 'ShipmentBloc');
      emit(state.copyWith(
        isLoading: false,
        error: AppError(
          message: 'Failed to create shipment',
          error: e,
          stackTrace: stackTrace,
          source: 'ShipmentBloc'
        ),
        operationSuccess: false,
      ));
    }
  }

  Future<void> _onDeleteShipment(
    DeleteShipment event,
    Emitter<ShipmentState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null, operationSuccess: false));
      
      await _shipmentService.deleteShipment(event.id);
      
      emit(state.copyWith(isLoading: false, operationSuccess: true));
      // Refresh the shipments list
      add(const LoadShipments());
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error deleting shipment', e, stackTrace, 'ShipmentBloc');
      emit(state.copyWith(
        isLoading: false,
        error: AppError(
          message: 'Failed to delete shipment',
          error: e,
          stackTrace: stackTrace,
          source: 'ShipmentBloc'
        ),
        operationSuccess: false,
      ));
    }
  }

  Future<void> _onUpdateShipmentItemExpiration(
    UpdateShipmentItemExpiration event,
    Emitter<ShipmentState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null, operationSuccess: false));
      
      await _shipmentService.updateShipmentItemExpiration(
        event.shipmentItemId, 
        event.expirationDate
      );
      
      emit(state.copyWith(isLoading: false, operationSuccess: true));
      
      // We need to reload the shipment items for the affected shipment
      // We can't do that here because we don't know the shipment ID
      // The UI needs to handle this by dispatching a LoadShipmentItems event
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error updating shipment item expiration', e, stackTrace, 'ShipmentBloc');
      emit(state.copyWith(
        isLoading: false,
        error: AppError(
          message: 'Failed to update expiration date',
          error: e,
          stackTrace: stackTrace,
          source: 'ShipmentBloc'
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