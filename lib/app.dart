import 'package:flutter/material.dart';
import 'package:food_inventory/common/screens/home_screen.dart';
import 'package:food_inventory/common/services/dialog_service.dart';
import 'package:food_inventory/common/services/service_locator.dart';
import 'package:food_inventory/features/inventory/services/image_service.dart';
import 'package:food_inventory/features/settings/bloc/preferences_bloc.dart';
import 'package:food_inventory/theme.dart';
import 'package:provider/provider.dart';

class FoodInventoryApp extends StatelessWidget {
  const FoodInventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Get services and blocs from service locator
    final preferencesBloc = ServiceLocator.instance<PreferencesBloc>();
    final imageService = ServiceLocator.instance<ImageService>();
    final dialogService = ServiceLocator.instance<DialogService>();
    
    // Theme
    final theme = MaterialTheme(Theme.of(context).textTheme);
    
    return MultiProvider(
      providers: [
        Provider<ImageService>.value(value: imageService),
        Provider<DialogService>.value(value: dialogService),
      ],
      child: StreamBuilder<ThemeMode>(
        stream: preferencesBloc.themeMode,
        initialData: ThemeMode.system,
        builder: (context, snapshot) {
          final themeMode = snapshot.data ?? ThemeMode.system;
          
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