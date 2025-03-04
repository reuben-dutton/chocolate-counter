import 'package:flutter/material.dart';
import 'package:food_inventory/data/models/item_definition.dart';
import 'package:food_inventory/features/inventory/services/inventory_service.dart';
import 'package:food_inventory/features/inventory/services/image_service.dart';
import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/common/widgets/full_item_image_widget.dart';
import 'package:provider/provider.dart';
import 'dart:io';

class ItemEditScreen extends StatefulWidget {
  final ItemDefinition itemDefinition;

  const ItemEditScreen({
    super.key,
    required this.itemDefinition,
  });

  @override
  _ItemEditScreenState createState() => _ItemEditScreenState();
}

class _ItemEditScreenState extends State<ItemEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _barcodeController;
  File? _imageFile;
  String? _existingImagePath;
  bool _isUpdating = false;
  late ImageService _imageService;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.itemDefinition.name);
    _barcodeController = TextEditingController(text: widget.itemDefinition.barcode ?? '');
    _existingImagePath = widget.itemDefinition.imageUrl;
    
    // If there's an existing local image, initialize _imageFile
    if (_existingImagePath != null && !_existingImagePath!.startsWith('http')) {
      _imageFile = File(_existingImagePath!);
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _imageService = Provider.of<ImageService>(context, listen: false);
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
          _existingImagePath = null; // Clear existing image path
        });
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, 'Failed to take photo', error: e);
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final pickedFile = await _imageService.pickPhoto();
      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
          _existingImagePath = null; // Clear existing image path
        });
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, 'Failed to pick photo', error: e);
    }
  }
  
  Future<void> _removePhoto() async {
    // Delete the existing image if it's a local file
    if (_existingImagePath != null && !_existingImagePath!.startsWith('http')) {
      await _imageService.deleteImage(_existingImagePath);
    }
    
    setState(() {
      _imageFile = null;
      _existingImagePath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Item'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isUpdating ? null : _updateItem,
          ),
        ],
      ),
      body: _isUpdating
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image at the top
                    _buildImagePreview(),
                    
                    Padding(
                      padding: const EdgeInsets.all(16.0),
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
                          
                          // Image controls
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.camera_alt, size: 16),
                                label: const Text('Camera'),
                                onPressed: _takePhoto,
                              ),
                              const SizedBox(width: 16),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.photo_library, size: 16),
                                label: const Text('Gallery'),
                                onPressed: _pickPhoto,
                              ),
                            ],
                          ),
                          if (_imageFile != null || _existingImagePath != null) ...[
                            const SizedBox(height: 8),
                            Center(
                              child: TextButton.icon(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                                label: const Text('Remove Image', 
                                  style: TextStyle(color: Colors.red, fontSize: 12)
                                ),
                                onPressed: _removePhoto,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildImagePreview() {
    if (_imageFile != null) {
      return Image.file(
        _imageFile!,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
      );
    } else if (_existingImagePath != null) {
      return FullItemImageWidget(
        imagePath: _existingImagePath,
        itemName: widget.itemDefinition.name,
        imageService: _imageService,
        height: 200,
      );
    } else {
      // No image
      return Container(
        width: double.infinity,
        height: 200,
        color: Colors.grey.shade300,
        child: const Icon(
          Icons.camera_alt,
          size: 60,
          color: Colors.white,
        ),
      );
    }
  }

  Future<void> _updateItem() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isUpdating = true;
    });

    try {
      final inventoryService = Provider.of<InventoryService>(context, listen: false);
      
      // Save image and get the path
      String? imagePath;
      if (_imageFile != null) {
        imagePath = await _imageService.saveImage(_imageFile);
      } else {
        imagePath = _existingImagePath;
      }
      
      final updatedItem = widget.itemDefinition.copyWith(
        name: _nameController.text,
        barcode: _barcodeController.text.isEmpty ? null : _barcodeController.text,
        imageUrl: imagePath,
      );
      
      await inventoryService.updateItemDefinition(updatedItem);
      
      ErrorHandler.showSuccessSnackBar(context, 'Item updated');
      
      Navigator.pop(context, updatedItem);
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, 'Error updating item', error: e);
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }
}