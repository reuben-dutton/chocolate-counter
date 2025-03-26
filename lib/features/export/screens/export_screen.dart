// lib/features/export/screens/export_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/common/services/dialog_service.dart';
import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/features/export/bloc/export_bloc.dart';
import 'package:food_inventory/features/export/services/export_service.dart';
import 'package:food_inventory/features/export/widgets/export_format_card.dart';
import 'package:food_inventory/features/export/widgets/sqlite_export_info_sheet.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  late ExportBloc _exportBloc;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final exportService = Provider.of<ExportService>(context, listen: false);
    _exportBloc = ExportBloc(exportService);
  }

  @override
  void dispose() {
    _exportBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dialogService = Provider.of<DialogService>(context);
    
    return BlocProvider.value(
      value: _exportBloc,
      child: BlocConsumer<ExportBloc, ExportState>(
        listener: (context, state) {
          if (state is ExportError) {
            ErrorHandler.showErrorSnackBar(
              context, 
              state.error.message, 
              error: state.error.error,
            );
          } else if (state is ExportSuccess) {
            final filePath = state.filePath;
            final fileName = path.basename(filePath);
            String locationMessage = '';

            if (Platform.isAndroid && filePath.contains('/Download/')) {
              locationMessage = 'Saved to Downloads folder';
            } else {
              locationMessage = 'Saved to app storage';
            }

            ErrorHandler.showSuccessSnackBar(
              context, 
              'Export complete: $fileName\n$locationMessage',
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            body: RefreshIndicator(
              onRefresh: () async {
                // Add refresh functionality if needed
              },
              child: SingleChildScrollView(
                padding: EdgeInsets.all(ConfigService.mediumPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header section
                    _buildHeader(context),
                    
                    SizedBox(height: ConfigService.largePadding),
                    
                    // Format options section
                    Text(
                      'Export Formats',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: ConfigService.mediumPadding),
                    
                    // Grid of format cards
                    GridView.count(
                      padding: EdgeInsets.zero,
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1,
                      mainAxisSpacing: ConfigService.smallPadding,
                      crossAxisSpacing: ConfigService.smallPadding,
                      children: [
                        ExportFormatCard(
                          icon: Icons.view_list,
                          title: 'CSV',
                          description: 'Export as CSV files for spreadsheet applications',
                          onTap: () => _startExport(context, ExportFormat.csv),
                          isLoading: state is ExportLoading && state.format == ExportFormat.csv,
                        ),
                        ExportFormatCard(
                          icon: Icons.description,
                          title: 'JSON',
                          description: 'Export as JSON for data processing',
                          onTap: () => _startExport(context, ExportFormat.json),
                          isLoading: state is ExportLoading && state.format == ExportFormat.json,
                        ),
                        ExportFormatCard(
                          icon: Icons.dataset,
                          title: 'SQLite',
                          description: 'Export the full database file for backup or transfer',
                          onTap: () => _startExport(context, ExportFormat.sqlite),
                          isLoading: state is ExportLoading && state.format == ExportFormat.sqlite,
                        ),
                        ExportFormatCard(
                          icon: Icons.horizontal_split,
                          title: 'Excel',
                          description: 'Export as Excel spreadsheet with multiple tabs',
                          onTap: () => _startExport(context, ExportFormat.excel),
                          isLoading: state is ExportLoading && state.format == ExportFormat.excel,
                        ),
                      ],
                    ),
                    
                    SizedBox(height: ConfigService.largePadding),
                    
                    // Options section
                    _buildOptionsSection(context, state),
                    
                    SizedBox(height: ConfigService.largePadding),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.download_rounded,
              size: ConfigService.largeIconSize,
              color: theme.colorScheme.primary,
            ),
            SizedBox(width: ConfigService.mediumPadding),
            Text(
              'Export Inventory Data',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        SizedBox(height: ConfigService.smallPadding),
        Text(
          'Export your inventory data in different formats for analysis, backup, or sharing with others.',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildOptionsSection(BuildContext context, ExportState state) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Export Options',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: ConfigService.smallPadding),
        Card(
          child: Padding(
            padding: EdgeInsets.all(ConfigService.mediumPadding),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Include Images'),
                  subtitle: const Text('Include product images in the export (where supported)'),
                  value: state.includeImages,
                  onChanged: (bool value) {
                    context.read<ExportBloc>().add(ToggleIncludeImages(value));
                  },
                ),
                SwitchListTile(
                  title: const Text('Include History'),
                  subtitle: const Text('Include movement history in the export'),
                  value: state.includeHistory,
                  onChanged: (bool value) {
                    context.read<ExportBloc>().add(ToggleIncludeHistory(value));
                  },
                ),
                SwitchListTile(
                  title: const Text('Export All Data'),
                  subtitle: const Text('Export all tables including settings'),
                  value: state.exportAllData,
                  onChanged: (bool value) {
                    context.read<ExportBloc>().add(ToggleExportAllData(value));
                  },
                ),
                const Divider(),
                // Add directory selection button
                ListTile(
                  title: const Text('Export Location'),
                  subtitle: Text(state.customExportDir ?? 'Default location'),
                  trailing: ElevatedButton.icon(
                    icon: const Icon(Icons.folder_open, size: ConfigService.smallIconSize),
                    label: const Text('Choose'),
                    onPressed: () => _selectExportDirectory(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectExportDirectory(BuildContext context) async {
    final exportService = Provider.of<ExportService>(context, listen: false);
    final dialogService = Provider.of<DialogService>(context, listen: false);
    
    try {
      bool hasPermission = false;
      String permissionMessage = '';
      
      if (Platform.isAndroid) {
        // Check Android version and if it's an emulator
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final isEmulator = !androidInfo.isPhysicalDevice;
        
        // Skip permission check on emulators
        if (isEmulator) {
          hasPermission = true;
        } else {
          final sdkInt = androidInfo.version.sdkInt;
          
          if (sdkInt >= 30) { // Android 11+
            // First try with storage permission
            var storageStatus = await Permission.storage.status;
            
            if (!storageStatus.isGranted) {
              storageStatus = await Permission.storage.request();
            }
            
            // If regular storage permission isn't enough, try with manage external storage
            if (!storageStatus.isGranted) {
              var manageStatus = await Permission.manageExternalStorage.status;
              
              if (!manageStatus.isGranted) {
                manageStatus = await Permission.manageExternalStorage.request();
              }
              
              hasPermission = manageStatus.isGranted;
              
              if (!hasPermission) {
                permissionMessage = 'Storage permission required for selecting a custom directory. Please grant the permission in app settings.';
              }
            } else {
              hasPermission = true;
            }
          } else { // Android 10 and below
            var status = await Permission.storage.status;
            
            if (!status.isGranted) {
              status = await Permission.storage.request();
            }
            
            hasPermission = status.isGranted;
            
            if (!hasPermission) {
              permissionMessage = 'Storage permission required for selecting a custom directory. Please grant the permission in app settings.';
            }
          }
        }
      } else {
        // For iOS and other platforms, no special permissions needed
        hasPermission = true;
      }
      
      if (!hasPermission) {
        if (context.mounted) {
          // Show permission denied message
          await dialogService.showMessageDialog(
            context: context,
            title: 'Permission Required',
            message: permissionMessage,
            buttonText: 'OK',
          );
          
          return;
        }
      }
      
      // If we have permission, let user choose a directory
      if (context.mounted) {
        final selectedDir = await exportService.chooseExportDirectory();
        
        if (selectedDir != null && context.mounted) {
          context.read<ExportBloc>().add(SetCustomExportDirectory(selectedDir.path));
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Export location set to: ${selectedDir.path}'),
              duration: ConfigService.snackBarDuration,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      // Log and show error
      ErrorHandler.logError('Error selecting export directory', e, stackTrace, 'ExportScreen');
      
      if (context.mounted) {
        ErrorHandler.showErrorSnackBar(
          context, 
          'Error selecting export directory: ${e.toString()}',
        );
      }
    }
  }

  void _startExport(BuildContext context, ExportFormat format) async {
    final dialogService = Provider.of<DialogService>(context, listen: false);
    
    try {
      // Check permissions before starting export
      bool hasPermission = false;
      
      if (Platform.isAndroid) {
        // Check if it's an emulator
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final isEmulator = !androidInfo.isPhysicalDevice;
        
        // Skip permission check on emulators
        if (isEmulator) {
          hasPermission = true;
        } else {
          final sdkInt = androidInfo.version.sdkInt;
          
          if (sdkInt >= 30) { // Android 11+
            // For Android 11+, check both permissions
            var storageStatus = await Permission.storage.status;
            if (!storageStatus.isGranted) {
              storageStatus = await Permission.storage.request();
            }
            
            if (storageStatus.isGranted) {
              hasPermission = true;
            } else {
              // Try manage external storage as fallback
              final manageStatus = await Permission.manageExternalStorage.request();
              hasPermission = manageStatus.isGranted;
            }
          } else { // Android 10 and below
            final status = await Permission.storage.request();
            hasPermission = status.isGranted;
          }
        }
      } else {
        // For iOS and other platforms, no special permissions needed
        hasPermission = true;
      }
      
      if (!hasPermission && context.mounted) {
        await dialogService.showMessageDialog(
          context: context,
          title: 'Permission Required',
          message: 'Storage permission is required to export data. Please grant the permission in app settings.',
          buttonText: 'OK',
        );
        return;
      }
      
      // For SQLite export, show additional info first
      if (format == ExportFormat.sqlite) {
        final proceed = await showSQLiteExportInfoSheet(context);
        if (proceed != true || !context.mounted) {
          return;
        }
      }
      
      // Start export process
      if (context.mounted) {
        context.read<ExportBloc>().add(StartExport(format));
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error starting export', e, stackTrace, 'ExportScreen');
      
      if (context.mounted) {
        ErrorHandler.showErrorSnackBar(
          context, 
          'Error starting export: ${e.toString()}',
        );
      }
    }
  }
}