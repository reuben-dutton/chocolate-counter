import 'package:flutter/material.dart';
import 'package:food_inventory/data/models/item_definition.dart';
import 'package:food_inventory/data/models/shipment_item.dart';
import 'package:food_inventory/common/services/dialog_service.dart';
import 'package:food_inventory/common/utils/gesture_handler.dart';
import 'package:food_inventory/common/utils/navigation_utils.dart';
import 'package:food_inventory/features/inventory/screens/add_item_definition_screen.dart';
import 'package:food_inventory/features/shipments/widgets/selected_shipment_item_tile.dart';
import 'package:food_inventory/features/shipments/widgets/available_item_tile.dart';
import 'package:food_inventory/features/shipments/widgets/add_item_dialog.dart';
import 'package:food_inventory/common/widgets/section_header_widget.dart';
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
    // Create a new list to avoid modifying the original
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
    // This is the safe place to access inherited widgets
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
    // Filter items only when building - avoid doing this during callbacks
    final filteredItems = widget.availableItems
        .where((item) => item.name.toLowerCase().contains(_searchQuery))
        .toList();
    final theme = Theme.of(context);
        
    return Column(
      children: [
        // Search bar
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Search items',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _searchQuery.isNotEmpty 
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => _searchController.clear(),
                )
              : null,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey.withAlpha(25),
          ),
        ),
        const SizedBox(height: 12),
        
        // Selected items
        if (_selectedItems.isNotEmpty) ...[
          Card(
            color: theme.colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeaderWidget(
                    title: 'Selected Items',
                    icon: Icons.check_circle,
                    iconColor: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    constraints: BoxConstraints(
                      maxHeight: _selectedItems.length > 2 ? 150 : 100,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _selectedItems.length,
                      itemBuilder: (context, index) {
                        // Extract each item into its own stateful widget to prevent entire list rebuilds
                        return SelectedShipmentItemTile(
                          key: ValueKey(_selectedItems[index].itemDefinitionId),
                          item: _selectedItems[index],
                          onEdit: (quantity, expirationDate) => _updateItem(index, quantity, expirationDate),
                          onRemove: () => _removeItem(index),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        // Available items with swipe up gesture for adding new item
        Expanded(
          child: _buildAvailableItemsSection(filteredItems, theme),
        ),
      ],
    );
  }

  Widget _buildAvailableItemsSection(List<ItemDefinition> filteredItems, ThemeData theme) {
    // Create gesture handler for swipe up to create new item
    final gestureHandler = GestureHandler(
      onCreateAction: _navigateToAddItemDefinition,
      // Disable other gestures to avoid conflicts
      onFilterAction: null,
      onSettingsAction: null,
      onNavigationSwipe: null,
    );
    
    return gestureHandler.wrapWithGestures(
      context,
      Card(
        color: theme.colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeaderWidget(
                title: 'Available Items',
                icon: Icons.list,
                iconColor: theme.colorScheme.secondary,
                actionIcon: Icons.add_circle,
                actionTooltip: 'Add New Item',
                onActionPressed: _navigateToAddItemDefinition,
              ),
              const SizedBox(height: 4),
              Expanded(
                child: filteredItems.isEmpty
                    ? _buildEmptyItemsView(theme)
                    : ListView.builder(
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          // Extract each available item into a separate widget
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
      // Enable vertical swipes but disable horizontal swipes
      enableHorizontalSwipe: false,
      enableVerticalSwipe: true,
    );
  }

  Widget _buildEmptyItemsView(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: theme.colorScheme.onSurface.withAlpha(100),
          ),
          const SizedBox(height: 16),
          Text(
            'No matching items found',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withAlpha(150),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Create New Item'),
            onPressed: _navigateToAddItemDefinition,
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog(ItemDefinition item) async {
    // Make sure dependencies are initialized
    if (_dialogService == null) return;
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddItemDialog(
        item: item,
        dialogService: _dialogService!,
      ),
    );
    
    if (result != null) {
      _addItem(item, result['quantity'], result['expirationDate']);
    }
  }
  
  void _addItem(ItemDefinition item, int quantity, DateTime? expirationDate) {
    // Check if item is already selected
    final existingIndex = _selectedItems.indexWhere(
      (selected) => selected.itemDefinitionId == item.id,
    );
    
    if (existingIndex != -1) {
      // Update quantity if already selected
      _updateItem(existingIndex, _selectedItems[existingIndex].quantity + quantity, expirationDate);
    } else {
      // Create a new list instead of modifying the existing one in place
      final newItems = List<ShipmentItem>.from(_selectedItems);
      newItems.add(
        ShipmentItem(
          shipmentId: -1, // Temporary ID, will be set when saving
          itemDefinitionId: item.id!,
          quantity: quantity,
          expirationDate: expirationDate,
          itemDefinition: item,
        ),
      );
      
      setState(() {
        _selectedItems = newItems;
      });
      widget.onItemsChanged(_selectedItems);
    }
  }
  
  void _updateItem(int index, int quantity, DateTime? expirationDate) {
    // Create a new list with the updated item instead of modifying in place
    final updatedItem = ShipmentItem(
      id: _selectedItems[index].id,
      shipmentId: _selectedItems[index].shipmentId,
      itemDefinitionId: _selectedItems[index].itemDefinitionId,
      quantity: quantity,
      expirationDate: expirationDate,
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
    // Create a new list without the removed item
    final newItems = List<ShipmentItem>.from(_selectedItems);
    newItems.removeAt(index);
    
    setState(() {
      _selectedItems = newItems;
    });
    widget.onItemsChanged(_selectedItems);
  }
  
  void _navigateToAddItemDefinition() async {
    // Navigate to add item screen and wait for result
    final result = await NavigationUtils.navigateWithSlide(
      context,
      const AddItemDefinitionScreen(),
    );
    
    // If we have a new item, refresh the available items
    if (result != null) {
      // Force widget to rebuild with new available items
      // The parent widget should handle refreshing the available items list
      
      // Optionally, auto-add the newly created item
      if (result is ItemDefinition && result.id != null) {
        _showAddItemDialog(result);
      }
    }
  }
}