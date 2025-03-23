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
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
            ErrorHandler.showSuccessSnackBar(
              context, 
              'Export complete: ${state.filePath}',
            );
            
            // Ask if user wants to share the file
            _promptToShareFile(context, dialogService, state.filePath);
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
                          description: 'Export the full database file for backup',
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
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _startExport(BuildContext context, ExportFormat format) async {
    // Check storage permissions
    final permission = await Permission.storage.request();
    if (permission.isDenied) {
      if (context.mounted) {
        ErrorHandler.showErrorSnackBar(
          context, 
          'Storage permission denied. Please enable in settings to export data.'
        );
      }
      return;
    }
    
    // Start export process
    if (context.mounted) {
      context.read<ExportBloc>().add(StartExport(format));
    }
  }

  void _promptToShareFile(BuildContext context, DialogService dialogService, String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return;
    
    final confirm = await dialogService.showConfirmBottomSheet(
      context: context,
      title: 'Share Export File',
      content: 'Do you want to share the exported file?',
      icon: Icons.share,
    );
    
    if (confirm == true && context.mounted) {
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Food Inventory Export',
      );
    }
  }
}