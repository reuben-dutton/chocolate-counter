import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/common/utils/navigation_utils.dart';
import 'package:food_inventory/data/repositories/item_definition_repository.dart';
import 'package:food_inventory/features/inventory/cubit/item_definition_cubit.dart';
import 'package:food_inventory/features/inventory/event_bus/inventory_event_bus.dart';
import 'package:food_inventory/features/inventory/screens/add_item_definition_screen.dart';
import 'package:food_inventory/features/inventory/screens/item_detail_screen.dart';
import 'package:food_inventory/features/inventory/widgets/inventory_list_item.dart';
import 'package:provider/provider.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
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
    
    // Get dependencies from provider
    final itemDefinitionRepository = Provider.of<ItemDefinitionRepository>(context, listen: false);
    final inventoryEventBus = Provider.of<InventoryEventBus>(context, listen: false);
    
    // Initialize the cubit with dependencies from provider
    _itemDefinitionCubit = ItemDefinitionCubit(
      itemDefinitionRepository,
      inventoryEventBus,
    );
    
    // Load initial data
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
    return BlocProvider.value(
      value: _itemDefinitionCubit,
      child: BlocListener<ItemDefinitionCubit, ItemDefinitionState>(
        listenWhen: (previous, current) => current.error != null && previous.error != current.error,
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!.message)),
            );
          }
        },
        child: Scaffold(
          body: Column(
            children: [
              // Items list
              Expanded(
                child: _InventoryListView(searchQuery: _searchQuery),
              ),
              
              // Search bar at the bottom
              Container(
                padding: EdgeInsets.symmetric(horizontal: ConfigService.smallPadding, vertical: ConfigService.smallPadding),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
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
                          contentPadding: EdgeInsets.symmetric(horizontal: ConfigService.smallPadding, vertical: ConfigService.smallPadding),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(ConfigService.borderRadiusLarge),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.withAlpha(ConfigService.alphaLight),
                        ),
                      ),
                    ),
                    SizedBox(width: ConfigService.smallPadding),
                    IconButton(
                      icon: const Icon(Icons.add_box),
                      tooltip: 'Add Item',
                      onPressed: () => _navigateToAddItemDefinition(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _navigateToAddItemDefinition(BuildContext context) {
    NavigationUtils.navigateWithSlide(
      context,
      const AddItemDefinitionScreen(),
    ).then((_) {
      // Refresh data when returning from add screen
      _itemDefinitionCubit.loadItems();
    });
  }
}

class _InventoryListView extends StatelessWidget {
  final String searchQuery;
  
  const _InventoryListView({required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ItemDefinitionCubit, ItemDefinitionState>(
      buildWhen: (previous, current) => 
        (current is ItemDefinitionLoading && previous is! ItemDefinitionLoading) || 
        (current is ItemDefinitionLoaded && (previous is! ItemDefinitionLoaded || 
            previous.items != (current).items)),
      builder: (context, state) {
        if (state is ItemDefinitionLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ItemDefinitionLoaded) {
          final allItems = state.items;
          
          if (allItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: ConfigService.xLargeIconSize, color: Colors.grey),
                  SizedBox(height: ConfigService.defaultPadding),
                  Text('No items found. Add some by creating a shipment.'),
                ],
              ),
            );
          }
          
          // Filter items by search query (in memory)
          final items = searchQuery.isEmpty
              ? allItems
              : allItems.where((item) => 
                  item.itemDefinition.name.toLowerCase().contains(searchQuery) ||
                  (item.itemDefinition.barcode?.toLowerCase().contains(searchQuery) ?? false)
                ).toList();
          
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: ConfigService.largeIconSize, color: Colors.grey),
                  SizedBox(height: ConfigService.defaultPadding),
                  Text('No results found for "$searchQuery"'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<ItemDefinitionCubit>().loadItems();
            },
            child: ListView.builder(
              // needs to be 0 padding at the top as we have padding from the menu indicator
              padding: EdgeInsets.only(top: 0, bottom: ConfigService.smallPadding, left: ConfigService.tinyPadding, right: ConfigService.tinyPadding),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                
                return InventoryListItem(
                  itemDefinition: item.itemDefinition,
                  stockCount: item.stockCount,
                  inventoryCount: item.inventoryCount,
                  isEmptyItem: item.isEmptyItem,
                  earliestExpirationDate: item.earliestExpirationDate,
                  onTap: () {
                    NavigationUtils.navigateWithSlide(
                      context,
                      ItemDetailScreen(itemDefinition: item.itemDefinition),
                    ).then((_) {
                      // Refresh data when returning from details
                      context.read<ItemDefinitionCubit>().loadItems();
                    });
                  },
                );
              },
            ),
          );
        }
        
        // Fallback for initial state
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}