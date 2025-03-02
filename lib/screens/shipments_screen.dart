import 'package:flutter/material.dart';
import 'package:food_inventory/models/shipment.dart';
import 'package:food_inventory/screens/add_item_definition_screen.dart';
import 'package:food_inventory/screens/add_shipment_screen.dart';
import 'package:food_inventory/screens/shipment_detail_screen.dart';
import 'package:food_inventory/services/shipment_service.dart';
import 'package:food_inventory/widgets/shipment_list_item.dart';
import 'package:provider/provider.dart';

class ShipmentsScreen extends StatefulWidget {
  const ShipmentsScreen({super.key});

  @override
  _ShipmentsScreenState createState() => _ShipmentsScreenState();
}

class _ShipmentsScreenState extends State<ShipmentsScreen> {
  late ShipmentService _shipmentService;
  late Future<List<Shipment>> _shipmentsFuture;

  @override
  void initState() {
    super.initState();
    _shipmentService = Provider.of<ShipmentService>(context, listen: false);
    _loadShipments();
  }

  void _loadShipments() {
    _shipmentsFuture = _shipmentService.getAllShipments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shipments'),
      ),
      body: FutureBuilder<List<Shipment>>(
        future: _shipmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
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
                    setState(() {
                      _loadShipments();
                    });
                  });
                },
                onDelete: () async {
                  await _shipmentService.deleteShipment(shipment.id!);
                  setState(() {
                    _loadShipments();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Shipment deleted')),
                  );
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
      setState(() {
        _loadShipments();
      });
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