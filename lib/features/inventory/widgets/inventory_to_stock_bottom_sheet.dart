import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/common/widgets/modal_bottom_sheet.dart';
import 'package:intl/intl.dart';

class InventoryToStockBottomSheet extends StatefulWidget {
  final int currentInventory;

  const InventoryToStockBottomSheet({
    Key? key,
    required this.currentInventory,
  }) : super(key: key);

  @override
  _InventoryToStockBottomSheetState createState() => _InventoryToStockBottomSheetState();
}

class _InventoryToStockBottomSheetState extends State<InventoryToStockBottomSheet> {
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
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        ModalBottomSheet.buildHeader(
          context: context,
          title: 'Move to Stock',
          icon: Icons.move_up,
          onClose: () => Navigator.of(context).pop(),
        ),
        
        // Current inventory
        Text('Current inventory: ${widget.currentInventory}'),
        const SizedBox(height: 16),
        
        // Quantity selector
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: _quantity > 1 
                  ? () => _updateQuantity(_quantity - 1) 
                  : null,
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
        
        // Timestamp selector
        SizedBox(height: ConfigService.defaultPadding),
        InkWell(
          onTap: () => _selectDateTime(context),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Timestamp',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: ConfigService.smallPadding, vertical: ConfigService.smallPadding),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: ConfigService.smallIconSize),
                SizedBox(width: ConfigService.tinyPadding),
                Text(
                  dateFormat.format(_timestamp),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        
        // Actions
        SizedBox(height: ConfigService.largePadding),
        ModalBottomSheet.buildActions(
          context: context,
          onCancel: () => Navigator.of(context).pop(),
          onConfirm: () => Navigator.of(context).pop(_quantity),
          confirmText: 'Move',
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

// Helper method to show the bottom sheet
Future<int?> showInventoryToStockBottomSheet(
  BuildContext context, 
  int currentInventory,
) {
  return ModalBottomSheet.show<int>(
    context: context,
    builder: (context) => InventoryToStockBottomSheet(
      currentInventory: currentInventory,
    ),
  );
}