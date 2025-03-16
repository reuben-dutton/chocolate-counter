import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/common/services/dialog_service.dart';
import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/data/models/shipment.dart';
import 'package:food_inventory/data/models/shipment_item.dart';
import 'package:food_inventory/features/shipments/bloc/shipment_bloc.dart';
import 'package:food_inventory/features/shipments/services/shipment_service.dart';
import 'package:food_inventory/features/shipments/widgets/shipment_item_list.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ShipmentDetailScreen extends StatefulWidget {
  final Shipment shipment;

  const ShipmentDetailScreen({
    super.key,
    required this.shipment,
  });

  @override
  _ShipmentDetailScreenState createState() => _ShipmentDetailScreenState();
}

class _ShipmentDetailScreenState extends State<ShipmentDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final shipmentService = Provider.of<ShipmentService>(context, listen: false);
    
    return BlocProvider(
      create: (context) => ShipmentBloc(shipmentService)
        ..add(LoadShipmentItems(widget.shipment.id!)),
      child: BlocConsumer<ShipmentBloc, ShipmentState>(
        listenWhen: (previous, current) => 
          current.error != null && previous.error != current.error ||
          current is OperationResult,
        listener: (context, state) {
          if (state.error != null) {
            context.read<ShipmentBloc>().handleError(context, state.error!);
          }
          
          if (state is OperationResult && state.success) {
            // If it was a deletion operation, navigate back
            if (state.operationType == OperationType.delete) {
              Navigator.pop(context);
            }
            
            // Clear the operation state
            context.read<ShipmentBloc>().add(const ClearOperationState());
          }
        },
        builder: (context, state) {
          final formattedDate = DateFormat('yyyy-MM-dd').format(widget.shipment.date);
          final theme = Theme.of(context);
          
          return Scaffold(
            appBar: AppBar(
              title: Text(
                widget.shipment.name ?? 'Shipment Details',
                style: const TextStyle(fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: () => _deleteShipment(context),
                ),
              ],
            ),
            body: state is ShipmentLoading && state is! ShipmentItemsLoaded
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(context, state, formattedDate, theme),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, ShipmentState state, String formattedDate, ThemeData theme) {
    List<dynamic> items = [];
    
    if (state is ShipmentItemsLoaded) {
      items = state.shipmentItems;
    }
    
    // Calculate the total cost of the shipment
    double totalCost = _calculateShipmentTotal(items);
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shipment info
            Card(
              color: theme.colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Shipment Information',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14),
                        const SizedBox(width: 8),
                        Text(
                          'Date: $formattedDate',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    if (widget.shipment.name != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.label, size: 14),
                          const SizedBox(width: 8),
                          Text(
                            'Name: ${widget.shipment.name}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                    // Add total cost row
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.monetization_on, size: 14),
                        const SizedBox(width: 8),
                        Text(
                          'Total Cost: ${ConfigService.formatCurrency(totalCost)}',
                          style: const TextStyle(
                            fontSize: 14, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Items list
            _ShipmentItemsList(shipmentId: widget.shipment.id!, items: items),
          ],
        ),
      ),
    );
  }

  // Calculate total cost of shipment
  double _calculateShipmentTotal(List<dynamic> items) {
    double total = 0.0;
    for (var item in items) {
      if (item is ShipmentItem && item.unitPrice != null) {
        total += item.unitPrice! * item.quantity;
      }
    }
    return total;
  }

  void _deleteShipment(BuildContext context) async {
    try {
      // Use bottom sheet confirmation instead of dialog
      final dialogService = Provider.of<DialogService>(context, listen: false);
      final confirm = await dialogService.showConfirmBottomSheet(
        context: context,
        title: 'Delete Shipment',
        content: 'Are you sure you want to delete this shipment? This action cannot be undone, but inventory counts will not be affected.',
        icon: Icons.delete_forever,
      );

      if (confirm == true) {
        context.read<ShipmentBloc>().add(DeleteShipment(widget.shipment.id!));
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
  }
}

class _ShipmentItemsList extends StatelessWidget {
  final int shipmentId;
  final List<dynamic> items;
  
  const _ShipmentItemsList({
    required this.shipmentId,
    required this.items,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.inventory_2, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Items (${items.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14),
                    ),
                  ],
                ),
                Tooltip(
                  message: 'Tap the calendar icon to edit expiration dates',
                  child: Row(
                    children: [
                      const Icon(Icons.edit_calendar, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Edit dates', 
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.primary
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('No items in this shipment.'),
              )
            else
              ShipmentItemList(
                items: items,
                onExpirationDateChanged: (shipmentItemId, newExpirationDate) => _updateItemExpirationDate(context, shipmentItemId, newExpirationDate),
              ),
          ],
        ),
      ),
    );
  }
  
  void _updateItemExpirationDate(BuildContext context, int shipmentItemId, DateTime? newExpirationDate) {
    // Use the combined update+refresh event
    BlocProvider.of<ShipmentBloc>(context).add(
      UpdateShipmentItemExpiration(
        shipmentItemId: shipmentItemId,
        expirationDate: newExpirationDate,
        shipmentId: shipmentId,
      )
    );
  }
}