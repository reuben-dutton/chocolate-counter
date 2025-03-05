import 'dart:async';

import 'package:flutter/material.dart';
import 'package:food_inventory/common/bloc/bloc_base.dart';
import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/data/models/shipment.dart';
import 'package:food_inventory/data/models/shipment_item.dart';
import 'package:food_inventory/features/shipments/services/shipment_service.dart';

/// BLoC for shipment management
class ShipmentBloc extends BlocBase {
  final ShipmentService _shipmentService;
  bool _isLoading = false;

  // Stream for all shipments
  final _shipmentsController = StreamController<List<Shipment>>.broadcast();
  Stream<List<Shipment>> get shipments => _shipmentsController.stream;

  // Stream for shipment items
  final _shipmentItemsController = StreamController<List<ShipmentItem>>.broadcast();
  Stream<List<ShipmentItem>> get shipmentItems => _shipmentItemsController.stream;

  // Stream for loading state
  final _loadingController = StreamController<bool>.broadcast();
  Stream<bool> get isLoading => _loadingController.stream;

  // Stream for errors
  final _errorController = StreamController<AppError>.broadcast();
  Stream<AppError> get errors => _errorController.stream;

  ShipmentBloc(this._shipmentService);

  /// Load all shipments
  Future<void> loadShipments() async {
    if (_isLoading) return;
    
    _isLoading = true;
    _loadingController.add(true);
    
    try {
      final shipmentList = await _shipmentService.getAllShipments();
      _shipmentsController.add(shipmentList);
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error loading shipments', e, stackTrace, 'ShipmentBloc');
      _shipmentsController.add([]);
      _errorController.add(AppError(
        message: 'Failed to load shipments',
        error: e,
        stackTrace: stackTrace,
        source: 'ShipmentBloc'
      ));
    } finally {
      _isLoading = false;
      _loadingController.add(false);
    }
  }

  /// Load items for a specific shipment
  Future<void> loadShipmentItems(int shipmentId) async {
    if (_isLoading) return;
    
    _isLoading = true;
    _loadingController.add(true);
    
    try {
      final items = await _shipmentService.getShipmentItems(shipmentId);
      _shipmentItemsController.add(items);
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error loading shipment items', e, stackTrace, 'ShipmentBloc');
      _shipmentItemsController.add([]);
      _errorController.add(AppError(
        message: 'Failed to load shipment items',
        error: e,
        stackTrace: stackTrace,
        source: 'ShipmentBloc'
      ));
    } finally {
      _isLoading = false;
      _loadingController.add(false);
    }
  }

  /// Create a new shipment
  Future<bool> createShipment(Shipment shipment) async {
    try {
      await _shipmentService.createShipment(shipment);
      await loadShipments(); // Refresh the list
      return true;
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error creating shipment', e, stackTrace, 'ShipmentBloc');
      _errorController.add(AppError(
        message: 'Failed to create shipment',
        error: e,
        stackTrace: stackTrace,
        source: 'ShipmentBloc'
      ));
      return false;
    }
  }

  /// Delete a shipment
  Future<bool> deleteShipment(int id) async {
    try {
      await _shipmentService.deleteShipment(id);
      await loadShipments(); // Refresh the list
      return true;
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error deleting shipment', e, stackTrace, 'ShipmentBloc');
      _errorController.add(AppError(
        message: 'Failed to delete shipment',
        error: e,
        stackTrace: stackTrace,
        source: 'ShipmentBloc'
      ));
      return false;
    }
  }

  /// Update shipment item expiration date
  Future<bool> updateShipmentItemExpiration(int shipmentItemId, DateTime? expirationDate) async {
    try {
      await _shipmentService.updateShipmentItemExpiration(shipmentItemId, expirationDate);
      // We need to know the shipment ID to refresh the items list
      // For simplicity, let's assume the parent shipment will reload the items
      return true;
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error updating shipment item expiration', e, stackTrace, 'ShipmentBloc');
      _errorController.add(AppError(
        message: 'Failed to update expiration date',
        error: e,
        stackTrace: stackTrace,
        source: 'ShipmentBloc'
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
    _shipmentsController.close();
    _shipmentItemsController.close();
    _loadingController.close();
    _errorController.close();
  }
}