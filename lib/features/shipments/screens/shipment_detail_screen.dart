import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/common/services/service_locator.dart';
import 'package:food_inventory/data/models/shipment.dart';
import 'package:food_inventory/data/models/shipment_item.dart';
import 'package:food_inventory/features/settings/widgets/confirm_dialog.dart';
import 'package:food_inventory/features/shipments/bloc/shipment_bloc.dart';
import 'package:food_inventory/features/shipments/widgets/shipment_item_list.dart';
import 'package:intl/intl.dart';

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
  late ShipmentBloc _shipmentBloc;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _shipmentBloc = ServiceLocator.instance<ShipmentBloc>();
      _loadItems();
      
      // Listen for errors
      _shipmentBloc.errors.listen((error) {
        if (mounted) {
          ErrorHandler.showErrorSnackBar(context, error.message, error: error.error);
        }
      });
      
      _initialized = true;
    }
  }

  void _loadItems() {
    _shipmentBloc.loadShipmentItems(widget.shipment.id!);
  }

  Future<void> _updateItemExpirationDate(int shipmentItemId, DateTime? newExpirationDate) async {
    try {
      final success = await _shipmentBloc.updateShipmentItemExpiration(
        shipmentItemId, 
        newExpirationDate
      );
      
      if (success) {
        ErrorHandler.showSuccessSnackBar(context, 'Expiration date updated successfully');
        
        // Refresh the list
        _loadItems();
      } else {
        ErrorHandler.showErrorSnackBar(context, 'Error updating expiration date');
      }
    } catch (e, stackTrace) {
      ErrorHandler.handleServiceError(
        context, 
        e, 
        service: 'Shipment',
        operation: 'updating expiration date',
        stackTrace: stackTrace
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: () => _deleteShipment(),
          ),
        ],
      ),
      body: StreamBuilder<bool>(
        stream: _shipmentBloc.isLoading,
        builder: (context, loadingSnapshot) {
          final isLoading = loadingSnapshot.data ?? false;
          
          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return StreamBuilder<List<ShipmentItem>>(
            stream: _shipmentBloc.shipmentItems,
            builder: (context, snapshot) {
              final items = snapshot.data ?? [];
              
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
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Items list
                      Card(
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
                                        Text('Edit dates', style: TextStyle(
                                          fontSize: 12,
                                          color: theme.colorScheme.primary
                                        )),
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
                                  onExpirationDateChanged: _updateItemExpirationDate,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _deleteShipment() async {
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => ConfirmDialog(
          title: 'Delete Shipment',
          content: 'Are you sure you want to delete this shipment? This action cannot be undone, but inventory counts will not be affected.',
          icon: Icons.delete_forever,
        ),
      );

      if (confirm == true) {
        final success = await _shipmentBloc.deleteShipment(widget.shipment.id!);
        if (success) {
          Navigator.pop(context);
        } else {
          ErrorHandler.showErrorSnackBar(context, 'Failed to delete shipment');
        }
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