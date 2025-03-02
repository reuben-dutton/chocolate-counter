import 'package:flutter/material.dart';
import 'package:food_inventory/screens/home_screen.dart';
import 'package:food_inventory/services/database_service.dart';
import 'package:food_inventory/services/dialog_service.dart';
import 'package:food_inventory/services/inventory_service.dart';
import 'package:food_inventory/services/preferences_service.dart';
import 'package:food_inventory/services/service_locator.dart';
import 'package:food_inventory/services/shipment_service.dart';
import 'package:food_inventory/theme.dart';
import 'package:provider/provider.dart';

class FoodInventoryApp extends StatelessWidget {
  const FoodInventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Get services from service locator
    final databaseService = ServiceLocator.instance<DatabaseService>();
    final preferencesService = ServiceLocator.instance<PreferencesService>();
    final inventoryService = ServiceLocator.instance<InventoryService>();
    final shipmentService = ServiceLocator.instance<ShipmentService>();
    final dialogService = ServiceLocator.instance<DialogService>();

    final theme = MaterialTheme(Theme.of(context).textTheme);
    
    return MultiProvider(
      providers: [
        Provider<DatabaseService>.value(value: databaseService),
        ChangeNotifierProvider<PreferencesService>.value(value: preferencesService),
        Provider<InventoryService>.value(value: inventoryService),
        Provider<ShipmentService>.value(value: shipmentService),
        Provider<DialogService>.value(value: dialogService),
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