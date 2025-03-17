import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/common/services/database_service.dart';
import 'package:food_inventory/common/services/dialog_service.dart';
import 'package:food_inventory/common/services/service_locator.dart';
import 'package:food_inventory/features/settings/bloc/preferences_bloc.dart';
import 'package:food_inventory/features/settings/widgets/database_reset_bottom_sheet.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  
  // Define fixed padding values for the settings screen that won't change with density
  static const double _fixedDefaultPadding = 16.0;
  static const double _fixedSmallPadding = 8.0;
  static const double _fixedTinyPadding = 4.0;
  static const double _fixedMediumPadding = 12.0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreferencesBloc, PreferencesState>(
      buildWhen: (previous, current) => 
        previous.themeMode != current.themeMode || 
        previous.hardwareAcceleration != current.hardwareAcceleration ||
        previous.compactUiDensity != current.compactUiDensity,
      builder: (context, state) {
        return Scaffold(
          body: ListView(
            padding: const EdgeInsets.only(
              top: 0, 
              bottom: _fixedSmallPadding, 
              left: _fixedTinyPadding, 
              right: _fixedTinyPadding
            ),
            children: [
              ListTile(
                leading: const Icon(Icons.palette, size: ConfigService.defaultIconSize),
                title: const Text('Theme'),
                subtitle: _getThemeSubtitle(state.themeMode),
                trailing: DropdownButton<ThemeMode>(
                  value: state.themeMode,
                  onChanged: (ThemeMode? newValue) {
                    if (newValue != null) {
                      context.read<PreferencesBloc>().add(SetThemeMode(newValue));
                    }
                  },
                  underline: const SizedBox.shrink(),
                  icon: const Icon(Icons.arrow_drop_down),
                  items: const [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text('System'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text('Light'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text('Dark'),
                    ),
                  ],
                ),
              ),
              const Divider(),

              // UI Density Toggle
              SwitchListTile(
                title: const Text('Compact UI'),
                subtitle: const Text('Use smaller padding values throughout the app'),
                secondary: const Icon(Icons.density_medium, size: ConfigService.defaultIconSize),
                value: state.compactUiDensity,
                onChanged: (bool value) {
                  context.read<PreferencesBloc>().add(SetCompactUiDensity(value));
                  
                  // Show a snackbar informing the user that changes are applied immediately
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('UI density has been updated'),
                      duration: ConfigService.snackBarDuration,
                    ),
                  );
                },
              ),
              const Divider(),
              
              // Hardware Acceleration Toggle
              SwitchListTile(
                title: const Text('Hardware Acceleration'),
                subtitle: const Text('Use GPU for rendering (disabling may help on some devices, but is undefined behaviour)'),
                secondary: const Icon(Icons.speed, size: ConfigService.defaultIconSize),
                value: state.hardwareAcceleration,
                onChanged: (bool value) {
                  context.read<PreferencesBloc>().add(SetHardwareAcceleration(value));
                  
                  // Show a snackbar informing the user that restart is required
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Restart the app for this change to take effect'),
                      duration: ConfigService.snackBarDuration,
                    ),
                  );
                },
              ),
              const Divider(),
              
              // Debug section
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  _fixedDefaultPadding, 
                  _fixedDefaultPadding, 
                  _fixedDefaultPadding, 
                  _fixedSmallPadding
                ),
                child: const Text(
                  'Debug Options',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.delete_forever, 
                  size: ConfigService.defaultIconSize, 
                  color: Colors.red
                ),
                title: const Text('Reset Database'),
                subtitle: const Text('Delete all data and restart app'),
                onTap: () => _confirmDatabaseReset(context),
              ),
              const Divider(),
              
              const AboutListTile(
                icon: Icon(Icons.info_outline, size: ConfigService.defaultIconSize),
                applicationName: 'Food Inventory',
                applicationVersion: '1.0.0',
                applicationIcon: Icon(Icons.inventory),
                aboutBoxChildren: [
                  SizedBox(height: _fixedMediumPadding),
                  Text('A comprehensive app for tracking food inventory and stock.'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _getThemeSubtitle(ThemeMode mode) {
    String text;
    switch (mode) {
      case ThemeMode.system:
        text = 'Use system settings';
      case ThemeMode.light:
        text = 'Light mode';
      case ThemeMode.dark:
        text = 'Dark mode';
    }
    return Text(text, style: const TextStyle(fontSize: 12));
  }
  
  Future<void> _confirmDatabaseReset(BuildContext context) async {
    final confirmed = await showDatabaseResetBottomSheet(context);
    
    if (confirmed == true) {
      final databaseService = ServiceLocator.instance<DatabaseService>();
      final dialogService = Provider.of<DialogService>(context, listen: false);
      
      // Show a loading bottom sheet while resetting
      if (context.mounted) {
        await dialogService.showLoadingBottomSheet(
          context: context,
          message: 'Resetting Database',
        );
      }
      
      // Reset the database
      await databaseService.resetDatabase();
      
      // Close the loading sheet and navigate back
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading sheet
        Navigator.of(context).popUntil((route) => route.isFirst);
        
        // Show a confirmation message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Database has been reset'),
            duration: ConfigService.snackBarDuration,
          ),
        );
      }
    }
  }
}