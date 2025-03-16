import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/data/models/item_definition.dart';

class ItemEditDialog extends StatefulWidget {
  final ItemDefinition itemDefinition;

  const ItemEditDialog({
    super.key,
    required this.itemDefinition,
  });

  @override
  _ItemEditDialogState createState() => _ItemEditDialogState();
}

class _ItemEditDialogState extends State<ItemEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _barcodeController;
  late TextEditingController _imageUrlController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.itemDefinition.name);
    _barcodeController = TextEditingController(text: widget.itemDefinition.barcode ?? '');
    _imageUrlController = TextEditingController(text: widget.itemDefinition.imageUrl ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.edit, size: ConfigService.defaultIconSize),
          const SizedBox(width: ConfigService.smallPadding),
          const Text('Edit Item')
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                isDense: true,
                prefixIcon: Icon(Icons.label, size: ConfigService.mediumIconSize),
              ),
            ),
            TextField(
              controller: _barcodeController,
              decoration: const InputDecoration(
                labelText: 'Barcode (Optional)',
                isDense: true,
                prefixIcon: Icon(Icons.qr_code, size: ConfigService.mediumIconSize),
              ),
            ),
            TextField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'Image URL (Optional)',
                isDense: true,
                prefixIcon: Icon(Icons.image, size: ConfigService.mediumIconSize),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(Icons.close),
        ),
        ElevatedButton(
          onPressed: () {
            final updatedItem = widget.itemDefinition.copyWith(
              name: _nameController.text,
              barcode: _barcodeController.text.isEmpty ? null : _barcodeController.text,
              imageUrl: _imageUrlController.text.isEmpty ? null : _imageUrlController.text,
            );
            Navigator.of(context).pop(updatedItem);
          },
          child: const Icon(Icons.save),
        ),
      ],
    );
  }
}