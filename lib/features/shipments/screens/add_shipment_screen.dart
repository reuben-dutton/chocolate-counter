import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/common/services/dialog_service.dart';
import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/common/utils/navigation_utils.dart';
import 'package:food_inventory/data/models/shipment.dart';
import 'package:food_inventory/data/models/shipment_item.dart';
import 'package:food_inventory/features/inventory/bloc/inventory_bloc.dart' as inventory;
import 'package:food_inventory/features/inventory/services/inventory_service.dart';
import 'package:food_inventory/features/shipments/bloc/shipment_bloc.dart';
import 'package:food_inventory/features/shipments/screens/select_items_screen.dart';
import 'package:food_inventory/features/shipments/services/shipment_service.dart';
import 'package:food_inventory/features/shipments/widgets/selected_shipment_item_tile.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class AddShipmentScreen extends StatefulWidget {
  const AddShipmentScreen({super.key});

  @override
  _AddShipmentScreenState createState() => _AddShipmentScreenState();
}

class _AddShipmentScreenState extends State<AddShipmentScreen> {
  // Selected items
  final List<ShipmentItem> _selectedItems = [];
  bool _isLoading = false;
  
  // Shipment details
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime _shipmentDate = DateTime.now();
  bool _isProcessing = false;
  
  int _currentStep = 0;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dialogService = Provider.of<DialogService>(context);
    final inventoryService = Provider.of<InventoryService>(context, listen: false);
    final shipmentService = Provider.of<ShipmentService>(context, listen: false);
    
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => inventory.InventoryBloc(inventoryService),
        ),
        BlocProvider(
          create: (context) => ShipmentBloc(shipmentService),
        ),
      ],
      child: BlocListener<inventory.InventoryBloc, inventory.InventoryState>(
        listenWhen: (previous, current) => 
          current.error != null && previous.error != current.error,
        listener: (context, inventoryState) {
          if (inventoryState.error != null) {
            ErrorHandler.showErrorSnackBar(
              context, 
              inventoryState.error!.message, 
              error: inventoryState.error!.error
            );
          }
        },
        child: BlocConsumer<ShipmentBloc, ShipmentState>(
          listenWhen: (previous, current) => 
            current.error != null && previous.error != current.error ||
            current is OperationResult,
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
            
            if (shipmentState is OperationResult && shipmentState.success) {
              ErrorHandler.showSuccessSnackBar(context, 'Shipment added successfully');
              Navigator.pop(context);
            }
          },
          builder: (context, shipmentState) {
            final theme = Theme.of(context);
            
            return Scaffold(
              appBar: AppBar(
                title: Text(_currentStep == 0 ? 'Add Items' : 'Shipment Details'),
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
      ),
    );
  }

  Widget _buildItemsStep() {
    final theme = Theme.of(context);
    
    return Stack(
      children: [
        // Selected items list
        _selectedItems.isEmpty 
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 64,
                      color: theme.colorScheme.onSurface.withAlpha(100),
                    ),
                    const SizedBox(height: 16),
                    const Text('No items selected'),
                    const SizedBox(height: 16),
                    const Text('Tap the button below to add items')
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: _selectedItems.length,
                itemBuilder: (context, index) {
                  return SelectedShipmentItemTile(
                    key: ValueKey(_selectedItems[index].itemDefinitionId),
                    item: _selectedItems[index],
                    onEdit: (quantity, expirationDate, unitPrice) => _updateItem(index, quantity, expirationDate, unitPrice),
                    onRemove: () => _removeItem(index),
                  );
                },
              ),
        
        // Add item button
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () => _navigateToSelectItems(context),
          ),
        ),
      ],
    );
  }
  
  void _navigateToSelectItems(BuildContext context) async {
    final result = await NavigationUtils.navigateWithSlide<ShipmentItem>(
      context,
      SelectItemsScreen(),
    );
    
    if (result != null) {
      _addItem(result);
    }
  }
  
  void _addItem(ShipmentItem item) {
    final existingIndex = _selectedItems.indexWhere(
      (selected) => selected.itemDefinitionId == item.itemDefinitionId,
    );
    
    if (existingIndex != -1) {
      _updateItem(
        existingIndex, 
        _selectedItems[existingIndex].quantity + item.quantity, 
        item.expirationDate,
        item.unitPrice
      );
    } else {
      setState(() {
        _selectedItems.add(item);
      });
    }
  }
  
  void _updateItem(int index, int quantity, DateTime? expirationDate, double? unitPrice) {
    setState(() {
      final updatedItem = ShipmentItem(
        id: _selectedItems[index].id,
        shipmentId: _selectedItems[index].shipmentId,
        itemDefinitionId: _selectedItems[index].itemDefinitionId,
        quantity: quantity,
        expirationDate: expirationDate,
        unitPrice: unitPrice,
        itemDefinition: _selectedItems[index].itemDefinition,
      );
      
      _selectedItems[index] = updatedItem;
    });
  }
  
  void _removeItem(int index) {
    setState(() {
      _selectedItems.removeAt(index);
    });
  }

  Widget _buildDetailsStep(DialogService dialogService) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final theme = Theme.of(context);
    
    // Calculate total cost
    double totalCost = 0.0;
    for (var item in _selectedItems) {
      if (item.unitPrice != null) {
        totalCost += item.unitPrice! * item.quantity;
      }
    }
    
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
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.monetization_on, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Total Cost: ${ConfigService.formatCurrency(totalCost)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
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
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (item.expirationDate != null)
                                    Row(
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
                                    ),
                                  if (item.unitPrice != null)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.attach_money, 
                                          size: 12, 
                                          color: theme.colorScheme.secondary
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${ConfigService.formatCurrency(item.unitPrice!)} × ${item.quantity}',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                ],
                              ),
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