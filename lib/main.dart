import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/app.dart';
import 'package:food_inventory/common/services/service_locator.dart';
import 'package:food_inventory/utils/bloc_observer.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services and repositories
  await ServiceLocator.init();
  
  // Set up the BLoC observer for debugging
  Bloc.observer = AppBlocObserver();
  
  // Run the app
  runApp(const FoodInventoryApp());
}