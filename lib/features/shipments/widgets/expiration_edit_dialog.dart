import 'package:flutter/material.dart';
import 'package:food_inventory/data/models/shipment_item.dart';
import 'package:intl/intl.dart';

class ExpirationEditDialog extends StatefulWidget {
  final ShipmentItem item;

  const ExpirationEditDialog({
    super.key,
    required this.item,
  });

  @override
  _ExpirationEditDialogState createState() => _ExpirationEditDialogState();
}

class _ExpirationEditDialogState extends State<ExpirationEditDialog> {
  late DateTime? _expirationDate;

  @override
  void initState() {
    super.initState();
    _expirationDate = widget.item.expirationDate;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final theme = Theme.of(context);
    
    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            'Edit Expiration Date',
            style: theme.textTheme.titleMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Item info
          Text(
            widget.item.itemDefinition?.name ?? 'Unknown Item',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_bag, size: 16),
              const SizedBox(width: 4),
              Text('Quantity: ${widget.item.quantity}', 
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Current expiration date
          Text(
            'Current expiration:',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _expirationDate != null
                  ? dateFormat.format(_expirationDate!)
                  : 'No expiration date',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          
          // Date selection buttons
          Column(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.calendar_today, size: 16),
                label: const Text('Choose New Date'),
                onPressed: () => _selectDate(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  minimumSize: const Size(200, 0),
                ),
              ),
              if (_expirationDate != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: Icon(Icons.remove_circle_outline, size: 16, color: theme.colorScheme.error),
                  label: Text('Remove Date', style: TextStyle(color: theme.colorScheme.error)),
                  onPressed: () {
                    setState(() {
                      _expirationDate = null;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.colorScheme.error),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    minimumSize: const Size(200, 0),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurface,
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save, size: 16),
              label: const Text('Save'),
              onPressed: () {
                Navigator.of(context).pop(_expirationDate);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),  // Allow dates in the past for correction
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),    // Limit to 5 years in the future
      helpText: 'SELECT EXPIRATION DATE',
      cancelText: 'CANCEL',
      confirmText: 'SELECT',
      errorFormatText: 'Enter a valid date',
      errorInvalidText: 'Invalid date range',
      fieldLabelText: 'Expiration date',
      fieldHintText: 'MM/DD/YYYY',
    );
    
    if (picked != null) {
      setState(() {
        _expirationDate = picked;
      });
    }
  }
}