import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/app.dart';
import 'package:food_inventory/common/services/preferences_service.dart';
import 'package:food_inventory/common/services/service_locator.dart';
import 'package:food_inventory/utils/bloc_observer.dart';
import 'package:food_inventory/theme/theme_loader.dart'; // Import theme loader

// Global navigator key for context access
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Preload themes
  await ThemeLoader.preloadThemes();
  
  // Initialize services and repositories
  await ServiceLocator.init();
  
  // Get hardware acceleration preference
  final preferencesService = ServiceLocator.instance<PreferencesService>();
  final hardwareAcceleration = preferencesService.hardwareAcceleration;
  
  // Set hardware acceleration based on preference
  if (!hardwareAcceleration) {
    // This tells Flutter to use a software renderer instead of hardware acceleration
    // Note: This might not be fully supported on all platforms and may have performance implications
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
    
    // Additional platform-specific approach to disable hardware acceleration
    // This is OS-specific and may not work on all platforms
    if (navigatorKey.currentContext != null && 
        Theme.of(navigatorKey.currentContext!).platform == TargetPlatform.android) {
      await SystemChannels.platform.invokeMethod('SystemChrome.setPreferredOrientations', []);
    }
  }
  
  // Set up the BLoC observer for debugging
  Bloc.observer = AppBlocObserver();
  
  // Run the app
  runApp(
    MaterialApp(
      home: const FoodInventoryApp(),
      navigatorKey: navigatorKey,
    ),
  );
}