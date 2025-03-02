import 'package:flutter/material.dart';
import 'package:food_inventory/models/shipment.dart';
import 'package:food_inventory/models/shipment_item.dart';
import 'package:food_inventory/services/image_service.dart';
import 'package:food_inventory/services/service_locator.dart';
import 'package:food_inventory/services/shipment_service.dart';
import 'package:food_inventory/widgets/confirm_dialog.dart';
import 'package:food_inventory/widgets/shipment_item_list.dart';
import 'package:provider/provider.dart';
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
  late ShipmentService _shipmentService;
  late ImageService _imageService;
  late Future<List<ShipmentItem>> _itemsFuture;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _shipmentService = Provider.of<ShipmentService>(context, listen: false);
    _imageService = ServiceLocator.instance<ImageService>();
    _loadItems();
  }

  void _loadItems() {
    _itemsFuture = _shipmentService.getShipmentItems(widget.shipment.id!);
  }

  Future<void> _updateItemExpirationDate(int shipmentItemId, DateTime? newExpirationDate) async {
    if (_isUpdating) return;
    
    setState(() {
      _isUpdating = true;
    });
    
    try {
      // Update both the shipment item and linked inventory items
      await _shipmentService.updateShipmentItemExpiration(shipmentItemId, newExpirationDate);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expiration date updated successfully')),
      );
      
      // Refresh the list
      setState(() {
        _loadItems();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating expiration date: $e')),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
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
      body: _isUpdating 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                    FutureBuilder<List<ShipmentItem>>(
                      future: _itemsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        }

                        final items = snapshot.data ?? [];
                        
                        if (items.isEmpty) {
                          return const Card(
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Text('No items in this shipment.'),
                            ),
                          );
                        }

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
                                ShipmentItemList(
                                  items: items,
                                  onExpirationDateChanged: _updateItemExpirationDate,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
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
      await _shipmentService.deleteShipment(widget.shipment.id!);
      Navigator.pop(context);
    }
  }
}