import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/common/services/dialog_service.dart';
import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/common/widgets/count_display_widget.dart';
import 'package:food_inventory/common/widgets/cached_image_widgets.dart';
import 'package:food_inventory/common/widgets/section_header_widget.dart';
import 'package:food_inventory/common/utils/navigation_utils.dart';
import 'package:food_inventory/data/models/inventory_movement.dart';
import 'package:food_inventory/data/models/item_definition.dart';
import 'package:food_inventory/data/models/item_instance.dart';
import 'package:food_inventory/features/inventory/bloc/inventory_bloc.dart';
import 'package:food_inventory/features/inventory/screens/item_edit_screen.dart';
import 'package:food_inventory/features/inventory/services/image_service.dart';
import 'package:food_inventory/features/inventory/services/inventory_service.dart';
import 'package:food_inventory/features/inventory/widgets/inventory_movement_list.dart';
import 'package:food_inventory/features/inventory/widgets/inventory_to_stock_bottom_sheet.dart';
import 'package:food_inventory/features/inventory/widgets/item_expiration_list.dart';
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
  late ItemDefinition _currentItemDefinition;

  @override
  void initState() {
    super.initState();
    _currentItemDefinition = widget.itemDefinition;
  }

  @override
  Widget build(BuildContext context) {
    final dialogService = Provider.of<DialogService>(context);
    final imageService = Provider.of<ImageService>(context);
    final inventoryService = Provider.of<InventoryService>(context, listen: false);
    final theme = Theme.of(context);
    
    return BlocProvider(
      create: (context) => InventoryBloc(inventoryService)
        ..add(LoadItemDetail(_currentItemDefinition.id!)),
      child: BlocConsumer<InventoryBloc, InventoryState>(
        listenWhen: (previous, current) => 
          current.error != null && previous.error != current.error ||
          current is OperationResult,
        listener: (context, state) {
          if (state.error != null) {
            context.read<InventoryBloc>().handleError(context, state.error!);
          }
          
          if (state is OperationResult) {
            if (state.success) {
              // If successful operation, clear the operation state
              context.read<InventoryBloc>().add(const ClearOperationState());
            }
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'Item Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit, size: ConfigService.defaultIconSize),
                  onPressed: () => _editItem(context),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: ConfigService.defaultIconSize),
                  onPressed: () => _deleteItem(context, dialogService),
                ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: () async {
                context.read<InventoryBloc>().add(LoadItemDetail(_currentItemDefinition.id!));
              },
              child: _buildContent(context, state, theme, imageService, dialogService),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, InventoryState state, ThemeData theme, 
                       ImageService imageService, DialogService dialogService) {
    if (state is InventoryLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (state is ItemDetailLoaded) {
      final itemData = state.itemDetail;
      
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item image at the top
            FullItemImageWidget(
              imagePath: _currentItemDefinition.imageUrl,
              itemName: _currentItemDefinition.name,
              imageService: imageService,
              memoryEfficient: true,
            ),
            
            Padding(
              padding: EdgeInsets.all(ConfigService.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item name 
                  Padding(
                    padding: EdgeInsets.only(bottom: ConfigService.smallPadding),
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
                      padding: EdgeInsets.all(ConfigService.defaultPadding),
                      child: Row(
                        children: [
                          Icon(Icons.qr_code, size: ConfigService.mediumIconSize, color: theme.colorScheme.primary),
                          SizedBox(height: ConfigService.smallPadding),
                          Text(
                            _currentItemDefinition.barcode!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withAlpha(ConfigService.alphaHigh),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Item counts
                  _buildCounts(theme, itemData.counts),
                  
                  SizedBox(height: ConfigService.defaultPadding),

                  // Actions
                  _ItemActions(
                    itemDefinitionId: _currentItemDefinition.id!,
                    stockCount: itemData.counts['stock'] ?? 0,
                    inventoryCount: itemData.counts['inventory'] ?? 0,
                  ),
                  
                  SizedBox(height: ConfigService.largePadding),
                  
                  // Expiration dates
                  _buildExpirationDates(theme, itemData.instances),
                  
                  SizedBox(height: ConfigService.largePadding),
                  
                  // Movement history
                  _buildMovementHistory(theme, itemData.movements),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    // Fallback if no data loaded yet
    return const Center(child: Text('Failed to load item details'));
  }

  Widget _buildCounts(ThemeData theme, Map<String, int> counts) {
    final stockCount = counts['stock'] ?? 0;
    final inventoryCount = counts['inventory'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: ConfigService.smallPadding),
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
        SizedBox(height: ConfigService.mediumPadding),
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
          SizedBox(height: ConfigService.defaultPadding),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.history_toggle_off, 
                  size: ConfigService.largeIconSize, 
                  color: theme.colorScheme.onSurface.withAlpha(ConfigService.alphaMedium)
                ),
                SizedBox(height: ConfigService.smallPadding),
                Text(
                  'No movement history yet',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(ConfigService.alphaDefault),
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
        SizedBox(height: ConfigService.mediumPadding),
        InventoryMovementList(movements: typedMovements),
      ],
    );
  }

  void _editItem(BuildContext context) async {
    try {
      final result = await NavigationUtils.navigateWithSlide<ItemDefinition>(
        context,
        ItemEditScreen(
          itemDefinition: _currentItemDefinition,
        ),
      );

      if (result != null) {
        // Update the current item definition with the edited one
        setState(() {
          _currentItemDefinition = result;
        });
        // Refresh the data
        context.read<InventoryBloc>().add(LoadItemDetail(_currentItemDefinition.id!));
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, 'Failed to edit item', error: e);
    }
  }

  void _deleteItem(BuildContext context, DialogService dialogService) async {
    try {
      // Use bottom sheet confirmation instead of dialog
      final confirm = await dialogService.showConfirmBottomSheet(
        context: context,
        title: 'Delete Item',
        content: 'Are you sure you want to delete this item? This will also remove it from shipments, and delete all stock and inventory counts.',
        icon: Icons.delete_forever,
      );

      if (confirm == true) {
        context.read<InventoryBloc>().add(DeleteItemDefinition(_currentItemDefinition.id!));
        
        // Success is handled in the BLoC listener
        Navigator.pop(context);
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, 'Failed to delete item', error: e);
    }
  }
}

/// Extracted widget for item actions to prevent parent rebuilds
class _ItemActions extends StatelessWidget {
  final int itemDefinitionId;
  final int stockCount;
  final int inventoryCount;
  
  const _ItemActions({
    required this.itemDefinitionId,
    required this.stockCount,
    required this.inventoryCount,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dialogService = Provider.of<DialogService>(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: Icon(Icons.remove_shopping_cart, size: ConfigService.mediumIconSize, color: theme.colorScheme.onSecondary),
                label: const Text('Record Sale'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: theme.colorScheme.onSecondary,
                  padding: EdgeInsets.symmetric(vertical: ConfigService.mediumPadding),
                ),
                onPressed: stockCount > 0 ? () => _updateStock(context, stockCount, dialogService) : null,
              ),
            ),
            SizedBox(width: ConfigService.mediumPadding),
            Expanded(
              child: ElevatedButton.icon(
                icon: Icon(Icons.move_up, size: ConfigService.mediumIconSize, color: theme.colorScheme.onTertiary),
                label: const Text('Move to Stock'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.tertiary,
                  foregroundColor: theme.colorScheme.onTertiary,
                  padding: EdgeInsets.symmetric(vertical: ConfigService.mediumPadding),
                ),
                onPressed: inventoryCount > 0 ? () => _moveToStock(context, inventoryCount) : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  void _updateStock(BuildContext context, int currentStock, DialogService dialogService) async {
    try {
      // Use the bottom sheet version of the quantity dialog
      final result = await dialogService.showQuantityBottomSheet(
        context: context,
        title: 'Record Sale',
        currentQuantity: 1,
        maxQuantity: currentStock,
        icon: Icons.remove_shopping_cart,
      );

      if (result != null) {
        context.read<InventoryBloc>().add(RecordStockSale(
          itemDefinitionId,
          result,
        ));
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, 'Failed to update stock', error: e);
    }
  }

  void _moveToStock(BuildContext context, int currentInventory) async {
    try {
      // Use the bottom sheet instead of dialog
      final result = await showInventoryToStockBottomSheet(
        context,
        currentInventory,
      );

      if (result != null) {
        context.read<InventoryBloc>().add(MoveInventoryToStock(
          itemDefinitionId,
          result,
        ));
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, 'Failed to move items to stock', error: e);
    }
  }
}