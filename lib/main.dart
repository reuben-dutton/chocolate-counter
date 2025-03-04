import 'package:flutter/material.dart';
import 'package:food_inventory/app.dart';
import 'package:food_inventory/common/services/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await ServiceLocator.init();
  
  runApp(const FoodInventoryApp());
}