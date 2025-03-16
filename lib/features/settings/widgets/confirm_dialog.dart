import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final IconData? icon;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.content,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            icon ?? Icons.warning_rounded, 
            size: ConfigService.defaultIconSize, 
            color: icon == Icons.delete_forever || icon == Icons.delete_sweep
              ? theme.colorScheme.error
              : theme.colorScheme.secondary,
          ),
          const SizedBox(width: ConfigService.mediumPadding),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        content,
        style: theme.textTheme.bodyMedium,
      ),
      contentPadding: const EdgeInsets.all(ConfigService.largePadding),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: ConfigService.defaultPadding, vertical: ConfigService.mediumPadding),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ConfigService.borderRadiusSmall),
            ),
          ),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: icon == Icons.delete_forever || icon == Icons.delete_sweep
                ? theme.colorScheme.error
                : theme.colorScheme.primary,
            foregroundColor: icon == Icons.delete_forever || icon == Icons.delete_sweep
                ? theme.colorScheme.onError
                : theme.colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: ConfigService.defaultPadding, vertical: ConfigService.mediumPadding),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ConfigService.borderRadiusSmall),
            ),
          ),
          child: Text(
            icon == Icons.delete_forever || icon == Icons.delete_sweep
              ? 'Delete'
              : 'Confirm'
          ),
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(ConfigService.defaultPadding, 0, ConfigService.defaultPadding, ConfigService.defaultPadding),
      buttonPadding: const EdgeInsets.symmetric(horizontal: ConfigService.smallPadding),
    );
  }
}