// lib/features/inventory/screens/inventory_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/common/utils/navigation_utils.dart';
import 'package:food_inventory/features/inventory/bloc/inventory_bloc.dart';
import 'package:food_inventory/features/inventory/screens/add_item_definition_screen.dart';
import 'package:food_inventory/features/inventory/screens/item_detail_screen.dart';
import 'package:food_inventory/features/inventory/services/inventory_service.dart';
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
  late InventoryBloc _inventoryBloc;

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
    // Initialize the bloc in didChangeDependencies to ensure context is ready
    final inventoryService = Provider.of<InventoryService>(context, listen: false);
    _inventoryBloc = InventoryBloc(inventoryService);
    _inventoryBloc.add(const InitializeInventoryScreen());
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _inventoryBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _inventoryBloc,
      child: BlocListener<InventoryBloc, InventoryState>(
        listenWhen: (previous, current) => current.error != null && previous.error != current.error,
        listener: (context, state) {
          if (state.error != null) {
            _inventoryBloc.handleError(context, state.error!);
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
      // Use _inventoryBloc directly instead of context.read
      _inventoryBloc.add(const LoadInventoryItems());
    });
  }
}

class _InventoryListView extends StatelessWidget {
  final String searchQuery;
  
  const _InventoryListView({required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InventoryBloc, InventoryState>(
      buildWhen: (previous, current) => 
        (current is InventoryLoading && previous is! InventoryLoading) || 
        (current is InventoryItemsLoaded && (previous is! InventoryItemsLoaded || 
            previous.items != (current).items)),
      builder: (context, state) {
        if (state is InventoryLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is InventoryItemsLoaded) {
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
              context.read<InventoryBloc>().add(const LoadInventoryItems());
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
                  earliestExpirationDate: item.earliestExpirationDate, // Pass expiration date
                  onTap: () {
                    NavigationUtils.navigateWithSlide(
                      context,
                      ItemDetailScreen(itemDefinition: item.itemDefinition),
                    ).then((_) {
                      // Refresh data when returning from details
                      context.read<InventoryBloc>().add(const LoadInventoryItems());
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