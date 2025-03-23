// lib/features/shipments/screens/select_items_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/common/services/dialog_service.dart';
import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/common/utils/navigation_utils.dart';
import 'package:food_inventory/common/widgets/cached_image_widgets.dart';
import 'package:food_inventory/data/models/item_definition.dart';
import 'package:food_inventory/data/models/shipment_item.dart';
import 'package:food_inventory/data/repositories/item_definition_repository.dart';
import 'package:food_inventory/data/repositories/item_instance_repository.dart';
import 'package:food_inventory/features/inventory/cubit/item_definition_cubit.dart';
import 'package:food_inventory/features/inventory/event_bus/inventory_event_bus.dart';
import 'package:food_inventory/features/inventory/screens/add_item_definition_screen.dart';
import 'package:food_inventory/features/inventory/services/image_service.dart';
import 'package:food_inventory/features/shipments/widgets/add_item_bottom_sheet.dart';
import 'package:provider/provider.dart';

class SelectItemsScreen extends StatefulWidget {
  const SelectItemsScreen({super.key});

  @override
  _SelectItemsScreenState createState() => _SelectItemsScreenState();
}

class _SelectItemsScreenState extends State<SelectItemsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<ItemDefinition> _availableItems = [];
  bool _isLoading = true;
  late ItemDefinitionCubit _itemDefinitionCubit;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Get dependencies from Provider
    final itemDefinitionRepository = Provider.of<ItemDefinitionRepository>(context, listen: false);
    final itemInstanceRepository = Provider.of<ItemInstanceRepository>(context, listen: false);
    final inventoryEventBus = Provider.of<InventoryEventBus>(context, listen: false);
    
    // Initialize cubit
    _itemDefinitionCubit = ItemDefinitionCubit(
      itemDefinitionRepository,
      itemInstanceRepository,
      inventoryEventBus,
    );
    
    // Load items
    _itemDefinitionCubit.loadItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _itemDefinitionCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dialogService = Provider.of<DialogService>(context, listen: false);
    final theme = Theme.of(context);

    return BlocProvider.value(
      value: _itemDefinitionCubit,
      child: BlocListener<ItemDefinitionCubit, ItemDefinitionState>(
        listenWhen: (previous, current) =>
            current is ItemDefinitionLoaded ||
            current is ItemDefinitionLoading ||
            (current.error != null && previous.error != current.error),
        listener: (context, state) {
          if (state.error != null) {
            ErrorHandler.showErrorSnackBar(
              context,
              state.error!.message,
              error: state.error!.error,
            );
          }

          if (state is ItemDefinitionLoading) {
            setState(() {
              _isLoading = true;
            });
          } else if (state is ItemDefinitionLoaded) {
            setState(() {
              _isLoading = false;
              _availableItems = state.items.map((item) => item.itemDefinition).toList();
            });
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Select Item'),
          ),
          body: Column(
            children: [
              // Search bar at the top
              Padding(
                padding: EdgeInsets.all(ConfigService.smallPadding),
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
                    contentPadding: EdgeInsets.all(ConfigService.smallPadding),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ConfigService.borderRadiusLarge),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.withAlpha(ConfigService.alphaLight),
                  ),
                ),
              ),

              // Available items list
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildAvailableItems(context, dialogService),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () => _navigateToAddItemDefinition(context),
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableItems(BuildContext context, DialogService dialogService) {
    final filteredItems = _availableItems
        .where((item) => item.name.toLowerCase().contains(_searchQuery))
        .toList();
    
    if (filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: ConfigService.xLargeIconSize,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(ConfigService.alphaModerate),
            ),
            SizedBox(height: ConfigService.defaultPadding),
            const Text('No matching items found'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(ConfigService.smallPadding),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return _buildItemTile(context, item, dialogService);
      },
    );
  }

  Widget _buildItemTile(BuildContext context, ItemDefinition item, DialogService dialogService) {
    final imageService = Provider.of<ImageService>(context, listen: false);
    
    return Card(
      margin: EdgeInsets.symmetric(vertical: ConfigService.tinyPadding, horizontal: 0),
      child: ListTile(
        leading: ItemImageWidget(
          imagePath: item.imageUrl,
          itemName: item.name,
          radius: 20,
          imageService: imageService,
          memoryEfficient: true,
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: item.barcode != null ? Text('Barcode: ${item.barcode}') : null,
        trailing: IconButton(
          icon: const Icon(Icons.add_circle, color: Colors.green),
          onPressed: () => _showAddItemBottomSheet(context, item, dialogService),
        ),
        onTap: () => _showAddItemBottomSheet(context, item, dialogService),
      ),
    );
  }

  void _navigateToAddItemDefinition(BuildContext context) {
    NavigationUtils.navigateWithSlide(
      context,
      const AddItemDefinitionScreen(),
    ).then((_) {
      _itemDefinitionCubit.loadItems();
    });
  }

  Future<void> _showAddItemBottomSheet(BuildContext context, ItemDefinition item, DialogService dialogService) async {
    // Use the helper method to show the bottom sheet instead of dialog
    final result = await showAddItemBottomSheet(
      context,
      item,
      dialogService,
    );
    
    if (result != null) {
      // Create ShipmentItem and return to previous screen
      final shipmentItem = ShipmentItem(
        shipmentId: -1, // Temporary value
        itemDefinitionId: item.id!,
        quantity: result['quantity'],
        expirationDate: result['expirationDate'],
        unitPrice: result['unitPrice'],
        itemDefinition: item,
      );
      
      Navigator.pop(context, shipmentItem);
    }
  }
}