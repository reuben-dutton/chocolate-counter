import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/common/widgets/modal_bottom_sheet.dart';
import 'package:food_inventory/features/settings/widgets/confirm_dialog.dart';

/// Service for handling dialogs and bottom sheets throughout the application
class DialogService {
  /// Show a confirmation dialog
  Future<bool?> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String content,
    IconData? icon,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: title,
        content: content,
        icon: icon,
      ),
    );
  }
  
  /// Show a confirmation as bottom sheet
  Future<bool?> showConfirmBottomSheet({
    required BuildContext context,
    required String title,
    required String content,
    IconData? icon,
  }) async {
    return ModalBottomSheet.show<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final isDestructive = icon == Icons.delete_forever || icon == Icons.delete_sweep;
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ModalBottomSheet.buildHeader(
              context: context,
              title: title,
              icon: icon ?? Icons.warning_rounded,
              iconColor: isDestructive
                ? theme.colorScheme.error
                : theme.colorScheme.secondary,
              onClose: () => Navigator.of(context).pop(false),
            ),
            
            // Content
            Padding(
              padding: EdgeInsets.symmetric(vertical: ConfigService.defaultPadding),
              child: Text(
                content,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            
            // Actions
            SizedBox(height: ConfigService.largePadding),
            ModalBottomSheet.buildActions(
              context: context,
              onCancel: () => Navigator.of(context).pop(false),
              onConfirm: () => Navigator.of(context).pop(true),
              confirmText: isDestructive ? 'Delete' : 'Confirm',
              isDestructiveAction: isDestructive,
            ),
          ],
        );
      },
    );
  }
  
  /// Show a dialog to select a date
  Future<DateTime?> showCustomDatePicker({
    required BuildContext context,
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    String? helpText,
  }) async {
    return showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime(2101),
      helpText: helpText,
    );
  }
  
  /// Show a dialog to select a date and time
  Future<DateTime?> showDateTimePicker({
    required BuildContext context,
    DateTime? initialDate,
  }) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate ?? DateTime.now()),
      );
      
      if (pickedTime != null) {
        return DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      }
    }
    
    return null;
  }
  
  /// Show a dialog to enter a quantity
  Future<int?> showQuantityDialog({
    required BuildContext context,
    required String title,
    required int currentQuantity,
    required int maxQuantity,
    IconData? icon,
  }) async {
    int quantity = currentQuantity;
    TextEditingController controller = TextEditingController(text: quantity.toString());
    
    return showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final theme = Theme.of(context);
          
          return AlertDialog(
            backgroundColor: theme.colorScheme.surface,
            title: Row(
              children: [
                Icon(icon ?? Icons.inventory_2, size: ConfigService.defaultIconSize),
                SizedBox(width: ConfigService.smallPadding),
                Text(title),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Maximum: $maxQuantity'),
                SizedBox(height: ConfigService.smallPadding),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: quantity > 1 
                          ? () => setState(() {
                              quantity--;
                              controller.text = quantity.toString();
                            })
                          : null,
                    ),
                    SizedBox(
                      width: 50,
                      child: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        onChanged: (value) {
                          final newValue = int.tryParse(value);
                          if (newValue != null && newValue > 0 && newValue <= maxQuantity) {
                            setState(() {
                              quantity = newValue;
                            });
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: quantity < maxQuantity
                          ? () => setState(() {
                              quantity++;
                              controller.text = quantity.toString();
                            })
                          : null,
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(quantity),
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  /// Show a quantity dialog as bottom sheet
  Future<int?> showQuantityBottomSheet({
    required BuildContext context,
    required String title,
    required int currentQuantity,
    required int maxQuantity,
    IconData? icon,
  }) async {
    int quantity = currentQuantity;
    TextEditingController controller = TextEditingController(text: quantity.toString());
    
    return ModalBottomSheet.show<int>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                ModalBottomSheet.buildHeader(
                  context: context,
                  title: title,
                  icon: icon ?? Icons.inventory_2,
                  onClose: () => Navigator.of(context).pop(),
                ),
                
                // Content
                Text('Maximum: $maxQuantity'),
                SizedBox(height: ConfigService.defaultPadding),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: quantity > 1 
                          ? () => setState(() {
                              quantity--;
                              controller.text = quantity.toString();
                            })
                          : null,
                    ),
                    SizedBox(
                      width: 50,
                      child: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        onChanged: (value) {
                          final newValue = int.tryParse(value);
                          if (newValue != null && newValue > 0 && newValue <= maxQuantity) {
                            setState(() {
                              quantity = newValue;
                            });
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: quantity < maxQuantity
                          ? () => setState(() {
                              quantity++;
                              controller.text = quantity.toString();
                            })
                          : null,
                    ),
                  ],
                ),
                
                // Actions
                SizedBox(height: ConfigService.largePadding),
                ModalBottomSheet.buildActions(
                  context: context,
                  onCancel: () => Navigator.of(context).pop(),
                  onConfirm: () => Navigator.of(context).pop(quantity),
                  confirmText: 'Confirm',
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  /// Show a simple message dialog with a single action
  Future<void> showMessageDialog({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
  }) async {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
  
  /// Show a message as bottom sheet
  Future<void> showMessageBottomSheet({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
  }) async {
    return ModalBottomSheet.show(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ModalBottomSheet.buildHeader(
              context: context,
              title: title,
              icon: Icons.info_outline,
              onClose: () => Navigator.of(context).pop(),
            ),
            
            Padding(
              padding: EdgeInsets.symmetric(vertical: ConfigService.defaultPadding),
              child: Text(message),
            ),
            
            SizedBox(height: ConfigService.largePadding),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(buttonText),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
  
  /// Show a loading dialog
  Future<void> showLoadingDialog({
    required BuildContext context,
    required String message,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: ConfigService.defaultPadding),
            Text(message),
          ],
        ),
      ),
    );
  }
  
  /// Show a loading bottom sheet
  Future<void> showLoadingBottomSheet({
    required BuildContext context,
    required String message,
  }) async {
    return ModalBottomSheet.show(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: ConfigService.defaultPadding),
            Text(message),
            SizedBox(height: ConfigService.defaultPadding),
          ],
        );
      },
    );
  }
}