import 'package:flutter/material.dart';
import 'package:food_inventory/features/settings/widgets/confirm_dialog.dart';

/// Service for handling dialogs throughout the application
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
                Icon(icon ?? Icons.inventory_2, size: 20),
                const SizedBox(width: 8),
                Text(title),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Maximum: $maxQuantity'),
                const SizedBox(height: 8),
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
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }
}