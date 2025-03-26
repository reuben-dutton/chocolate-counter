// lib/features/export/widgets/share_export_bottom_sheet.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/common/widgets/modal_bottom_sheet.dart';
import 'package:food_inventory/features/export/services/export_service.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';

class ShareExportBottomSheet extends StatelessWidget {
  final String filePath;
  final ExportFormat format;

  const ShareExportBottomSheet({
    Key? key,
    required this.filePath,
    required this.format,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fileName = path.basename(filePath);
    final fileSize = _getFileSize();
    
    // Get format-specific information
    IconData formatIcon;
    String formatName;
    String description;
    
    switch (format) {
      case ExportFormat.csv:
        formatIcon = Icons.view_list;
        formatName = 'CSV';
        description = 'Your inventory data has been exported to CSV files, which can be opened in spreadsheet applications like Excel, Google Sheets, or LibreOffice Calc.';
        break;
      case ExportFormat.json:
        formatIcon = Icons.description;
        formatName = 'JSON';
        description = 'Your inventory data has been exported to JSON format, which is ideal for data processing or importing into other applications.';
        break;
      case ExportFormat.sqlite:
        formatIcon = Icons.dataset;
        formatName = 'SQLite';
        description = 'Your inventory database has been exported as a SQLite file, which can be opened with SQLite browser applications or used as a backup.';
        break;
      case ExportFormat.excel:
        formatIcon = Icons.horizontal_split;
        formatName = 'Excel';
        description = 'Your inventory data has been exported as an Excel spreadsheet with multiple tabs for different data categories.';
        break;
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ModalBottomSheet.buildHeader(
          context: context,
          title: 'Export Complete',
          icon: Icons.check_circle,
          iconColor: Colors.green,
          onClose: () => Navigator.of(context).pop(),
        ),
        
        // File info
        Padding(
          padding: EdgeInsets.all(ConfigService.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      formatIcon,
                      size: 36,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(width: ConfigService.defaultPadding),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$formatName Export Complete',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: ConfigService.smallPadding),
                        Text(
                          fileName,
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          fileSize,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: ConfigService.defaultPadding),
              
              Text(
                description,
                style: theme.textTheme.bodyMedium,
              ),
              
              SizedBox(height: ConfigService.largePadding),
              
              // Share button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: EdgeInsets.symmetric(vertical: ConfigService.mediumPadding),
                  ),
                  onPressed: () => _shareFile(context),
                ),
              ),
              
              SizedBox(height: ConfigService.mediumPadding),
              
              // File location
              Text(
                'File saved to:',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: ConfigService.tinyPadding),
              Text(
                filePath,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  String _getFileSize() {
    try {
      final file = File(filePath);
      final bytes = file.lengthSync();
      
      if (bytes < 1024) {
        return '$bytes B';
      } else if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(1)} KB';
      } else {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    } catch (e) {
      return 'Unknown size';
    }
  }
  
  void _shareFile(BuildContext context) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Food Inventory Export',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing file: $e')),
        );
      }
    }
  }
}

// Helper method to show the bottom sheet
Future<void> showShareExportBottomSheet(
  BuildContext context, 
  String filePath,
  ExportFormat format,
) {
  return ModalBottomSheet.show(
    context: context,
    builder: (context) => ShareExportBottomSheet(
      filePath: filePath,
      format: format,
    ),
  );
}