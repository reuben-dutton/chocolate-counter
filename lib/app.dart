import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/common/screens/home_screen.dart';
import 'package:food_inventory/common/services/dialog_service.dart';
import 'package:food_inventory/common/services/service_locator.dart';
import 'package:food_inventory/common/services/preferences_service.dart';
import 'package:food_inventory/features/inventory/bloc/inventory_bloc.dart';
import 'package:food_inventory/features/inventory/services/image_service.dart';
import 'package:food_inventory/features/inventory/services/inventory_service.dart';
import 'package:food_inventory/features/settings/bloc/preferences_bloc.dart';
import 'package:food_inventory/features/shipments/bloc/shipment_bloc.dart';
import 'package:food_inventory/features/shipments/services/shipment_service.dart';
import 'package:food_inventory/theme.dart';
import 'package:provider/provider.dart';

class FoodInventoryApp extends StatelessWidget {
  const FoodInventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Get services from service locator
    final imageService = ServiceLocator.instance<ImageService>();
    final dialogService = ServiceLocator.instance<DialogService>();
    final inventoryService = ServiceLocator.instance<InventoryService>();
    final shipmentService = ServiceLocator.instance<ShipmentService>();
    
    // Theme
    final theme = MaterialTheme(Theme.of(context).textTheme);
    
    return MultiProvider(
      providers: [
        // Services
        Provider<ImageService>.value(value: imageService),
        Provider<DialogService>.value(value: dialogService),
        Provider<InventoryService>.value(value: inventoryService),
        Provider<ShipmentService>.value(value: shipmentService),

        // BLoCs
        BlocProvider<PreferencesBloc>(
          create: (context) => PreferencesBloc(ServiceLocator.instance<PreferencesService>()),
        ),
        BlocProvider<InventoryBloc>(
          create: (context) => InventoryBloc(context.read<InventoryService>()),
        ),
        BlocProvider<ShipmentBloc>(
          create: (context) => ShipmentBloc(context.read<ShipmentService>()),
        ),
      ],
      child: BlocBuilder<PreferencesBloc, PreferencesState>(
        builder: (context, state) {
          final themeMode = state.themeMode;
          
          return MaterialApp(
            title: 'Food Inventory',
            theme: theme.light(),
            darkTheme: theme.dark(),
            themeMode: themeMode,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}