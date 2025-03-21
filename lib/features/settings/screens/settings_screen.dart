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
          body: Column(
            children: [
              // // Title section with minimal padding
              // Padding(
              //   padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              //   child: Row(
              //     children: [
              //       Icon(Icons.settings, 
              //         size: ConfigService.defaultIconSize,
              //         color: theme.colorScheme.primary),
              //       const SizedBox(width: 8),
              //       Text('Settings',
              //         style: theme.textTheme.titleLarge?.copyWith(
              //           fontWeight: FontWeight.bold
              //         )),
              //     ],
              //   ),
              // ),
              
              // Main content in an Expanded ListView
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(top: 0, bottom: 16),
                  children: [
                    // Theme Mode Section
                    Card(
                      margin: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.wb_sunny_outlined, 
                                  color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                Text('Theme Mode', 
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold
                                  )),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final mode in ThemeMode.values)
                                  _buildThemeButton(
                                    context: context,
                                    label: _getThemeModeLabel(mode),
                                    selected: state.themeMode == mode,
                                    onTap: () => context.read<PreferencesBloc>().add(SetThemeMode(mode)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Theme Type Section
                    Card(
                      margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.color_lens_outlined, 
                                  color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                Text('Theme Style', 
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold
                                  )),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final entry in availableThemes.entries)
                                  _buildThemeButton(
                                    context: context,
                                    label: entry.value.name,
                                    selected: state.themeType == entry.key,
                                    onTap: () => context.read<PreferencesBloc>().add(SetThemeType(entry.key)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // UI Options Section
                    Card(
                      margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.tune, 
                                  color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                Text('UI Options', 
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold
                                  )),
                              ],
                            ),
                            const SizedBox(height: 8),
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
                              contentPadding: EdgeInsets.zero,
                            ),
                            const Divider(),
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
                              contentPadding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Debug & About Section
                    Card(
                      margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.bug_report_outlined, 
                                  color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                Text('Debug & About', 
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold
                                  )),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ListTile(
                              title: const Text('Reset Database'),
                              subtitle: const Text('Delete all data and restart app'),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.error,
                                  foregroundColor: theme.colorScheme.onError,
                                ),
                                onPressed: () => _confirmDatabaseReset(context),
                                child: const Text('Reset'),
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                            const Divider(),
                            ListTile(
                              title: const Text('About'),
                              subtitle: Text('Version ${ConfigService.appVersion}'),
                              trailing: OutlinedButton(
                                onPressed: () => _showAboutDialog(context),
                                child: const Text('Details'),
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ],
                        ),
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
  
  Widget _buildThemeButton({
    required BuildContext context,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return Material(
      borderRadius: BorderRadius.circular(8),
      color: selected 
          ? theme.colorScheme.primary
          : theme.colorScheme.surfaceVariant,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minWidth: 90),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              color: selected 
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
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