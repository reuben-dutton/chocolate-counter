import 'package:flutter/material.dart';
import 'package:food_inventory/data/models/inventory_movement.dart';
import 'package:food_inventory/data/models/item_definition.dart';
import 'package:food_inventory/data/models/item_instance.dart';
import 'package:food_inventory/features/inventory/screens/item_edit_screen.dart';
import 'package:food_inventory/features/inventory/services/inventory_service.dart';
import 'package:food_inventory/features/inventory/services/image_service.dart';
import 'package:food_inventory/common/services/dialog_service.dart';
import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/common/widgets/count_display_widget.dart';
import 'package:food_inventory/common/widgets/full_item_image_widget.dart';
import 'package:food_inventory/common/widgets/section_header_widget.dart';
import 'package:food_inventory/features/inventory/widgets/inventory_movement_list.dart';
import 'package:food_inventory/features/inventory/widgets/item_expiration_list.dart';
import 'package:food_inventory/features/inventory/widgets/inventory_to_stock_dialog.dart';
import 'package:provider/provider.dart';

class ItemDetailScreen extends StatefulWidget {
  final ItemDefinition itemDefinition;

  const ItemDetailScreen({
    super.key,
    required this.itemDefinition,
  });

  @override
  _ItemDetailScreenState createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late InventoryService _inventoryService;
  late DialogService _dialogService;
  late ImageService _imageService;
  late Future<Map<String, int>> _countsFuture;
  late Future<List<ItemInstance>> _itemInstancesFuture;
  late Future<List<InventoryMovement>> _movementsFuture;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _inventoryService = Provider.of<InventoryService>(context, listen: false);
      _dialogService = Provider.of<DialogService>(context, listen: false);
      _imageService = Provider.of<ImageService>(context, listen: false);
      _refreshData();
      _initialized = true;
    }
  }

  void _refreshData() {
    setState(() {
      _countsFuture = _inventoryService.getItemCounts(widget.itemDefinition.id!);
      _itemInstancesFuture = _inventoryService.getItemInstances(widget.itemDefinition.id!);
      _movementsFuture = _inventoryService.getItemMovements(widget.itemDefinition.id!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Item Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, size: 22),
            onPressed: () => _editItem(),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 22),
            onPressed: () => _deleteItem(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item image at the top
              FullItemImageWidget(
                imagePath: widget.itemDefinition.imageUrl,
                itemName: widget.itemDefinition.name,
                imageService: _imageService,
              ),
              
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item name 
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        widget.itemDefinition.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    // Barcode (if available)
                    if (widget.itemDefinition.barcode != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          children: [
                            Icon(Icons.qr_code, size: 18, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              widget.itemDefinition.barcode!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withAlpha(175),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Item counts
                    _buildCounts(theme),
                    
                    const SizedBox(height: 16),

                    // Actions
                    _buildActions(theme),
                    
                    const SizedBox(height: 24),
                    
                    // Expiration dates
                    _buildExpirationDates(theme),
                    
                    const SizedBox(height: 24),
                    
                    // Movement history
                    _buildMovementHistory(theme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCounts(ThemeData theme) {
    return FutureBuilder<Map<String, int>>(
      future: _countsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final stockCount = snapshot.data?['stock'] ?? 0;
        final inventoryCount = snapshot.data?['inventory'] ?? 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Stock count
                CountDisplayWidget(
                  icon: Icons.shopping_cart,
                  label: 'Stock',
                  count: stockCount,
                  color: theme.colorScheme.primary,
                ),
                
                // Inventory count
                CountDisplayWidget(
                  icon: Icons.inventory_2,
                  label: 'Inventory',
                  count: inventoryCount,
                  color: theme.colorScheme.secondary,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildActions(ThemeData theme) {
    return FutureBuilder<Map<String, int>>(
      future: _countsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox();
        }

        final stockCount = snapshot.data?['stock'] ?? 0;
        final inventoryCount = snapshot.data?['inventory'] ?? 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.remove_shopping_cart, size: 18, color: theme.colorScheme.onSecondary),
                    label: const Text('Record Sale'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: theme.colorScheme.onSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: stockCount > 0 ? () => _updateStock(stockCount) : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.move_up, size: 18, color: theme.colorScheme.onTertiary),
                    label: const Text('Move to Stock'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.tertiary,
                      foregroundColor: theme.colorScheme.onTertiary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: inventoryCount > 0 ? () => _moveToStock(inventoryCount) : null,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildExpirationDates(ThemeData theme) {
    return FutureBuilder<List<ItemInstance>>(
      future: _itemInstancesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final instances = snapshot.data ?? [];
        
        if (instances.isEmpty) {
          return const SizedBox();  // Hide if no instances
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeaderWidget(
              title: 'Expiration Dates',
              icon: Icons.event_available,
              iconColor: theme.colorScheme.secondary,
            ),
            const SizedBox(height: 12),
            ItemExpirationList(instances: instances),
          ],
        );
      },
    );
  }

  Widget _buildMovementHistory(ThemeData theme) {
    return FutureBuilder<List<InventoryMovement>>(
      future: _movementsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final movements = snapshot.data ?? [];
        
        if (movements.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeaderWidget(
                title: 'Movement History',
                icon: Icons.history,
                iconColor: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.history_toggle_off, 
                      size: 48, 
                      color: theme.colorScheme.onSurface.withAlpha(75)
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No movement history yet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(128),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeaderWidget(
              title: 'Movement History',
              icon: Icons.history,
              iconColor: theme.colorScheme.secondary,
            ),
            const SizedBox(height: 12),
            InventoryMovementList(movements: movements),
          ],
        );
      },
    );
  }

  void _editItem() async {
    try {
      final result = await Navigator.push<ItemDefinition>(
        context,
        MaterialPageRoute(
          builder: (context) => ItemEditScreen(
            itemDefinition: widget.itemDefinition,
          ),
        ),
      );

      if (result != null) {
        // The item was updated in the edit screen, just refresh the UI
        _refreshData();
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, 'Failed to edit item', error: e);
    }
  }

  void _deleteItem() async {
    try {
      final confirm = await _dialogService.showConfirmDialog(
        context: context,
        title: 'Delete Item',
        content: 'Are you sure you want to delete this item? This will also remove it from shipments, and delete all stock and inventory counts.',
        icon: Icons.delete_forever,
      );

      if (confirm == true) {
        await _inventoryService.deleteItemDefinition(widget.itemDefinition.id!);
        ErrorHandler.showSuccessSnackBar(context, 'Item deleted');
        Navigator.pop(context);
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, 'Failed to delete item', error: e);
    }
  }

  void _updateStock(int currentStock) async {
    try {
      final result = await _dialogService.showQuantityDialog(
        context: context,
        title: 'Record Sale',
        currentQuantity: 1,
        maxQuantity: currentStock,
        icon: Icons.remove_shopping_cart,
      );

      if (result != null) {
        await _inventoryService.updateStockCount(
          widget.itemDefinition.id!,
          result,
        );
        _refreshData();
        ErrorHandler.showSuccessSnackBar(context, 'Stock updated');
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, 'Failed to update stock', error: e);
    }
  }

  void _moveToStock(int currentInventory) async {
    try {
      final result = await showDialog<int>(
        context: context,
        builder: (context) => InventoryToStockDialog(
          currentInventory: currentInventory,
        ),
      );

      if (result != null) {
        await _inventoryService.moveInventoryToStock(
          widget.itemDefinition.id!,
          result,
        );
        _refreshData();
        ErrorHandler.showSuccessSnackBar(context, 'Items moved to stock');
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, 'Failed to move items to stock', error: e);
    }
  }
}