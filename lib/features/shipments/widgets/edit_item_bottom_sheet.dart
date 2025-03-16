import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/dialog_service.dart';
import 'package:food_inventory/common/widgets/expiration_date_widget.dart';
import 'package:food_inventory/common/widgets/modal_bottom_sheet.dart';
import 'package:food_inventory/data/models/shipment_item.dart';

class EditItemBottomSheet extends StatefulWidget {
  final ShipmentItem item;
  final DialogService dialogService;

  const EditItemBottomSheet({
    Key? key,
    required this.item,
    required this.dialogService,
  }) : super(key: key);

  @override
  State<EditItemBottomSheet> createState() => _EditItemBottomSheetState();
}

class _EditItemBottomSheetState extends State<EditItemBottomSheet> {
  late int quantity;
  late DateTime? expirationDate;
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    quantity = widget.item.quantity;
    expirationDate = widget.item.expirationDate;
    _priceController = TextEditingController(
      text: widget.item.unitPrice?.toStringAsFixed(2) ?? '0.00'
    );
  }

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
        // Header
        ModalBottomSheet.buildHeader(
          context: context,
          title: 'Edit ${widget.item.itemDefinition?.name ?? 'Item'}',
          icon: Icons.edit,
          onClose: () => Navigator.of(context).pop(),
        ),
        
        // Main content
        // Quantity selector
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Quantity: '),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: quantity > 1
                  ? () => setState(() => quantity--)
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              '$quantity',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => setState(() => quantity++),
            ),
          ],
        ),
        
        // Expiration date selector
        const SizedBox(height: 16),
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: const Text('Expiration Date (Optional)'),
          subtitle: ExpirationDateWidget(
            expirationDate: expirationDate,
            showIcon: false,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.calendar_today, size: 20),
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
        
        // Price input
        const SizedBox(height: 16),
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
                  const Icon(Icons.attach_money, size: 16),
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
        
        // Actions
        const SizedBox(height: 24),
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
          confirmText: 'Update',
        ),
      ],
    );
  }
}

// Helper method to show the bottom sheet
Future<Map<String, dynamic>?> showEditItemBottomSheet(
  BuildContext context, 
  ShipmentItem item,
  DialogService dialogService,
) {
  return ModalBottomSheet.show<Map<String, dynamic>>(
    context: context,
    builder: (context) => EditItemBottomSheet(
      item: item,
      dialogService: dialogService,
    ),
  );
}