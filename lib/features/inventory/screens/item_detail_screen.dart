import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/common/services/dialog_service.dart';
import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/common/widgets/section_header_widget.dart';
import 'package:food_inventory/common/utils/navigation_utils.dart';
import 'package:food_inventory/data/models/inventory_movement.dart';
import 'package:food_inventory/data/models/item_definition.dart';
import 'package:food_inventory/data/models/item_instance.dart';
import 'package:food_inventory/features/inventory/cubit/item_definition_cubit.dart';
import 'package:food_inventory/features/inventory/cubit/item_detail_cubit.dart';
import 'package:food_inventory/features/inventory/cubit/stock_management_cubit.dart';
import 'package:food_inventory/features/inventory/event_bus/inventory_event_bus.dart';
import 'package:food_inventory/features/inventory/screens/item_edit_screen.dart';
import 'package:food_inventory/features/inventory/services/image_service.dart';
import 'package:food_inventory/features/inventory/services/inventory_service.dart';
import 'package:food_inventory/features/inventory/widgets/inventory_movement_list.dart';
import 'package:food_inventory/features/inventory/widgets/inventory_to_stock_bottom_sheet.dart';
import 'package:food_inventory/features/inventory/widgets/item_expiration_list.dart';
import 'package:food_inventory/common/widgets/item_image_widget.dart';
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
  late ItemDetailCubit _itemDetailCubit;
  late StockManagementCubit _stockManagementCubit;

  @override
  void initState() {
    super.initState();
    _currentItemDefinition = widget.itemDefinition;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Get dependencies from Provider instead of ServiceLocator
    final inventoryService = Provider.of<InventoryService>(context, listen: false);
    final inventoryEventBus = Provider.of<InventoryEventBus>(context, listen: false);
    
    // Initialize cubits with injected dependencies
    _itemDetailCubit = ItemDetailCubit(inventoryService, inventoryEventBus);
    _stockManagementCubit = StockManagementCubit(inventoryService);
    
    // Load initial data
    _itemDetailCubit.loadItemDetail(_currentItemDefinition.id!);
  }
  
  @override
  void dispose() {
    _itemDetailCubit.close();
    _stockManagementCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dialogService = Provider.of<DialogService>(context);
    final imageService = Provider.of<ImageService>(context);
    final inventoryService = Provider.of<InventoryService>(context, listen: false);
    final theme = Theme.of(context);
    
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _itemDetailCubit),
        BlocProvider(
          create: (context) => StockManagementCubit(inventoryService),
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<ItemDetailCubit, ItemDetailState>(
            listenWhen: (previous, current) => current.error != null && previous.error != current.error,
            listener: (context, state) {
              if (state.error != null) {
                ErrorHandler.showErrorSnackBar(
                  context, 
                  state.error!.message, 
                  error: state.error!.error
                );
              }
            },
          ),
          BlocListener<StockManagementCubit, StockManagementState>(
            listener: (context, state) {
              if (state is StockOperationFailure) {
                ErrorHandler.showErrorSnackBar(
                  context, 
                  state.error!.message, 
                  error: state.error!.error
                );
              } else if (state is StockOperationSuccess) {
                ErrorHandler.showSuccessSnackBar(
                  context, 
                  'Operation successful'
                );
                // Refresh item details
                _itemDetailCubit.loadItemDetail(_currentItemDefinition.id!);
              }
            },
          ),
        ],
        child: Scaffold(
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
              _itemDetailCubit.loadItemDetail(_currentItemDefinition.id!);
            },
            child: _buildContent(context, theme, imageService, dialogService),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme, ImageService imageService, DialogService dialogService) {
    return BlocBuilder<ItemDetailCubit, ItemDetailState>(
      builder: (context, state) {
        if (state is ItemDetailLoading) {
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
                ItemImageWidget.full(
                  imagePath: _currentItemDefinition.imageUrl,
                  itemName: _currentItemDefinition.name,
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
                          padding: EdgeInsets.symmetric(vertical: ConfigService.smallPadding),
                          child: Row(
                            children: [
                              Icon(Icons.qr_code, size: ConfigService.mediumIconSize, color: theme.colorScheme.primary),
                              SizedBox(width: ConfigService.smallPadding),
                              Text(
                                _currentItemDefinition.barcode!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withAlpha(ConfigService.alphaHigh),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      SizedBox(height: ConfigService.defaultPadding),
                      
                      // Stock and Inventory counts + actions
                      _ItemCountsAndActions(
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
      },
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
        _itemDetailCubit.loadItemDetail(_currentItemDefinition.id!);
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
        // Delete using the cubit
        context.read<ItemDefinitionCubit>().deleteItemDefinition(_currentItemDefinition.id!);
        Navigator.pop(context);
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, 'Failed to delete item', error: e);
    }
  }
}

/// Extracted widget for item counts and actions
class _ItemCountsAndActions extends StatelessWidget {
  final int itemDefinitionId;
  final int stockCount;
  final int inventoryCount;
  
  const _ItemCountsAndActions({
    required this.itemDefinitionId,
    required this.stockCount,
    required this.inventoryCount,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dialogService = Provider.of<DialogService>(context);
    final inventoryService = Provider.of<InventoryService>(context, listen: false);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stock and Inventory counts in vertical layout
        Padding(
          padding: EdgeInsets.symmetric(horizontal: ConfigService.defaultPadding),
          child: Column(
            children: [
              // Stock row
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.shopping_cart,
                      color: theme.colorScheme.primary,
                      size: ConfigService.defaultIconSize,
                    ),
                  ),
                  SizedBox(width: ConfigService.defaultPadding),
                  Text(
                    'Stock',
                    style: theme.textTheme.titleMedium,
                  ),
                  const Spacer(),
                  Text(
                    '$stockCount',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: ConfigService.defaultPadding),
              
              // Inventory row
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.inventory_2,
                      color: theme.colorScheme.secondary,
                      size: ConfigService.defaultIconSize,
                    ),
                  ),
                  SizedBox(width: ConfigService.defaultPadding),
                  Text(
                    'Inventory',
                    style: theme.textTheme.titleMedium,
                  ),
                  const Spacer(),
                  Text(
                    '$inventoryCount',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        SizedBox(height: ConfigService.largePadding),
        
        // Action buttons - full width and horizontal
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: Icon(Icons.remove_shopping_cart, 
                  size: ConfigService.smallIconSize,
                  color: theme.colorScheme.onSecondary,
                ),
                label: const Text('Record Sale'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: theme.colorScheme.onSecondary,
                  padding: EdgeInsets.symmetric(vertical: ConfigService.mediumPadding),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ConfigService.borderRadiusSmall),
                  ),
                ),
                onPressed: stockCount > 0 
                    ? () => _updateStock(context, stockCount, dialogService, inventoryService) 
                    : null,
              ),
            ),
            SizedBox(width: ConfigService.mediumPadding),
            Expanded(
              child: ElevatedButton.icon(
                icon: Icon(Icons.move_up, 
                  size: ConfigService.smallIconSize,
                  color: theme.colorScheme.onTertiary,
                ),
                label: const Text('Move to Stock'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.tertiary,
                  foregroundColor: theme.colorScheme.onTertiary,
                  padding: EdgeInsets.symmetric(vertical: ConfigService.mediumPadding),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ConfigService.borderRadiusSmall),
                  ),
                ),
                onPressed: inventoryCount > 0 
                    ? () => _moveToStock(context, inventoryCount, inventoryService)
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  void _updateStock(BuildContext context, int currentStock, DialogService dialogService, InventoryService inventoryService) async {
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
        // Call the stock management cubit to handle the sale operation
        context.read<StockManagementCubit>().recordStockSale(
          itemDefinitionId,
          result,
        );
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, 'Failed to update stock', error: e);
    }
  }

  void _moveToStock(BuildContext context, int currentInventory, InventoryService inventoryService) async {
    try {
      // Use the bottom sheet instead of dialog
      final result = await showInventoryToStockBottomSheet(
        context,
        currentInventory,
      );

      if (result != null) {
        // Call the stock management cubit to handle the move operation
        context.read<StockManagementCubit>().moveInventoryToStock(
          itemDefinitionId,
          result,
        );
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, 'Failed to move items to stock', error: e);
    }
  }
}