import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/common/services/error_handler.dart';
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
  @override
  void initState() {
    super.initState();
    // Load shipments when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShipmentBloc>().add(const LoadShipments());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ShipmentBloc, ShipmentState>(
      listenWhen: (previous, current) => current.error != null && previous.error != current.error,
      listener: (context, state) {
        if (state.error != null) {
          context.read<ShipmentBloc>().handleError(context, state.error!);
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Shipments'),
          ),
          body: _buildShipmentsList(context, state),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'addItemDefinition',
                onPressed: () => _navigateToAddItemDefinition(context),
                tooltip: 'Add Item',
                child: const Icon(Icons.add_box, size: 20),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: 'addShipment',
                onPressed: () => _navigateToAddShipment(context),
                tooltip: 'Add Shipment',
                child: const Icon(Icons.add),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShipmentsList(BuildContext context, ShipmentState state) {
    if (state.isLoading && state.shipments.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final shipments = state.shipments;
    
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
              onPressed: () => _navigateToAddShipment(context),
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
              context.read<ShipmentBloc>().add(const LoadShipments());
            });
          },
          onDelete: () async {
            try {
              context.read<ShipmentBloc>().add(DeleteShipment(shipment.id!));
              ErrorHandler.showSuccessSnackBar(context, 'Shipment deleted');
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
  }

  void _navigateToAddShipment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddShipmentScreen(),
      ),
    ).then((_) {
      context.read<ShipmentBloc>().add(const LoadShipments());
    });
  }

  void _navigateToAddItemDefinition(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddItemDefinitionScreen(),
      ),
    );
  }
}