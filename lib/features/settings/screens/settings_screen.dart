import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/common/services/database_service.dart';
import 'package:food_inventory/common/services/service_locator.dart';
import 'package:food_inventory/features/settings/bloc/preferences_bloc.dart';
import 'package:food_inventory/features/settings/widgets/database_reset_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreferencesBloc, PreferencesState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
          ),
          body: ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.palette, size: 20),
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
              
              // Debug section
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
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
                  size: 20, 
                  color: Colors.red
                ),
                title: const Text('Reset Database'),
                subtitle: const Text('Delete all data and restart app'),
                onTap: () => _confirmDatabaseReset(context),
              ),
              const Divider(),
              
              const AboutListTile(
                icon: Icon(Icons.info_outline, size: 20),
                applicationName: 'Food Inventory',
                applicationVersion: '1.0.0',
                applicationIcon: Icon(Icons.inventory),
                aboutBoxChildren: [
                  SizedBox(height: 10),
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
        text = 'Follow system settings';
        break;
      case ThemeMode.light:
        text = 'Light mode';
        break;
      case ThemeMode.dark:
        text = 'Dark mode';
        break;
    }
    return Text(text, style: const TextStyle(fontSize: 12));
  }
  
  Future<void> _confirmDatabaseReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const DatabaseResetDialog(),
    );
    
    if (confirmed == true) {
      final databaseService = ServiceLocator.instance<DatabaseService>();
      
      // Show a loading dialog while resetting
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            title: Text('Resetting Database'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Please wait...'),
              ],
            ),
          ),
        );
      }
      
      // Reset the database
      await databaseService.resetDatabase();
      
      // Restart the app by popping to the first route and showing a confirmation
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        
        // Show a confirmation message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Database has been reset'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
}