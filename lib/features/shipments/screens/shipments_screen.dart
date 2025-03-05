import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/common/services/service_locator.dart';
import 'package:food_inventory/data/models/shipment.dart';
import 'package:food_inventory/features/inventory/screens/add_item_definition_screen.dart';
import 'package:food_inventory/features/shipments/bloc/shipment_bloc.dart';
import 'package:food_inventory/features/shipments/screens/add_shipment_screen.dart';
import 'package:food_inventory/features/shipments/screens/shipment_detail_screen.dart';
import 'package:food_inventory/features/shipments/widgets/shipment_list_item.dart';

class ShipmentsScreen extends StatefulWidget {
  const ShipmentsScreen({super.key});

  @override
  _ShipmentsScreenState createState() => _ShipmentsScreenState();
}

class _ShipmentsScreenState extends State<ShipmentsScreen> {
  late ShipmentBloc _shipmentBloc;

  @override
  void initState() {
    super.initState();
    _shipmentBloc = ServiceLocator.instance<ShipmentBloc>();
    
    // Listen for errors
    _shipmentBloc.errors.listen((error) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, error.message, error: error.error);
      }
    });
    
    _loadShipments();
  }

  void _loadShipments() {
    _shipmentBloc.loadShipments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shipments'),
      ),
      body: StreamBuilder<List<Shipment>>(
        stream: _shipmentBloc.shipments,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final shipments = snapshot.data ?? [];
          
          if (shipments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No shipments found'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Shipment'),
                    onPressed: () => _navigateToAddShipment(),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: shipments.length,
            itemBuilder: (context, index) {
              final shipment = shipments[index];
              return ShipmentListItem(
                shipment: shipment,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ShipmentDetailScreen(shipment: shipment),
                    ),
                  ).then((_) {
                    // Refresh data when returning from details
                    _loadShipments();
                  });
                },
                onDelete: () async {
                  try {
                    final success = await _shipmentBloc.deleteShipment(shipment.id!);
                    if (success) {
                      ErrorHandler.showSuccessSnackBar(context, 'Shipment deleted');
                    } else {
                      ErrorHandler.showErrorSnackBar(context, 'Failed to delete shipment');
                    }
                  } catch (e, stackTrace) {
                    ErrorHandler.handleServiceError(
                      context, 
                      e,
                      service: 'Shipment',
                      operation: 'deletion',
                      stackTrace: stackTrace
                    );
                  }
                },
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'addItemDefinition',
            onPressed: () => _navigateToAddItemDefinition(),
            tooltip: 'Add Item',
            child: const Icon(Icons.add_box, size: 20),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'addShipment',
            onPressed: () => _navigateToAddShipment(),
            tooltip: 'Add Shipment',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  void _navigateToAddShipment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddShipmentScreen(),
      ),
    ).then((_) {
      _loadShipments();
    });
  }

  void _navigateToAddItemDefinition() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddItemDefinitionScreen(),
      ),
    );
  }
}