import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/common/services/dialog_service.dart';
import 'package:food_inventory/common/widgets/expiration_date_widget.dart';
import 'package:food_inventory/common/widgets/modal_bottom_sheet.dart';
import 'package:food_inventory/data/models/item_definition.dart';

class AddItemBottomSheet extends StatefulWidget {
  final ItemDefinition item;
  final DialogService dialogService;

  const AddItemBottomSheet({
    Key? key,
    required this.item,
    required this.dialogService,
  }) : super(key: key);

  @override
  State<AddItemBottomSheet> createState() => _AddItemBottomSheetState();
}

class _AddItemBottomSheetState extends State<AddItemBottomSheet> {
  int quantity = 1;
  DateTime? expirationDate;
  final TextEditingController _priceController = TextEditingController(text: '0.00');
  
  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with item name
        ModalBottomSheet.buildHeader(
          context: context,
          title: 'Add ${widget.item.name}',
          icon: Icons.add_circle,
          onClose: () => Navigator.of(context).pop(),
        ),
        
        // Quantity selector
        SizedBox(height: ConfigService.defaultPadding),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Quantity: '),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: ConfigService.defaultIconSize),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: quantity > 1
                  ? () => setState(() => quantity--)
                  : null,
            ),
            SizedBox(width: ConfigService.smallPadding),
            Text(
              '$quantity',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: ConfigService.smallPadding),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: ConfigService.defaultIconSize),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => setState(() => quantity++),
            ),
          ],
        ),
        
        // Expiration date selector
        SizedBox(height: ConfigService.defaultPadding),
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: const Text('Expiration Date (Optional)'),
          subtitle: ExpirationDateWidget(
            expirationDate: expirationDate,
            showIcon: false,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.calendar_today, size: ConfigService.defaultIconSize),
            onPressed: () async {
              final DateTime? picked = await widget.dialogService.showCustomDatePicker(
                context: context,
                initialDate: expirationDate ?? DateTime.now().add(const Duration(days: 30)),
                firstDate: DateTime.now(),
                lastDate: DateTime(2101),
                helpText: 'Select Expiration Date',
              );
              if (picked != null) {
                setState(() {
                  expirationDate = picked;
                });
              }
            },
          ),
        ),
        
        // Add price input with increment/decrement
        SizedBox(height: ConfigService.defaultPadding),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Unit Price:',
                style: TextStyle(fontSize: 16),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () {
                final currentPrice = double.tryParse(_priceController.text) ?? 0.0;
                if (currentPrice >= 0.1) {
                  setState(() {
                    _priceController.text = (currentPrice - 0.1).toStringAsFixed(2);
                  });
                }
              },
            ),
            Container(
              width: 70,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attach_money, size: ConfigService.smallIconSize),
                  Expanded(
                    child: Text(
                      _priceController.text,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                final currentPrice = double.tryParse(_priceController.text) ?? 0.0;
                setState(() {
                  _priceController.text = (currentPrice + 0.1).toStringAsFixed(2);
                });
              },
            ),
          ],
        ),
        
        // Action buttons
        SizedBox(height: ConfigService.largePadding),
        ModalBottomSheet.buildActions(
          context: context,
          onCancel: () => Navigator.of(context).pop(),
          onConfirm: () {
            Navigator.of(context).pop({
              'quantity': quantity,
              'expirationDate': expirationDate,
              'unitPrice': double.tryParse(_priceController.text) ?? 0.0,
            });
          },
          confirmText: 'Add',
        ),
      ],
    );
  }
}

// Helper method to show the bottom sheet
Future<Map<String, dynamic>?> showAddItemBottomSheet(
  BuildContext context, 
  ItemDefinition item,
  DialogService dialogService,
) {
  return ModalBottomSheet.show<Map<String, dynamic>>(
    context: context,
    builder: (context) => AddItemBottomSheet(
      item: item,
      dialogService: dialogService,
    ),
  );
}