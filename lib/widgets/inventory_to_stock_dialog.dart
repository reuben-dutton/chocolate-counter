import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InventoryToStockDialog extends StatefulWidget {
  final int currentInventory;

  const InventoryToStockDialog({
    super.key,
    required this.currentInventory,
  });

  @override
  _InventoryToStockDialogState createState() => _InventoryToStockDialogState();
}

class _InventoryToStockDialogState extends State<InventoryToStockDialog> {
  late TextEditingController _quantityController;
  late int _quantity;
  DateTime _timestamp = DateTime.now();

  @override
  void initState() {
    super.initState();
    _quantity = 1;
    _quantityController = TextEditingController(text: _quantity.toString());
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    final theme = Theme.of(context);
    
    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      title: Row(
        children: [
          const Icon(Icons.move_up, size: 20),
          const SizedBox(width: 8),
          const Text('Move to Stock')
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Current inventory: ${widget.currentInventory}'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _quantity > 1 ? () => _updateQuantity(_quantity - 1) : null,
              ),
              SizedBox(
                width: 50,
                child: TextField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  onChanged: (value) {
                    final newValue = int.tryParse(value);
                    if (newValue != null && newValue > 0 && newValue <= widget.currentInventory) {
                      setState(() {
                        _quantity = newValue;
                      });
                    }
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _quantity < widget.currentInventory
                    ? () => _updateQuantity(_quantity + 1)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _selectDateTime(context),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Timestamp',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(_timestamp),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
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
          icon: const Icon(Icons.move_up, size: 16),
          label: const Text('Move'),
          onPressed: () {
            Navigator.of(context).pop(_quantity);
          },
        ),
      ],
    );
  }

  void _updateQuantity(int newQuantity) {
    setState(() {
      _quantity = newQuantity;
      _quantityController.text = _quantity.toString();
    });
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _timestamp,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_timestamp),
      );
      
      if (pickedTime != null) {
        setState(() {
          _timestamp = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }
}