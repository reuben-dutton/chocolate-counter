import 'package:flutter/material.dart';
import 'package:food_inventory/models/item_definition.dart';
import 'package:food_inventory/services/dialog_service.dart';
import 'package:food_inventory/widgets/common/expiration_date_widget.dart';


// Dialog for adding a new item
class AddItemDialog extends StatefulWidget {
  final ItemDefinition item;
  final DialogService dialogService;

  const AddItemDialog({
    super.key,
    required this.item,
    required this.dialogService,
  });

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  int quantity = 1;
  DateTime? expirationDate;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: Row(
        children: [
          const Icon(Icons.add_circle, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Add ${widget.item.name}',
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
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add'),
          onPressed: () {
            Navigator.of(context).pop({
              'quantity': quantity,
              'expirationDate': expirationDate,
            });
          },
        ),
      ],
    );
  }
}