import 'package:food_inventory/factories/inventory_movement_factory.dart';
import 'package:food_inventory/factories/item_instance_factory.dart';
import 'package:food_inventory/repositories/inventory_movement_repository.dart';
import 'package:food_inventory/repositories/item_definition_repository.dart';
import 'package:food_inventory/repositories/item_instance_repository.dart';
import 'package:food_inventory/repositories/shipment_item_repository.dart';
import 'package:food_inventory/repositories/shipment_repository.dart';
import 'package:food_inventory/services/database_service.dart';
import 'package:food_inventory/services/dialog_service.dart';
import 'package:food_inventory/services/error_handler.dart';
import 'package:food_inventory/services/image_service.dart';
import 'package:food_inventory/services/inventory_service.dart';
import 'package:food_inventory/services/preferences_service.dart';
import 'package:food_inventory/services/shipment_service.dart';
import 'package:get_it/get_it.dart';

/// A service locator for managing dependency injection
class ServiceLocator {
  static final GetIt instance = GetIt.instance;
  
  /// Initialize all services and repositories
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
      ),
    );
  }
}