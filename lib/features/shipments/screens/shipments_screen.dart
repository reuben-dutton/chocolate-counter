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

class ShipmentsScreen extends StatefulWidget {
  const ShipmentsScreen({super.key});

  @override
  State<ShipmentsScreen> createState() => _ShipmentsScreenState();
}

class _ShipmentsScreenState extends State<ShipmentsScreen> {
  late ShipmentBloc _shipmentBloc;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize the bloc in didChangeDependencies to ensure context is ready
    final shipmentService = Provider.of<ShipmentService>(context, listen: false);
    _shipmentBloc = ShipmentBloc(shipmentService);
    _shipmentBloc.add(const InitializeShipmentsScreen());
  }

  @override
  void dispose() {
    _shipmentBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ShipmentBloc>.value(
      value: _shipmentBloc,
      child: BlocListener<ShipmentBloc, ShipmentState>(
        listenWhen: (previous, current) => 
          current.error != null && previous.error != current.error ||
          (current is OperationResult && current.success),
        listener: (context, state) {
          if (state.error != null) {
            _shipmentBloc.handleError(context, state.error!);
          }
          
          // Refresh the list when an operation is successful
          if (state is OperationResult && state.success) {
            _shipmentBloc.add(const LoadShipments());
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
    ).then((result) {
      // Always force a refresh when returning from add shipment screen
      _shipmentBloc.add(const LoadShipments());
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
                    onPressed: () {
                      NavigationUtils.navigateWithSlide(
                        context,
                        const AddShipmentScreen(),
                      ).then((_) {
                        // Refresh data when returning from add screen
                        context.read<ShipmentBloc>().add(const LoadShipments());
                      });
                    },
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<ShipmentBloc>().add(const LoadShipments());
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 0, bottom: 8, left: 4, right: 4),
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
            ),
          );
        }
        
        // Fallback for initial state
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}