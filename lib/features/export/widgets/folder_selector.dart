import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/features/export/bloc/export_bloc.dart';
import 'package:path/path.dart' as path;

class FolderSelector extends StatelessWidget {
  const FolderSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocBuilder<ExportBloc, ExportState>(
      buildWhen: (previous, current) => 
        previous is! ExportConfigured || 
        current is! ExportConfigured || 
        previous.outputDirectory != current.outputDirectory,
      builder: (context, state) {
        final outputDir = state is ExportConfigured ? state.outputDirectory : null;
        final hasSelectedDir = outputDir != null;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Destination',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ConfigService.mediumPadding),
            
            Text(
              'Choose where to save your exported data:',
              style: theme.textTheme.bodyMedium,
            ),
            SizedBox(height: ConfigService.defaultPadding),
            
            // Current selection display
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(ConfigService.mediumPadding),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(ConfigService.borderRadiusMedium),
                border: Border.all(
                  color: hasSelectedDir 
                      ? theme.colorScheme.primary 
                      : theme.colorScheme.outline,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Export destination:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: ConfigService.tinyPadding),
                  Row(
                    children: [
                      Icon(
                        Icons.folder,
                        color: hasSelectedDir 
                            ? theme.colorScheme.primary 
                            : theme.colorScheme.onSurface,
                        size: ConfigService.defaultIconSize,
                      ),
                      SizedBox(width: ConfigService.smallPadding),
                      Expanded(
                        child: Text(
                          hasSelectedDir 
                              ? _formatPath(outputDir)
                              : 'No folder selected',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: hasSelectedDir ? FontWeight.bold : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: ConfigService.mediumPadding),
            
            // Button to select folder
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.folder_open),
                label: Text(hasSelectedDir ? 'Change Folder' : 'Select Folder'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: ConfigService.defaultPadding, 
                    vertical: ConfigService.mediumPadding,
                  ),
                ),
                onPressed: () => _selectFolder(context),
              ),
            ),
            
            SizedBox(height: ConfigService.largePadding),
            
            // Note about folder selection
            Container(
              padding: EdgeInsets.all(ConfigService.mediumPadding),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(ConfigService.borderRadiusMedium),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                    size: ConfigService.mediumIconSize,
                  ),
                  SizedBox(width: ConfigService.mediumPadding),
                  Expanded(
                    child: Text(
                      'The export will be saved as a zip file in the selected folder. '
                      'The file will be named with the current date and export format.',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _selectFolder(BuildContext context) async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      
      if (selectedDirectory != null) {
        context.read<ExportBloc>().add(SetOutputDirectory(selectedDirectory));
      }
    } catch (e, stackTrace) {
      ErrorHandler.showErrorSnackBar(
        context, 
        'Failed to select folder: ${e.toString()}',
      );
      ErrorHandler.logError('Folder selection error', e, stackTrace, 'FolderSelector');
    }
  }
  
  String _formatPath(String pathString) {
    if (pathString.length < 50) {
      return pathString;
    }
    
    // Show just the folder name with an ellipsis for long paths
    final dirName = path.basename(pathString);
    final parentDir = path.dirname(pathString);
    
    if (parentDir.length > 30) {
      return '...${pathString.substring(pathString.length - 40)}';
    }
    
    return pathString;
  }
}