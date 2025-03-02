import 'package:flutter/material.dart';
import 'package:food_inventory/app.dart';
import 'package:food_inventory/services/database_service.dart';
import 'package:food_inventory/services/preferences_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  final databaseService = DatabaseService();
  await databaseService.initialize();
  
  final preferencesService = PreferencesService();
  await preferencesService.initialize();
  
  runApp(FoodInventoryApp(
    databaseService: databaseService,
    preferencesService: preferencesService,
  ));
}