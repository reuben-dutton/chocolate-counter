import 'package:flutter/material.dart';
import 'package:food_inventory/models/item_definition.dart';
import 'package:food_inventory/models/shipment_item.dart';
import 'package:food_inventory/services/dialog_service.dart';
import 'package:food_inventory/widgets/common/item_image_widget.dart';
import 'package:food_inventory/widgets/common/section_header_widget.dart';
import 'package:food_inventory/widgets/common/expiration_date_widget.dart';
import 'package:intl/intl.dart';
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
  List<ShipmentItem> _selectedItems = [];
  late DialogService _dialogService;
  
  @override
  void initState() {
    super.initState();
    _selectedItems = List.from(widget.selectedItems);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    _dialogService = Provider.of<DialogService>(context, listen: false);
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
            fillColor: Colors.grey.withAlpha(128),
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
                        final item = _selectedItems[index];
                        return Card(
                          color: theme.colorScheme.surface,
                          margin: const EdgeInsets.symmetric(vertical: 1),
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            leading: ItemImageWidget(
                              imagePath: item.itemDefinition?.imageUrl,
                              itemName: item.itemDefinition?.name ?? 'Unknown Item',
                              radius: 16,
                            ),
                            title: Text(
                              item.itemDefinition?.name ?? 'Unknown Item',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                            subtitle: item.expirationDate != null
                                ? ExpirationDateWidget(
                                    expirationDate: item.expirationDate,
                                    fontSize: 12,
                                    iconSize: 12,
                                  )
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${item.quantity}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 16),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _showItemEditDialog(index),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 16),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _removeItem(index),
                                ),
                              ],
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
          const SizedBox(height: 12),
        ],
        
        // Available items
        Expanded(
          child: Card(
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
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: filteredItems.isEmpty
                        ? const Center(child: Text('No matching items found'))
                        : ListView.builder(
                            itemCount: filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = filteredItems[index];
                              return ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                leading: ItemImageWidget(
                                  imagePath: item.imageUrl,
                                  itemName: item.name,
                                  radius: 16,
                                ),
                                title: Text(
                                  item.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.add_circle, size: 20),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _showAddItemDialog(item),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddItemDialog(ItemDefinition item) async {
    int quantity = 1;
    DateTime? expirationDate;
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Row(
              children: [
                const Icon(Icons.add_circle, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Add ${item.name}',
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quantity selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Quantity: '),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: quantity > 1
                          ? () => setState(() => quantity--)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$quantity',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => setState(() => quantity++),
                    ),
                  ],
                ),
                
                // Expiration date selector
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Expiration Date (Optional)'),
                  subtitle: ExpirationDateWidget(
                    expirationDate: expirationDate,
                    showIcon: false,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today, size: 20),
                    onPressed: () async {
                      final DateTime? picked = await _dialogService.showDatePicker(
                        context: context,
                        initialDate: expirationDate ?? DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2101),
                        helpText: 'Select Expiration Date',
                      );
                      if (picked != null) {
                        setState(() {
                          expirationDate = picked;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add'),
                onPressed: () {
                  Navigator.of(context).pop({
                    'quantity': quantity,
                    'expirationDate': expirationDate,
                  });
                },
              ),
            ],
          );
        },
      ),
    );
    
    if (result != null) {
      _addItem(item, result['quantity'], result['expirationDate']);
    }
  }
  
  void _showItemEditDialog(int index) async {
    final item = _selectedItems[index];
    int quantity = item.quantity;
    DateTime? expirationDate = item.expirationDate;
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.edit, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Edit ${item.itemDefinition?.name ?? 'Item'}',
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quantity selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Quantity: '),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: quantity > 1
                          ? () => setState(() => quantity--)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$quantity',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => setState(() => quantity++),
                    ),
                  ],
                ),
                
                // Expiration date selector
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Expiration Date (Optional)'),
                  subtitle: ExpirationDateWidget(
                    expirationDate: expirationDate,
                    showIcon: false,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today, size: 20),
                    onPressed: () async {
                      final DateTime? picked = await _dialogService.showDatePicker(
                        context: context,
                        initialDate: expirationDate ?? DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2101),
                        helpText: 'Select Expiration Date',
                      );
                      if (picked != null) {
                        setState(() {
                          expirationDate = picked;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Update'),
                onPressed: () {
                  Navigator.of(context).pop({
                    'quantity': quantity,
                    'expirationDate': expirationDate,
                  });
                },
              ),
            ],
          );
        },
      ),
    );
    
    if (result != null) {
      _updateItem(index, result['quantity'], result['expirationDate']);
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
      // Add new item
      setState(() {
        _selectedItems.add(
          ShipmentItem(
            shipmentId: -1, // Temporary ID, will be set when saving
            itemDefinitionId: item.id!,
            quantity: quantity,
            expirationDate: expirationDate,
            itemDefinition: item,
          ),
        );
        widget.onItemsChanged(_selectedItems);
      });
    }
  }
  
  void _updateItem(int index, int quantity, DateTime? expirationDate) {
    setState(() {
      final updatedItem = ShipmentItem(
        id: _selectedItems[index].id,
        shipmentId: _selectedItems[index].shipmentId,
        itemDefinitionId: _selectedItems[index].itemDefinitionId,
        quantity: quantity,
        expirationDate: expirationDate,
        itemDefinition: _selectedItems[index].itemDefinition,
      );
      _selectedItems[index] = updatedItem;
      widget.onItemsChanged(_selectedItems);
    });
  }
  
  void _removeItem(int index) {
    setState(() {
      _selectedItems.removeAt(index);
      widget.onItemsChanged(_selectedItems);
    });
  }
}