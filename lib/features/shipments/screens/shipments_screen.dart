import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/common/utils/navigation_utils.dart';
import 'package:food_inventory/features/shipments/bloc/shipment_bloc.dart';
import 'package:food_inventory/features/shipments/screens/add_shipment_screen.dart';
import 'package:food_inventory/features/shipments/screens/shipment_detail_screen.dart';
import 'package:food_inventory/features/shipments/services/shipment_service.dart';
import 'package:food_inventory/features/shipments/widgets/shipment_list_item.dart';
import 'package:provider/provider.dart';

class ShipmentsScreen extends StatelessWidget {
  const ShipmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shipmentService = Provider.of<ShipmentService>(context, listen: false);
    
    return BlocProvider(
      create: (context) => ShipmentBloc(shipmentService)
        ..add(const InitializeShipmentsScreen()),
      child: BlocListener<ShipmentBloc, ShipmentState>(
        listenWhen: (previous, current) => current.error != null && previous.error != current.error,
        listener: (context, state) {
          if (state.error != null) {
            context.read<ShipmentBloc>().handleError(context, state.error!);
          }
        },
        child: Scaffold(
          body: _ShipmentsList(),
          floatingActionButton: FloatingActionButton(
            heroTag: 'addShipment',
            onPressed: () => _navigateToAddShipment(context),
            tooltip: 'Add Shipment',
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }

  void _navigateToAddShipment(BuildContext context) {
    NavigationUtils.navigateWithSlide(
      context,
      const AddShipmentScreen(),
    ).then((_) {
      context.read<ShipmentBloc>().add(const LoadShipments());
    });
  }
}

class _ShipmentsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShipmentBloc, ShipmentState>(
      buildWhen: (previous, current) => 
        (current is ShipmentLoading && previous is! ShipmentLoading) || 
        (current is ShipmentsLoaded && (previous is! ShipmentsLoaded || 
            previous.shipments != (current).shipments)),
      builder: (context, state) {
        if (state is ShipmentLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ShipmentsLoaded) {
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
            padding: const EdgeInsets.only(top: 8, bottom: 8, left: 4, right: 4),
            itemCount: shipments.length,
            itemBuilder: (context, index) {
              final shipment = shipments[index];
              return ShipmentListItem(
                shipment: shipment,
                onTap: () {
                  NavigationUtils.navigateWithSlide(
                    context,
                    ShipmentDetailScreen(shipment: shipment),
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
        
        // Fallback for initial state
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  void _navigateToAddShipment(BuildContext context) {
    NavigationUtils.navigateWithSlide(
      context,
      const AddShipmentScreen(),
    ).then((_) {
      context.read<ShipmentBloc>().add(const LoadShipments());
    });
  }
}