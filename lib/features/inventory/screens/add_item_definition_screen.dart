import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/common/services/service_locator.dart';
import 'package:food_inventory/data/models/item_definition.dart';
import 'package:food_inventory/features/inventory/bloc/inventory_bloc.dart';
import 'package:food_inventory/features/inventory/services/image_service.dart';
import 'package:provider/provider.dart';
import 'dart:io';

class AddItemDefinitionScreen extends StatefulWidget {
  const AddItemDefinitionScreen({super.key});

  @override
  _AddItemDefinitionScreenState createState() => _AddItemDefinitionScreenState();
}

class _AddItemDefinitionScreenState extends State<AddItemDefinitionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  File? _imageFile;
  bool _isCreating = false;
  late ImageService _imageService;
  late InventoryBloc _inventoryBloc;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _imageService = Provider.of<ImageService>(context, listen: false);
      _inventoryBloc = ServiceLocator.instance<InventoryBloc>();
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    try {
      final pickedFile = await _imageService.takePhoto();
      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
        });
      }
    } catch (e, stackTrace) {
      ErrorHandler.handleServiceError(
        context, 
        e, 
        service: 'Image',
        operation: 'taking photo',
        stackTrace: stackTrace
      );
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final pickedFile = await _imageService.pickPhoto();
      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
        });
      }
    } catch (e, stackTrace) {
      ErrorHandler.handleServiceError(
        context, 
        e, 
        service: 'Image',
        operation: 'picking photo',
        stackTrace: stackTrace
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Item'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isCreating ? null : _saveItem,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Item Name *',
                    hintText: 'e.g., Snickers Bar',
                    isDense: true,
                    prefixIcon: Icon(Icons.label, size: 18),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an item name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _barcodeController,
                  decoration: const InputDecoration(
                    labelText: 'Barcode (Optional)',
                    hintText: 'e.g., 012345678912',
                    isDense: true,
                    prefixIcon: Icon(Icons.qr_code, size: 18),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Image picker
                Center(
                  child: Column(
                    children: [
                      const Text(
                        'Item Image (Optional)',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _imageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _imageFile!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt,
                                size: 60,
                                color: Colors.grey,
                              ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.camera_alt, size: 18),
                            label: const Text('Camera'),
                            onPressed: _takePhoto,
                          ),
                          const SizedBox(width: 16),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.photo_library, size: 18),
                            label: const Text('Gallery'),
                            onPressed: _pickPhoto,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (_isCreating)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
    });

    try {
      // Save image to app directory and get the path
      final imagePath = await _imageService.saveImage(_imageFile);
      
      final itemDefinition = ItemDefinition(
        name: _nameController.text,
        barcode: _barcodeController.text.isEmpty ? null : _barcodeController.text,
        imageUrl: imagePath, // Now stores local file path instead of URL
      );
      
      final success = await _inventoryBloc.createItemDefinition(itemDefinition);
      
      if (success) {
        ErrorHandler.showSuccessSnackBar(context, 'Item added successfully');
        Navigator.pop(context);
      } else {
        ErrorHandler.showErrorSnackBar(context, 'Error creating item');
      }
    } catch (e, stackTrace) {
      ErrorHandler.handleServiceError(
        context, 
        e, 
        service: 'Item',
        operation: 'creation',
        stackTrace: stackTrace
      );
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }
}