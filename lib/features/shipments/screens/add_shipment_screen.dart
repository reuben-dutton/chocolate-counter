import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/common/services/dialog_service.dart';
import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/data/models/item_definition.dart';
import 'package:food_inventory/data/models/shipment.dart';
import 'package:food_inventory/data/models/shipment_item.dart';
import 'package:food_inventory/features/inventory/bloc/inventory_bloc.dart';
import 'package:food_inventory/features/shipments/bloc/shipment_bloc.dart';
import 'package:food_inventory/features/shipments/widgets/shipment_item_selector.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class AddShipmentScreen extends StatefulWidget {
  const AddShipmentScreen({super.key});

  @override
  _AddShipmentScreenState createState() => _AddShipmentScreenState();
}

class _AddShipmentScreenState extends State<AddShipmentScreen> {
  // Step 1: Select items
  List<ItemDefinition> _availableItems = [];
  final List<ShipmentItem> _selectedItems = [];
  bool _isLoading = true;
  
  // Step 2: Shipment details
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime _shipmentDate = DateTime.now();
  bool _isProcessing = false;
  
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    
    // Load inventory items when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryBloc>().add(const LoadInventoryItems());
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dialogService = Provider.of<DialogService>(context);
    
    return BlocListener<InventoryBloc, InventoryState>(
      listenWhen: (previous, current) => 
        current.items != previous.items ||
        current.isLoading != previous.isLoading ||
        (current.error != null && previous.error != current.error),
      listener: (context, inventoryState) {
        if (inventoryState.error != null) {
          ErrorHandler.showErrorSnackBar(
            context, 
            inventoryState.error!.message, 
            error: inventoryState.error!.error
          );
        }
        
        setState(() {
          _isLoading = inventoryState.isLoading;
          _availableItems = inventoryState.items.map((item) => item.itemDefinition).toList();
        });
      },
      child: BlocConsumer<ShipmentBloc, ShipmentState>(
        listenWhen: (previous, current) => 
          current.error != null && previous.error != current.error ||
          current.operationSuccess && !previous.operationSuccess,
        listener: (context, shipmentState) {
          if (shipmentState.error != null) {
            ErrorHandler.showErrorSnackBar(
              context, 
              shipmentState.error!.message, 
              error: shipmentState.error!.error
            );
            setState(() {
              _isProcessing = false;
            });
          }
          
          if (shipmentState.operationSuccess) {
            ErrorHandler.showSuccessSnackBar(context, 'Shipment added successfully');
            Navigator.pop(context);
          }
        },
        builder: (context, shipmentState) {
          final theme = Theme.of(context);
          
          return Scaffold(
            appBar: AppBar(
              title: Text(_currentStep == 0 ? 'Select Items' : 'Shipment Details'),
              actions: [
                if (_currentStep == 1)
                  IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: _isProcessing ? null : () => _saveShipment(context),
                  ),
              ],
            ),
            body: Column(
              children: [
                // Stepper indicator
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 4,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 4,
                          color: _currentStep == 1 
                              ? theme.colorScheme.primary 
                              : theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content area
                Expanded(
                  child: _isProcessing
                      ? const Center(child: CircularProgressIndicator())
                      : (_currentStep == 0 ? _buildItemsStep() : _buildDetailsStep(dialogService)),
                ),
                
                // Fixed bottom buttons
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.arrow_back, size: 16),
                        label: Text(_currentStep > 0 ? 'Back' : 'Cancel'),
                        onPressed: _isProcessing
                            ? null
                            : () {
                                if (_currentStep > 0) {
                                  setState(() {
                                    _currentStep--;
                                  });
                                } else {
                                  Navigator.pop(context);
                                }
                              },
                      ),
                      ElevatedButton.icon(
                        icon: Icon(
                          _currentStep == 0 ? Icons.arrow_forward : Icons.save,
                          size: 16,
                        ),
                        label: Text(_currentStep == 0 ? 'Continue' : 'Save'),
                        onPressed: _isProcessing
                            ? null
                            : () {
                                if (_currentStep == 0) {
                                  if (_selectedItems.isEmpty) {
                                    ErrorHandler.showErrorSnackBar(
                                      context, 
                                      'Please select at least one item'
                                    );
                                    return;
                                  }
                                  setState(() {
                                    _currentStep = 1;
                                  });
                                } else {
                                  _saveShipment(context);
                                }
                              },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemsStep() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_availableItems.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No items available. Please add some item definitions first.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ShipmentItemSelector(
        availableItems: _availableItems,
        selectedItems: _selectedItems,
        onItemsChanged: (items) {
          setState(() {
            _selectedItems.clear();
            _selectedItems.addAll(items);
          });
        },
      ),
    );
  }

  Widget _buildDetailsStep(DialogService dialogService) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shipment name (optional)
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Shipment Name (Optional)',
                  hintText: 'e.g., Monthly Grocery Delivery',
                  prefixIcon: Icon(Icons.label, size: 18),
                ),
              ),
              const SizedBox(height: 16),
              
              // Shipment date
              InkWell(
                onTap: () => _selectDate(context, dialogService),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Shipment Date',
                    prefixIcon: Icon(Icons.calendar_today, size: 18),
                  ),
                  child: Text(
                    dateFormat.format(_shipmentDate),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Summary
              Card(
                color: theme.colorScheme.surface,
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.summarize, size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Shipment Summary',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.inventory_2, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Items: ${_selectedItems.length}', 
                                  style: theme.textTheme.bodyMedium
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.shopping_bag, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Total: ${_selectedItems.fold<int>(0, (sum, item) => sum + item.quantity)}',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Selected items list
              Card(
                color: theme.colorScheme.surface,
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.list, size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Selected Items',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const Divider(),
                      
                      Container(
                        constraints: const BoxConstraints(maxHeight: 300),
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.colorScheme.outlineVariant),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: _selectedItems.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: theme.colorScheme.outlineVariant,
                          ),
                          itemBuilder: (context, index) {
                            final item = _selectedItems[index];
                            return ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              leading: Icon(
                                Icons.inventory_2,
                                size: 20,
                                color: theme.colorScheme.primary,
                              ),
                              title: Text(
                                item.itemDefinition?.name ?? 'Unknown Item',
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium,
                              ),
                              subtitle: item.expirationDate != null
                                  ? Row(
                                      children: [
                                        Icon(
                                          Icons.event_available, 
                                          size: 12, 
                                          color: theme.colorScheme.secondary
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          dateFormat.format(item.expirationDate!),
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                    )
                                  : null,
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${item.quantity}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _selectDate(BuildContext context, DialogService dialogService) async {
    try {
      final DateTime? picked = await dialogService.showCustomDatePicker(
        context: context,
        initialDate: _shipmentDate,
        firstDate: DateTime(2000),
        lastDate: DateTime.now().add(const Duration(days: 1)),
      );
      
      if (picked != null && picked != _shipmentDate) {
        setState(() {
          _shipmentDate = picked;
        });
      }
    } catch (e, stackTrace) {
      ErrorHandler.handleServiceError(
        context, 
        e, 
        service: 'Dialog',
        operation: 'date selection',
        stackTrace: stackTrace
      );
    }
  }

  Future<void> _saveShipment(BuildContext context) async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      // Create shipment
      final shipment = Shipment(
        name: _nameController.text.isNotEmpty ? _nameController.text : null,
        date: _shipmentDate,
        items: _selectedItems,
      );
      
      // Dispatch the create shipment event
      context.read<ShipmentBloc>().add(CreateShipment(shipment));
      
      // The listener will handle success and navigation
    } catch (e, stackTrace) {
      ErrorHandler.handleServiceError(
        context, 
        e, 
        service: 'Shipment',
        operation: 'creation',
        stackTrace: stackTrace
      );
      setState(() {
        _isProcessing = false;
      });
    }
  }
}