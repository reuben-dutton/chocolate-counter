import 'package:flutter/material.dart';
import 'package:food_inventory/models/item_definition.dart';
import 'package:food_inventory/services/inventory_service.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

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
  final ImagePicker _picker = ImagePicker();

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
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _existingImagePath = null; // Clear existing image path
      });
    }
  }

  Future<void> _pickPhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _existingImagePath = null; // Clear existing image path
      });
    }
  }
  
  Future<void> _removePhoto() async {
    setState(() {
      _imageFile = null;
      _existingImagePath = null;
    });
  }

  Future<String?> _saveImage() async {
    if (_imageFile == null) return null;
    
    // If the image path is the same as the existing one, don't save again
    if (_existingImagePath != null && _existingImagePath == _imageFile!.path) {
      return _existingImagePath;
    }

    try {
      // Get application documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'item_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await _imageFile!.copy('${appDir.path}/$fileName');
      return savedImage.path;
    } catch (e) {
      print('Error saving image: $e');
      return null;
    }
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
    // New image selected
    if (_imageFile != null) {
      return Image.file(
        _imageFile!,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
      );
    }
    
    // Existing image path
    if (_existingImagePath != null) {
      try {
        if (_existingImagePath!.startsWith('http')) {
          // Remote URL
          return Image.network(
            _existingImagePath!,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: double.infinity,
                height: 200,
                color: Colors.grey.shade300,
                child: const Icon(
                  Icons.image_not_supported,
                  size: 60,
                  color: Colors.white,
                ),
              );
            },
          );
        } else {
          // Local file path
          return Image.file(
            File(_existingImagePath!),
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: double.infinity,
                height: 200,
                color: Colors.grey.shade300,
                child: const Icon(
                  Icons.image_not_supported,
                  size: 60,
                  color: Colors.white,
                ),
              );
            },
          );
        }
      } catch (e) {
        print('Error loading existing image: $e');
      }
    }
    
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

  Future<void> _updateItem() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isUpdating = true;
    });

    try {
      final inventoryService = Provider.of<InventoryService>(context, listen: false);
      
      // Determine the image path to save
      String? imagePath;
      if (_imageFile != null) {
        imagePath = await _saveImage();
      } else {
        imagePath = _existingImagePath;
      }
      
      final updatedItem = widget.itemDefinition.copyWith(
        name: _nameController.text,
        barcode: _barcodeController.text.isEmpty ? null : _barcodeController.text,
        imageUrl: imagePath,
      );
      
      await inventoryService.updateItemDefinition(updatedItem);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item updated')),
      );
      
      Navigator.pop(context, updatedItem);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating item: $e')),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }
}