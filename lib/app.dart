import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:food_inventory/common/screens/home_screen.dart';
import 'package:food_inventory/common/services/dialog_service.dart';
import 'package:food_inventory/common/services/service_locator.dart';
import 'package:food_inventory/common/services/preferences_service.dart';
import 'package:food_inventory/features/inventory/services/image_service.dart';
import 'package:food_inventory/features/inventory/services/inventory_service.dart';
import 'package:food_inventory/features/settings/bloc/preferences_bloc.dart';
import 'package:food_inventory/features/shipments/services/shipment_service.dart';
import 'package:food_inventory/theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FoodInventoryApp extends StatelessWidget {
  const FoodInventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Get services from service locator
    final imageService = ServiceLocator.instance<ImageService>();
    final dialogService = ServiceLocator.instance<DialogService>();
    final inventoryService = ServiceLocator.instance<InventoryService>();
    final shipmentService = ServiceLocator.instance<ShipmentService>();
    final preferencesService = ServiceLocator.instance<PreferencesService>();
    
    // Theme
    final theme = MaterialTheme(Theme.of(context).textTheme);
    
    return MultiProvider(
      providers: [

        ChangeNotifierProvider<PreferencesService>.value(
          value: preferencesService,
        ),
        // Services
        Provider<ImageService>.value(value: imageService),
        Provider<DialogService>.value(value: dialogService),
        Provider<InventoryService>.value(value: inventoryService),
        Provider<ShipmentService>.value(value: shipmentService),

        // Only keep the PreferencesBloc at app-level since it affects the entire app theme
        BlocProvider<PreferencesBloc>(
          create: (context) => PreferencesBloc(preferencesService),
        ),
      ],
      child: BlocBuilder<PreferencesBloc, PreferencesState>(
        buildWhen: (previous, current) => 
          previous.themeMode != current.themeMode || 
          previous.hardwareAcceleration != current.hardwareAcceleration,
        builder: (context, state) {
          final themeMode = state.themeMode;
          
          return MaterialApp(
            title: 'Food Inventory',
            theme: theme.light(),
            darkTheme: theme.dark(),
            themeMode: themeMode,
            home: const HomeScreen(),
            // Set the disableHardwareAcceleration flag based on preferences
            builder: (context, child) {
              if (child == null) return const SizedBox.shrink();
              
              // Apply hardware acceleration setting
              return MediaQuery(
                // This is where we would disable hardware acceleration if Flutter supported it
                // For now, we'll just pass through the data since Flutter doesn't have a direct way 
                // to toggle hardware acceleration at runtime
                data: MediaQuery.of(context),
                child: child,
              );
            },
          );
        },
      ),
    );
  }
}