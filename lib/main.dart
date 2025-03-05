import 'package:flutter/material.dart';
import 'package:food_inventory/app.dart';
import 'package:food_inventory/common/services/service_locator.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services and BLoCs
  await ServiceLocator.init();
  
  // Run the app
  runApp(const FoodInventoryApp());
}