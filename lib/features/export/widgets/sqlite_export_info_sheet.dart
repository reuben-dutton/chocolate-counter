// lib/features/export/widgets/sqlite_export_info_sheet.dart

import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/common/widgets/modal_bottom_sheet.dart';

class SQLiteExportInfoSheet extends StatelessWidget {
  const SQLiteExportInfoSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ModalBottomSheet.buildHeader(
          context: context,
          title: 'SQLite Database Export',
          icon: Icons.dataset,
          iconColor: theme.colorScheme.primary,
          onClose: () => Navigator.of(context).pop(false),
        ),
        
        SizedBox(height: ConfigService.smallPadding),
        Text(
          'About SQLite Export',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        SizedBox(height: ConfigService.defaultPadding),
        const Text(
          'The SQLite export creates a copy of your entire database file. This is useful for:',
        ),
        SizedBox(height: ConfigService.smallPadding),
        
        // Bulleted list of benefits
        Padding(
          padding: EdgeInsets.only(left: ConfigService.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBulletPoint(context, 'Creating a complete backup of all your data'),
              _buildBulletPoint(context, 'Transferring your data to another device'),
              _buildBulletPoint(context, 'Advanced users who want to analyze the data with SQLite tools'),
            ],
          ),
        ),
        
        SizedBox(height: ConfigService.defaultPadding),
        const Text(
          'If you include images, they will be exported separately alongside the database file.',
        ),
        
        SizedBox(height: ConfigService.largePadding),
        ModalBottomSheet.buildActions(
          context: context,
          onCancel: () => Navigator.of(context).pop(false),
          onConfirm: () => Navigator.of(context).pop(true),
          confirmText: 'Continue with Export',
        ),
      ],
    );
  }
  
  Widget _buildBulletPoint(BuildContext context, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: ConfigService.smallPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

// Helper method to show the bottom sheet
Future<bool?> showSQLiteExportInfoSheet(BuildContext context) {
  return ModalBottomSheet.show<bool>(
    context: context,
    builder: (context) => const SQLiteExportInfoSheet(),
  );
}