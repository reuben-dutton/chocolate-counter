import 'package:flutter/material.dart';
import 'package:food_inventory/data/models/shipment_item.dart';
import 'package:food_inventory/common/services/dialog_service.dart';
import 'package:food_inventory/common/widgets/expiration_date_widget.dart';

// Dialog for editing an existing item
class EditItemDialog extends StatefulWidget {
  final ShipmentItem item;
  final DialogService dialogService;

  const EditItemDialog({
    super.key,
    required this.item,
    required this.dialogService,
  });

  @override
  State<EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<EditItemDialog> {
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
    
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.edit, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Edit ${widget.item.itemDefinition?.name ?? 'Item'}',
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quantity selector
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
          
          // Add price input with increment/decrement
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
                    Text(
                      _priceController.text,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.check, size: 16),
          label: const Text('Update'),
          onPressed: () {
            Navigator.of(context).pop({
              'quantity': quantity,
              'expirationDate': expirationDate,
              'unitPrice': double.tryParse(_priceController.text) ?? 0.0,
            });
          },
        ),
      ],
    );
  }
}