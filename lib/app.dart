import 'package:flutter/material.dart';
import 'package:food_inventory/theme.dart';
import 'package:food_inventory/screens/home_screen.dart';
import 'package:food_inventory/services/database_service.dart';
import 'package:food_inventory/services/inventory_service.dart';
import 'package:food_inventory/services/preferences_service.dart';
import 'package:food_inventory/services/shipment_service.dart';
import 'package:provider/provider.dart';

class FoodInventoryApp extends StatelessWidget {
  final DatabaseService databaseService;
  final PreferencesService preferencesService;

  const FoodInventoryApp({
    super.key,
    required this.databaseService,
    required this.preferencesService,
  });

  @override
  Widget build(BuildContext context) {
    // Create services
    final inventoryService = InventoryService(databaseService);
    final shipmentService = ShipmentService(databaseService, inventoryService);

    final theme = MaterialTheme(Theme.of(context).textTheme);
    
    return MultiProvider(
      providers: [
        Provider<DatabaseService>.value(value: databaseService),
        ChangeNotifierProvider<PreferencesService>.value(value: preferencesService),
        Provider<InventoryService>.value(value: inventoryService),
        Provider<ShipmentService>.value(value: shipmentService),
      ],
      child: Consumer<PreferencesService>(
        builder: (context, preferences, _) {
          return MaterialApp(
            title: 'Food Inventory',
            theme: theme.light(),
            darkTheme: theme.dark(),
            themeMode: preferences.themeMode,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}