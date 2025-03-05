import 'package:flutter/material.dart';
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
  List<ShipmentItem> _currentItems = []; // Track current items

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _shipmentBloc = ServiceLocator.instance<ShipmentBloc>();
      _loadItems();
      _initialized = true;
      
      // Subscribe to shipment items updates
      _shipmentBloc.shipmentItems.listen((items) {
        print('ShipmentDetailScreen: Received ${items.length} items from bloc');
        setState(() {
          _currentItems = items;
        });
      });
    }
  }

  void _loadItems() {
    print('ShipmentDetailScreen: Loading items for shipment ${widget.shipment.id}');
    _shipmentBloc.loadShipmentItems(widget.shipment.id!);
  }

  Future<void> _updateItemExpirationDate(int shipmentItemId, DateTime? newExpirationDate) async {
    print('ShipmentDetailScreen: Updating expiration date for item $shipmentItemId to $newExpirationDate');
    
    final success = await _shipmentBloc.updateShipmentItemExpiration(
      shipmentItemId, 
      newExpirationDate
    );
    
    if (success) {
      print('ShipmentDetailScreen: Update succeeded, reloading items');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expiration date updated successfully')),
      );
    } else {
      print('ShipmentDetailScreen: Update failed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating expiration date')),
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
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                print('ShipmentDetailScreen: Manual refresh triggered');
                _loadItems();
              },
              child: StreamBuilder<bool>(
                stream: _shipmentBloc.isLoading,
                builder: (context, loadingSnapshot) {
                  final isLoading = loadingSnapshot.data ?? false;
                  
                  if (isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
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
                          
                          // Items list - using local state instead of stream
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
                                            'Items (${_currentItems.length})',
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
                                  if (_currentItems.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text('No items in this shipment.'),
                                    )
                                  else
                                    ShipmentItemList(
                                      items: _currentItems,
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
              ),
            ),
          ),
          
          // Debug button to force refresh
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                print('ShipmentDetailScreen: Force refresh button pressed');
                _loadItems();
                setState(() {}); // Force rebuild
              },
              child: const Text('Force Refresh (Debug)'),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteShipment() async {
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete shipment')),
        );
      }
    }
  }
}