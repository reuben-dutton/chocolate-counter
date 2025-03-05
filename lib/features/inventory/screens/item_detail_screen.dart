import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/dialog_service.dart';
import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/common/services/service_locator.dart';
import 'package:food_inventory/common/widgets/count_display_widget.dart';
import 'package:food_inventory/common/widgets/full_item_image_widget.dart';
import 'package:food_inventory/common/widgets/section_header_widget.dart';
import 'package:food_inventory/data/models/inventory_movement.dart';
import 'package:food_inventory/data/models/item_definition.dart';
import 'package:food_inventory/data/models/item_instance.dart';
import 'package:food_inventory/features/inventory/bloc/inventory_bloc.dart';
import 'package:food_inventory/features/inventory/screens/item_edit_screen.dart';
import 'package:food_inventory/features/inventory/services/image_service.dart';
import 'package:food_inventory/features/inventory/widgets/inventory_movement_list.dart';
import 'package:food_inventory/features/inventory/widgets/inventory_to_stock_dialog.dart';
import 'package:food_inventory/features/inventory/widgets/item_expiration_list.dart';


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
  late InventoryBloc _inventoryBloc;
  late DialogService _dialogService;
  late ImageService _imageService;
  // Initialize directly from the widget property to avoid LateInitializationError
  late ItemDefinition _currentItemDefinition = widget.itemDefinition;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _inventoryBloc = ServiceLocator.instance<InventoryBloc>();
      _dialogService = ServiceLocator.instance<DialogService>();
      _imageService = ServiceLocator.instance<ImageService>();
      // _currentItemDefinition is already initialized in declaration
      _refreshData();
      _initialized = true;
    }
  }

  void _refreshData() {
    _inventoryBloc.loadItemDetail(_currentItemDefinition.id!);
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
        child: StreamBuilder<ItemDetailData>(
          stream: _inventoryBloc.itemDetailData,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final itemData = snapshot.data!;
            
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item image at the top
                  FullItemImageWidget(
                    imagePath: _currentItemDefinition.imageUrl,
                    itemName: _currentItemDefinition.name,
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
                            _currentItemDefinition.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        
                        // Barcode (if available)
                        if (_currentItemDefinition.barcode != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Row(
                              children: [
                                Icon(Icons.qr_code, size: 18, color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  _currentItemDefinition.barcode!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface.withAlpha(175),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        // Item counts
                        _buildCounts(theme, itemData.counts),
                        
                        const SizedBox(height: 16),

                        // Actions
                        _buildActions(theme, itemData.counts),
                        
                        const SizedBox(height: 24),
                        
                        // Expiration dates
                        _buildExpirationDates(theme, itemData.instances),
                        
                        const SizedBox(height: 24),
                        
                        // Movement history
                        _buildMovementHistory(theme, itemData.movements),
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

  Widget _buildCounts(ThemeData theme, Map<String, int> counts) {
    final stockCount = counts['stock'] ?? 0;
    final inventoryCount = counts['inventory'] ?? 0;

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
  }

  Widget _buildActions(ThemeData theme, Map<String, int> counts) {
    final stockCount = counts['stock'] ?? 0;
    final inventoryCount = counts['inventory'] ?? 0;

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
  }
  
  Widget _buildExpirationDates(ThemeData theme, List<dynamic> instances) {
    if (instances.isEmpty) {
      return const SizedBox();  // Hide if no instances
    }

    // Cast the dynamic list to the proper type
    final typedInstances = instances.cast<ItemInstance>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeaderWidget(
          title: 'Expiration Dates',
          icon: Icons.event_available,
          iconColor: theme.colorScheme.secondary,
        ),
        const SizedBox(height: 12),
        ItemExpirationList(instances: typedInstances),
      ],
    );
  }

  Widget _buildMovementHistory(ThemeData theme, List<dynamic> movements) {
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

    // Cast the dynamic list to the proper type
    final typedMovements = movements.cast<InventoryMovement>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeaderWidget(
          title: 'Movement History',
          icon: Icons.history,
          iconColor: theme.colorScheme.secondary,
        ),
        const SizedBox(height: 12),
        InventoryMovementList(movements: typedMovements),
      ],
    );
  }

  void _editItem() async {
    try {
      final result = await Navigator.push<ItemDefinition>(
        context,
        MaterialPageRoute(
          builder: (context) => ItemEditScreen(
            itemDefinition: _currentItemDefinition,
          ),
        ),
      );

      if (result != null) {
        // Update the current item definition with the edited one
        setState(() {
          _currentItemDefinition = result;
        });
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
        final success = await _inventoryBloc.deleteItemDefinition(_currentItemDefinition.id!);
        if (success) {
          ErrorHandler.showSuccessSnackBar(context, 'Item deleted');
          Navigator.pop(context);
        } else {
          ErrorHandler.showErrorSnackBar(context, 'Failed to delete item');
        }
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
        final success = await _inventoryBloc.recordStockSale(
          _currentItemDefinition.id!,
          result,
        );
        if (success) {
          ErrorHandler.showSuccessSnackBar(context, 'Stock updated');
        } else {
          ErrorHandler.showErrorSnackBar(context, 'Failed to update stock');
        }
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
        final success = await _inventoryBloc.moveInventoryToStock(
          _currentItemDefinition.id!,
          result,
        );
        if (success) {
          ErrorHandler.showSuccessSnackBar(context, 'Items moved to stock');
        } else {
          ErrorHandler.showErrorSnackBar(context, 'Failed to move items to stock');
        }
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, 'Failed to move items to stock', error: e);
    }
  }
}