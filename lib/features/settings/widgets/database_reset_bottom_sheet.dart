import 'package:flutter/material.dart';
import 'package:food_inventory/common/widgets/modal_bottom_sheet.dart';

class DatabaseResetBottomSheet extends StatelessWidget {
  const DatabaseResetBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ModalBottomSheet.buildHeader(
          context: context,
          title: 'Reset Database',
          icon: Icons.warning_amber_rounded,
          iconColor: theme.colorScheme.error,
          onClose: () => Navigator.of(context).pop(false),
        ),
        
        const SizedBox(height: 8),
        Text(
          'WARNING: This will permanently delete ALL your data',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.error,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'This includes all items, shipments, inventory, and settings. '
          'This action cannot be undone.',
        ),
        const SizedBox(height: 12),
        Text(
          'The app will restart after resetting.',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        
        const SizedBox(height: 24),
        ModalBottomSheet.buildActions(
          context: context,
          onCancel: () => Navigator.of(context).pop(false),
          onConfirm: () => Navigator.of(context).pop(true),
          confirmText: 'Reset Database',
          isDestructiveAction: true,
        ),
      ],
    );
  }
}

// Helper method to show the bottom sheet
Future<bool?> showDatabaseResetBottomSheet(BuildContext context) {
  return ModalBottomSheet.show<bool>(
    context: context,
    builder: (context) => const DatabaseResetBottomSheet(),
  );
}