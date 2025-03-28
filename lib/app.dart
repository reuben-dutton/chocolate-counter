// Update to lib/app.dart to add the Export screen
import 'package:flutter/material.dart';
import 'package:food_inventory/features/shipments/services/shipment_service.dart';
import 'package:provider/provider.dart';
import 'package:food_inventory/common/screens/home_screen.dart';
import 'package:food_inventory/common/services/dialog_service.dart';
import 'package:food_inventory/common/services/service_locator.dart';
import 'package:food_inventory/common/services/preferences_service.dart';
import 'package:food_inventory/common/services/database_service.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/features/inventory/services/image_service.dart';
import 'package:food_inventory/features/inventory/services/inventory_service.dart';
import 'package:food_inventory/features/analytics/repositories/analytics_repository.dart';
import 'package:food_inventory/features/analytics/services/analytics_service.dart';
import 'package:food_inventory/features/inventory/event_bus/inventory_event_bus.dart';
import 'package:food_inventory/features/settings/bloc/preferences_bloc.dart';
import 'package:food_inventory/theme/material_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/data/repositories/inventory_movement_repository.dart';
import 'package:food_inventory/data/repositories/item_definition_repository.dart';
import 'package:food_inventory/data/repositories/item_instance_repository.dart';
import 'package:food_inventory/data/repositories/shipment_repository.dart';
import 'package:food_inventory/data/repositories/shipment_item_repository.dart';

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
    final databaseService = ServiceLocator.instance<DatabaseService>();
    final configService = ServiceLocator.instance<ConfigService>();
    final inventoryEventBus = ServiceLocator.instance<InventoryEventBus>();
    
    // Get repositories from service locator
    final itemDefinitionRepository = ServiceLocator.instance<ItemDefinitionRepository>();
    final itemInstanceRepository = ServiceLocator.instance<ItemInstanceRepository>();
    final inventoryMovementRepository = ServiceLocator.instance<InventoryMovementRepository>();
    final shipmentRepository = ServiceLocator.instance<ShipmentRepository>();
    final shipmentItemRepository = ServiceLocator.instance<ShipmentItemRepository>();
    
    // Create analytics repository
    final analyticsRepository = AnalyticsRepository(databaseService);
    
    // Theme
    final theme = MaterialTheme(Theme.of(context).textTheme);
    
    return MultiProvider(
      providers: [
        // Services
        ChangeNotifierProvider<PreferencesService>.value(
          value: preferencesService,
        ),
        ChangeNotifierProvider<ConfigService>.value(
          value: configService,
        ),
        Provider<ImageService>.value(value: imageService),
        Provider<DialogService>.value(value: dialogService),
        Provider<InventoryService>.value(value: inventoryService),
        Provider<ShipmentService>.value(value: shipmentService),
        Provider<DatabaseService>.value(value: databaseService),
        Provider<InventoryEventBus>.value(value: inventoryEventBus),
        
        // Repositories
        Provider<ItemDefinitionRepository>.value(value: itemDefinitionRepository),
        Provider<ItemInstanceRepository>.value(value: itemInstanceRepository),
        Provider<InventoryMovementRepository>.value(value: inventoryMovementRepository),
        Provider<ShipmentRepository>.value(value: shipmentRepository),
        Provider<ShipmentItemRepository>.value(value: shipmentItemRepository),
        
        // Analytics providers
        Provider<AnalyticsRepository>.value(value: analyticsRepository),
        ProxyProvider<AnalyticsRepository, AnalyticsService>(
          update: (context, repository, _) => AnalyticsService(repository),
        ),

        // Only keep the PreferencesBloc at app-level since it affects the entire app theme
        BlocProvider<PreferencesBloc>(
          create: (context) => PreferencesBloc(preferencesService, configService),
        ),
      ],
      child: BlocBuilder<PreferencesBloc, PreferencesState>(
        buildWhen: (previous, current) => 
          previous.themeMode != current.themeMode || 
          previous.themeType != current.themeType ||
          previous.hardwareAcceleration != current.hardwareAcceleration,
        builder: (context, state) {
          final themeMode = state.themeMode;
          final themeType = state.themeType;
          
          return MaterialApp(
            title: ConfigService.appName,
            theme: theme.light(themeType),
            darkTheme: theme.dark(themeType),
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