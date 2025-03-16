import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';

/// A utility class for showing modal bottom sheets consistently across the app
class ModalBottomSheet {
  /// Show a customizable modal bottom sheet
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget Function(BuildContext) builder,
    bool isDismissible = true,
    bool enableDrag = true,
    Color? backgroundColor,
    bool useScrollView = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(ConfigService.borderRadiusLarge)),
      ),
      builder: (context) {
        // Add padding to avoid the bottom inset (keyboard, navigation bar)
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: useScrollView 
            ? SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: ConfigService.defaultPadding, vertical: ConfigService.defaultPadding), // previously +4
                  child: builder(context),
                ),
              )
            : Padding(
                padding: EdgeInsets.symmetric(horizontal: ConfigService.defaultPadding, vertical: ConfigService.defaultPadding), // previously +4
                child: builder(context),
              ),
        );
      },
    );
  }
  
  /// Helper to create a standard bottom sheet header
  static Widget buildHeader({
    required BuildContext context,
    required String title,
    IconData? icon,
    Color? iconColor,
    VoidCallback? onClose,
  }) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.colorScheme.primary;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: ConfigService.defaultIconSize, color: effectiveIconColor),
                    const SizedBox(width: ConfigService.mediumPadding),
                  ],
                  Flexible(
                    child: Text(
                      title,
                      style: theme.textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (onClose != null)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClose,
              ),
          ],
        ),
        const Divider(height: 24),
      ],
    );
  }
  
  /// Helper to create a standard bottom sheet action buttons row
  static Widget buildActions({
    required BuildContext context,
    VoidCallback? onCancel,
    VoidCallback? onConfirm,
    String cancelText = 'Cancel',
    String confirmText = 'Confirm',
    bool isDestructiveAction = false,
    bool loading = false,
  }) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (onCancel != null)
          TextButton(
            onPressed: loading ? null : onCancel,
            child: Text(cancelText),
          ),
        const SizedBox(width: ConfigService.defaultPadding),
        if (onConfirm != null)
          loading
          ? const CircularProgressIndicator()
          : ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDestructiveAction 
                  ? theme.colorScheme.error 
                  : theme.colorScheme.primary,
                foregroundColor: isDestructiveAction 
                  ? theme.colorScheme.onError 
                  : theme.colorScheme.onPrimary,
              ),
              child: Text(confirmText),
            ),
      ],
    );
  }
}