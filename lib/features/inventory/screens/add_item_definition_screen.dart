import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/data/models/item_definition.dart';
import 'package:food_inventory/data/repositories/item_definition_repository.dart';
import 'package:food_inventory/data/repositories/item_instance_repository.dart';
import 'package:food_inventory/features/inventory/cubit/item_definition_cubit.dart';
import 'package:food_inventory/features/inventory/event_bus/inventory_event_bus.dart';
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
  late ItemDefinitionCubit _itemDefinitionCubit;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Get repositories from Provider
    final itemDefinitionRepository = Provider.of<ItemDefinitionRepository>(context, listen: false);
    final itemInstanceRepository = Provider.of<ItemInstanceRepository>(context, listen: false);
    final inventoryEventBus = Provider.of<InventoryEventBus>(context, listen: false);
    
    // Initialize cubit
    _itemDefinitionCubit = ItemDefinitionCubit(
      itemDefinitionRepository,
      itemInstanceRepository,
      inventoryEventBus,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _itemDefinitionCubit.close();
    super.dispose();
  }

  Future<void> _takePhoto(ImageService imageService) async {
    try {
      final pickedFile = await imageService.takePhoto();
      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
        });
      }
    } catch (e, stackTrace) {
      if (!mounted) {
        return;
      }
      ErrorHandler.handleServiceError(
        context, 
        e, 
        service: 'Image',
        operation: 'taking photo',
        stackTrace: stackTrace
      );
    }
  }

  Future<void> _pickPhoto(ImageService imageService) async {
    try {
      final pickedFile = await imageService.pickPhoto();
      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
        });
      }
    } catch (e, stackTrace) {
      if (!mounted) {
        return;
      }
      ErrorHandler.handleServiceError(
        context, 
        e, 
        service: 'Image',
        operation: 'picking photo',
        stackTrace: stackTrace
      );
    }
  }

  Future<void> _saveItem(BuildContext context, ImageService imageService) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
    });

    try {
      // Save image to app directory and get the path
      final imagePath = await imageService.saveImage(_imageFile);
      
      final itemDefinition = ItemDefinition(
        name: _nameController.text,
        barcode: _barcodeController.text.isEmpty ? null : _barcodeController.text,
        imageUrl: imagePath, // Now stores local file path instead of URL
      );
      
      // Use the cubit to create the item
      _itemDefinitionCubit.createItemDefinition(itemDefinition);
      
      // The listener will handle success and navigation
    } catch (e, stackTrace) {
      ErrorHandler.handleServiceError(
        context, 
        e, 
        service: 'Item',
        operation: 'creation',
        stackTrace: stackTrace
      );
      setState(() {
        _isCreating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageService = Provider.of<ImageService>(context);
    
    return BlocProvider.value(
      value: _itemDefinitionCubit,
      child: BlocConsumer<ItemDefinitionCubit, ItemDefinitionState>(
        listenWhen: (previous, current) => 
          current.error != null && previous.error != current.error ||
          current is OperationResult,
        listener: (context, state) {
          if (state.error != null) {
            ErrorHandler.showErrorSnackBar(context, state.error!.message, error: state.error!.error);
            setState(() {
              _isCreating = false;
            });
          }
          
          if (state is OperationResult && state.success) {
            // Item was created successfully
            ErrorHandler.showSuccessSnackBar(context, 'Item added successfully');
            Navigator.pop(context);
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Add Item'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: _isCreating ? null : () => _saveItem(context, imageService),
                ),
              ],
            ),
            body: Padding(
              padding: EdgeInsets.all(ConfigService.smallPadding),
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
                          prefixIcon: Icon(Icons.label, size: ConfigService.mediumIconSize),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an item name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: ConfigService.mediumPadding),
                      TextFormField(
                        controller: _barcodeController,
                        decoration: const InputDecoration(
                          labelText: 'Barcode (Optional)',
                          hintText: 'e.g., 012345678912',
                          isDense: true,
                          prefixIcon: Icon(Icons.qr_code, size: ConfigService.mediumIconSize),
                        ),
                      ),
                      SizedBox(height: ConfigService.defaultPadding),
                      
                      // Image picker
                      Center(
                        child: Column(
                          children: [
                            const Text(
                              'Item Image (Optional)',
                              style: TextStyle(fontSize: 14),
                            ),
                            SizedBox(height: ConfigService.smallPadding),
                            Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(ConfigService.borderRadiusSmall),
                              ),
                              child: _imageFile != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(ConfigService.borderRadiusSmall),
                                      child: Image.file(
                                        _imageFile!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.camera_alt,
                                      size: ConfigService.xLargeIconSize,
                                      color: Colors.grey,
                                    ),
                            ),
                            SizedBox(height: ConfigService.defaultPadding),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.camera_alt, size: ConfigService.mediumIconSize),
                                  label: const Text('Camera'),
                                  onPressed: () => _takePhoto(imageService),
                                ),
                                SizedBox(width: ConfigService.defaultPadding),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.photo_library, size: ConfigService.mediumIconSize),
                                  label: const Text('Gallery'),
                                  onPressed: () => _pickPhoto(imageService),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: ConfigService.largePadding),
                      if (_isCreating)
                        const Center(child: CircularProgressIndicator()),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}