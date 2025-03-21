import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/common/services/database_service.dart';
import 'package:food_inventory/common/services/dialog_service.dart';
import 'package:food_inventory/common/services/service_locator.dart';
import 'package:food_inventory/features/settings/bloc/preferences_bloc.dart';
import 'package:food_inventory/features/settings/widgets/database_reset_bottom_sheet.dart';
import 'package:food_inventory/theme/theme_loader.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreferencesBloc, PreferencesState>(
      buildWhen: (previous, current) => 
        previous.themeMode != current.themeMode || 
        previous.themeType != current.themeType ||
        previous.hardwareAcceleration != current.hardwareAcceleration ||
        previous.compactUiDensity != current.compactUiDensity,
      builder: (context, state) {
        final theme = Theme.of(context);
        final availableThemes = ThemeLoader.themes;
        
        return Scaffold(
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              // Appearance Section
              _buildSectionHeader(context, 'Appearance'),
              
              // Theme Mode
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Theme Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (final mode in ThemeMode.values)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: _buildFixedSizeButton(
                                context,
                                label: _getThemeModeLabel(mode),
                                selected: state.themeMode == mode,
                                onTap: () => context.read<PreferencesBloc>().add(SetThemeMode(mode)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Theme Type
              // Theme Type section for settings screen
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Theme Style', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final entry in availableThemes.entries)
                          Container(
                            constraints: const BoxConstraints(minWidth: 100),
                            child: _buildFixedSizeButton(
                              context,
                              label: entry.value.name,
                              selected: state.themeType == entry.key,
                              onTap: () => context.read<PreferencesBloc>().add(SetThemeType(entry.key)),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              const Divider(),
              
              // UI Settings
              _buildSectionHeader(context, 'UI Settings'),
              
              // UI Density
              SwitchListTile(
                title: const Text('Compact UI'),
                subtitle: const Text('Use smaller padding throughout the app'),
                value: state.compactUiDensity,
                onChanged: (bool value) {
                  context.read<PreferencesBloc>().add(SetCompactUiDensity(value));
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('UI density has been updated'),
                      duration: ConfigService.snackBarDuration,
                    ),
                  );
                },
              ),
              
              // Hardware Acceleration
              SwitchListTile(
                title: const Text('Hardware Acceleration'),
                subtitle: const Text('Disable for certain devices with graphics issues'),
                value: state.hardwareAcceleration,
                onChanged: (bool value) {
                  context.read<PreferencesBloc>().add(SetHardwareAcceleration(value));
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Restart the app for this change to take effect'),
                      duration: ConfigService.snackBarDuration,
                    ),
                  );
                },
              ),
              
              const Divider(),
              
              // Debug & About Section
              _buildSectionHeader(context, 'Debug & About'),
              
              // Reset Database
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Reset Database', style: TextStyle(fontSize: 16)),
                          SizedBox(height: 4),
                          Text('Delete all data and restart app', 
                            style: TextStyle(fontSize: 14, color: Colors.grey)),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(36),
                        ),
                        onPressed: () => _confirmDatabaseReset(context),
                        child: const Text('Reset'),
                      ),
                    ),
                  ],
                ),
              ),
              
              // About
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('About', style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('Version ${ConfigService.appVersion}', 
                            style: const TextStyle(fontSize: 14, color: Colors.grey)),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(36),
                        ),
                        onPressed: () => _showAboutDialog(context),
                        child: const Text('Details'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildFixedSizeButton(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return Material(
      color: selected ? theme.colorScheme.primary : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      elevation: selected ? 1 : 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? theme.colorScheme.primary : theme.colorScheme.outline,
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Future<void> _confirmDatabaseReset(BuildContext context) async {
    final confirmed = await showDatabaseResetBottomSheet(context);
    
    if (confirmed == true) {
      final databaseService = ServiceLocator.instance<DatabaseService>();
      final dialogService = Provider.of<DialogService>(context, listen: false);
      
      if (context.mounted) {
        await dialogService.showLoadingBottomSheet(
          context: context,
          message: 'Resetting Database',
        );
      }
      
      await databaseService.resetDatabase();
      
      if (context.mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).popUntil((route) => route.isFirst);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Database has been reset'),
            duration: ConfigService.snackBarDuration,
          ),
        );
      }
    }
  }
  
  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: ConfigService.appName,
      applicationVersion: ConfigService.appVersion,
      applicationIcon: const Icon(Icons.inventory_2),
      children: [
        const SizedBox(height: 16),
        const Text('A comprehensive app for tracking food inventory and stock.'),
      ],
    );
  }
}