import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/data/models/item_definition.dart';
import 'package:food_inventory/data/models/shipment_item.dart';
import 'package:food_inventory/common/services/dialog_service.dart';
import 'package:food_inventory/features/shipments/widgets/add_item_bottom_sheet.dart';
import 'package:food_inventory/features/shipments/widgets/selected_shipment_item_tile.dart';
import 'package:food_inventory/features/shipments/widgets/available_item_tile.dart';
import 'package:food_inventory/common/widgets/section_header_widget.dart';
import 'package:food_inventory/features/inventory/bloc/inventory_bloc.dart' as inventory;
import 'package:food_inventory/features/inventory/screens/add_item_definition_screen.dart';
import 'package:food_inventory/common/utils/navigation_utils.dart';
import 'package:provider/provider.dart';

class ShipmentItemSelector extends StatefulWidget {
  final List<ItemDefinition> availableItems;
  final List<ShipmentItem> selectedItems;
  final Function(List<ShipmentItem>) onItemsChanged;

  const ShipmentItemSelector({
    super.key,
    required this.availableItems,
    required this.selectedItems,
    required this.onItemsChanged,
  });

  @override
  _ShipmentItemSelectorState createState() => _ShipmentItemSelectorState();
}

class _ShipmentItemSelectorState extends State<ShipmentItemSelector> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late List<ShipmentItem> _selectedItems;
  DialogService? _dialogService;
  bool _initialized = false;
  
  @override
  void initState() {
    super.initState();
    _selectedItems = List.from(widget.selectedItems);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _dialogService = Provider.of<DialogService>(context, listen: false);
      _initialized = true;
    }
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = widget.availableItems
        .where((item) => item.name.toLowerCase().contains(_searchQuery))
        .toList();
    final theme = Theme.of(context);
        
    return Column(
      children: [
        // Available items
        Expanded(
          child: Card(
            color: theme.colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(ConfigService.tinyPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeaderWidget(
                    title: 'Available Items',
                    icon: Icons.list,
                    iconColor: theme.colorScheme.secondary,
                  ),
                  const SizedBox(height: ConfigService.tinyPadding),
                  Expanded(
                    child: filteredItems.isEmpty
                        ? const Center(child: Text('No matching items found'))
                        : ListView.builder(
                            itemCount: filteredItems.length,
                            itemBuilder: (context, index) {
                              return AvailableItemTile(
                                item: filteredItems[index],
                                onAdd: _showAddItemDialog,
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Selected items
        if (_selectedItems.isNotEmpty) ...[
          const SizedBox(height: ConfigService.mediumPadding),
          Card(
            color: theme.colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(ConfigService.smallPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeaderWidget(
                    title: 'Selected Items',
                    icon: Icons.check_circle,
                    iconColor: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: ConfigService.tinyPadding),
                  Container(
                    constraints: BoxConstraints(
                      maxHeight: _selectedItems.length > 2 ? 150 : 100,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _selectedItems.length,
                      itemBuilder: (context, index) {
                        return SelectedShipmentItemTile(
                          key: ValueKey(_selectedItems[index].itemDefinitionId),
                          item: _selectedItems[index],
                          onEdit: (quantity, expirationDate, unitPrice) => 
                              _updateItem(index, quantity, expirationDate, unitPrice),
                          onRemove: () => _removeItem(index),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: ConfigService.mediumPadding),
        ],
        
        // Search and Add Item section
        Container(
          padding: const EdgeInsets.symmetric(horizontal: ConfigService.smallPadding, vertical: ConfigService.smallPadding),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                offset: const Offset(0, -2),
                blurRadius: 4,
              )
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search items...',
                    prefixIcon: const Icon(Icons.search, size: ConfigService.defaultIconSize),
                    suffixIcon: _searchQuery.isNotEmpty 
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: ConfigService.mediumIconSize),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: ConfigService.smallPadding, vertical: ConfigService.smallPadding),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ConfigService.borderRadiusLarge),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.withAlpha(ConfigService.alphaLight),
                  ),
                ),
              ),
              const SizedBox(width: ConfigService.smallPadding),
              IconButton(
                icon: const Icon(Icons.add_box),
                tooltip: 'Add New Item',
                onPressed: () => _navigateToAddItemDefinition(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _navigateToAddItemDefinition(BuildContext context) {
    NavigationUtils.navigateWithSlide(
      context,
      const AddItemDefinitionScreen(),
    ).then((_) {
      context.read<inventory.InventoryBloc>().add(const inventory.LoadInventoryItems());
    });
  }

  void _showAddItemDialog(ItemDefinition item) async {
    if (_dialogService == null) return;
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddItemBottomSheet(
        item: item,
        dialogService: _dialogService!,
      ),
    );
    
    if (result != null) {
      _addItem(
        item, 
        result['quantity'], 
        result['expirationDate'],
        result['unitPrice']
      );
    }
  }
  
  void _addItem(ItemDefinition item, int quantity, DateTime? expirationDate, double unitPrice) {
    final existingIndex = _selectedItems.indexWhere(
      (selected) => selected.itemDefinitionId == item.id,
    );
    
    if (existingIndex != -1) {
      _updateItem(
        existingIndex, 
        _selectedItems[existingIndex].quantity + quantity, 
        expirationDate,
        unitPrice
      );
    } else {
      final newItems = List<ShipmentItem>.from(_selectedItems);
      newItems.add(
        ShipmentItem(
          shipmentId: -1,
          itemDefinitionId: item.id!,
          quantity: quantity,
          expirationDate: expirationDate,
          unitPrice: unitPrice,
          itemDefinition: item,
        ),
      );
      
      setState(() {
        _selectedItems = newItems;
      });
      widget.onItemsChanged(_selectedItems);
    }
  }
  
  void _updateItem(int index, int quantity, DateTime? expirationDate, double? unitPrice) {
    final updatedItem = ShipmentItem(
      id: _selectedItems[index].id,
      shipmentId: _selectedItems[index].shipmentId,
      itemDefinitionId: _selectedItems[index].itemDefinitionId,
      quantity: quantity,
      expirationDate: expirationDate,
      unitPrice: unitPrice,
      itemDefinition: _selectedItems[index].itemDefinition,
    );
    
    final newItems = List<ShipmentItem>.from(_selectedItems);
    newItems[index] = updatedItem;
    
    setState(() {
      _selectedItems = newItems;
    });
    widget.onItemsChanged(_selectedItems);
  }
  
  void _removeItem(int index) {
    final newItems = List<ShipmentItem>.from(_selectedItems);
    newItems.removeAt(index);
    
    setState(() {
      _selectedItems = newItems;
    });
    widget.onItemsChanged(_selectedItems);
  }
}