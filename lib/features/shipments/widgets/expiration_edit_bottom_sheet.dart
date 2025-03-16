import 'package:flutter/material.dart';
import 'package:food_inventory/common/widgets/modal_bottom_sheet.dart';
import 'package:food_inventory/data/models/shipment_item.dart';
import 'package:intl/intl.dart';

class ExpirationEditBottomSheet extends StatefulWidget {
  final ShipmentItem item;

  const ExpirationEditBottomSheet({
    Key? key,
    required this.item,
  }) : super(key: key);

  @override
  _ExpirationEditBottomSheetState createState() => _ExpirationEditBottomSheetState();
}

class _ExpirationEditBottomSheetState extends State<ExpirationEditBottomSheet> {
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
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        ModalBottomSheet.buildHeader(
          context: context,
          title: 'Edit Expiration Date',
          icon: Icons.event_available,
          onClose: () => Navigator.of(context).pop(),
        ),
        
        // Item info
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
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
            ],
          ),
        ),
        
        // Current expiration date
        Text(
          'Current expiration:',
          style: theme.textTheme.bodyMedium,
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_today, size: 16),
              label: const Text('Choose New Date'),
              onPressed: () => _selectDate(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                ),
              ),
            ],
          ],
        ),
        
        // Action buttons
        const SizedBox(height: 24),
        ModalBottomSheet.buildActions(
          context: context,
          onCancel: () => Navigator.of(context).pop(),
          onConfirm: () => Navigator.of(context).pop(_expirationDate),
          confirmText: 'Save',
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
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

// Helper method to show the bottom sheet
Future<DateTime?> showExpirationEditBottomSheet(
  BuildContext context, 
  ShipmentItem item,
) {
  return ModalBottomSheet.show<DateTime?>(
    context: context,
    builder: (context) => ExpirationEditBottomSheet(item: item),
  );
}