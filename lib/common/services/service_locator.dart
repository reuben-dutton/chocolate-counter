import 'package:food_inventory/common/bloc/bloc_base.dart';
import 'package:food_inventory/data/factories/inventory_movement_factory.dart';
import 'package:food_inventory/data/factories/item_instance_factory.dart';
import 'package:food_inventory/data/repositories/inventory_movement_repository.dart';
import 'package:food_inventory/data/repositories/item_definition_repository.dart';
import 'package:food_inventory/data/repositories/item_instance_repository.dart';
import 'package:food_inventory/data/repositories/shipment_item_repository.dart';
import 'package:food_inventory/data/repositories/shipment_repository.dart';
import 'package:food_inventory/common/services/database_service.dart';
import 'package:food_inventory/common/services/dialog_service.dart';
import 'package:food_inventory/features/inventory/bloc/inventory_bloc.dart';
import 'package:food_inventory/features/inventory/services/image_service.dart';
import 'package:food_inventory/features/inventory/services/inventory_service.dart';
import 'package:food_inventory/common/services/preferences_service.dart';
import 'package:food_inventory/features/settings/bloc/preferences_bloc.dart';
import 'package:food_inventory/features/shipments/bloc/shipment_bloc.dart';
import 'package:food_inventory/features/shipments/services/shipment_service.dart';
import 'package:get_it/get_it.dart';

/// A service locator for managing dependency injection
class ServiceLocator {
  static final GetIt instance = GetIt.instance;
  
  /// Initialize all services, repositories, and BLoCs
  static Future<void> init() async {
    // Services
    final databaseService = DatabaseService();
    await databaseService.initialize();
    
    final preferencesService = PreferencesService();
    await preferencesService.initialize();
    
    // Register base services
    instance.registerSingleton<DatabaseService>(databaseService);
    instance.registerSingleton<PreferencesService>(preferencesService);
    instance.registerSingleton<DialogService>(DialogService());
    instance.registerSingleton<ImageService>(ImageService());
    
    // Register repositories
    instance.registerSingleton<ItemDefinitionRepository>(
      ItemDefinitionRepository(databaseService),
    );
    
    instance.registerSingleton<ItemInstanceRepository>(
      ItemInstanceRepository(
        databaseService,
        instance<ItemDefinitionRepository>(),
      ),
    );
    
    instance.registerSingleton<InventoryMovementRepository>(
      InventoryMovementRepository(
        databaseService,
        instance<ItemDefinitionRepository>(),
      ),
    );
    
    instance.registerSingleton<ShipmentItemRepository>(
      ShipmentItemRepository(
        databaseService,
        instance<ItemDefinitionRepository>(),
      ),
    );
    
    instance.registerSingleton<ShipmentRepository>(
      ShipmentRepository(
        databaseService,
        instance<ShipmentItemRepository>(),
      ),
    );
    
    // Register factory classes
    instance.registerSingleton<ItemInstanceFactory>(
      ItemInstanceFactory(
        instance<ItemInstanceRepository>(),
        instance<ItemDefinitionRepository>(),
      ),
    );
    
    instance.registerSingleton<InventoryMovementFactory>(
      InventoryMovementFactory(
        instance<InventoryMovementRepository>(),
      ),
    );
    
    // Register business services
    instance.registerSingleton<InventoryService>(
      InventoryService(
        instance<ItemDefinitionRepository>(),
        instance<ItemInstanceRepository>(),
        instance<InventoryMovementRepository>(),
      ),
    );
    
    instance.registerSingleton<ShipmentService>(
      ShipmentService(
        instance<ShipmentRepository>(),
        instance<ShipmentItemRepository>(),
        instance<ItemInstanceRepository>(),
        instance<InventoryService>(),
        instance<InventoryMovementFactory>(),
      ),
    );
    
    // Register BLoCs
    instance.registerSingleton<InventoryBloc>(
      InventoryBloc(instance<InventoryService>()),
    );
    
    instance.registerSingleton<ShipmentBloc>(
      ShipmentBloc(instance<ShipmentService>()),
    );
    
    instance.registerSingleton<PreferencesBloc>(
      PreferencesBloc(instance<PreferencesService>()),
    );
  }
}