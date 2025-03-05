import 'dart:async';

import 'package:food_inventory/common/bloc/bloc_base.dart';
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

  // Keep track of last loaded shipment ID
  int? _lastLoadedShipmentId;

  ShipmentBloc(this._shipmentService);

  /// Load all shipments
  Future<void> loadShipments() async {
    if (_isLoading) return;
    
    _isLoading = true;
    _loadingController.add(true);
    
    try {
      final shipmentList = await _shipmentService.getAllShipments();
      _shipmentsController.add(shipmentList);
    } catch (e) {
      print('Error loading shipments: $e');
      _shipmentsController.add([]);
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
    _lastLoadedShipmentId = shipmentId;
    
    try {
      final items = await _shipmentService.getShipmentItems(shipmentId);
      _shipmentItemsController.add(items);
    } catch (e) {
      print('Error loading shipment items: $e');
      _shipmentItemsController.add([]);
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
    } catch (e) {
      print('Error creating shipment: $e');
      return false;
    }
  }

  /// Delete a shipment
  Future<bool> deleteShipment(int id) async {
    try {
      await _shipmentService.deleteShipment(id);
      await loadShipments(); // Refresh the list
      return true;
    } catch (e) {
      print('Error deleting shipment: $e');
      return false;
    }
  }

  /// Update shipment item expiration date
  Future<bool> updateShipmentItemExpiration(int shipmentItemId, DateTime? expirationDate) async {
    try {
      await _shipmentService.updateShipmentItemExpiration(shipmentItemId, expirationDate);
      
      // Refresh the items list if we have a shipment ID
      if (_lastLoadedShipmentId != null) {
        await loadShipmentItems(_lastLoadedShipmentId!);
      }
      
      return true;
    } catch (e) {
      print('Error updating shipment item expiration: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _shipmentsController.close();
    _shipmentItemsController.close();
    _loadingController.close();
  }
}