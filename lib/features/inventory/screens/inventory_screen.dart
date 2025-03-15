import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/common/utils/gesture_handler.dart';
import 'package:food_inventory/common/utils/navigation_utils.dart';
import 'package:food_inventory/common/widgets/contextual_action_menu.dart';
import 'package:food_inventory/features/inventory/bloc/inventory_bloc.dart';
import 'package:food_inventory/features/inventory/screens/add_item_definition_screen.dart';
import 'package:food_inventory/features/inventory/screens/item_detail_screen.dart';
import 'package:food_inventory/features/inventory/services/inventory_service.dart';
import 'package:food_inventory/features/inventory/widgets/inventory_list_item.dart';
import 'package:food_inventory/features/settings/screens/settings_screen.dart';
import 'package:provider/provider.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchVisible = false;

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
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => InventoryBloc(Provider.of<InventoryService>(context, listen: false))
        ..add(const InitializeInventoryScreen()),
      child: BlocListener<InventoryBloc, InventoryState>(
        listenWhen: (previous, current) => current.error != null && previous.error != current.error,
        listener: (context, state) {
          if (state.error != null) {
            context.read<InventoryBloc>().handleError(context, state.error!);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: _isSearchVisible 
                ? TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Search items...',
                      border: InputBorder.none,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _isSearchVisible = false;
                          });
                        },
                      ),
                    ),
                    autofocus: true,
                  )
                : const Text('Stock & Inventory'),
            actions: [
              if (!_isSearchVisible) 
                IconButton(
                  icon: const Icon(Icons.search, size: 24),
                  onPressed: () => _toggleSearch(true),
                ),
            ],
          ),
          body: _buildGestureDetector(context),
        ),
      ),
    );
  }
  
  Widget _buildGestureDetector(BuildContext context) {
    // Create gesture handler for this screen
    final gestureHandler = GestureHandler(
      onCreateAction: _navigateToAddItem,
      onFilterAction: () => _toggleSearch(true),
      onSettingsAction: () => _openSettings(context),
    );
    
    return gestureHandler.wrapWithGestures(
      context,
      _buildContent(),
      // Disable horizontal swipes since parent handles that
      enableHorizontalSwipe: false, 
    );
  }
  
  Widget _buildContent() {
    return _InventoryListView(
      searchQuery: _searchQuery,
      onLongPress: _handleItemLongPress,
    );
  }
  
  void _toggleSearch(bool visible) {
    setState(() {
      _isSearchVisible = visible;
      if (visible) {
        _searchFocusNode.requestFocus();
      } else {
        _searchController.clear();
      }
    });
  }

  void _openSettings(BuildContext context) {
    NavigationUtils.navigateWithSlide(
      context,
      const SettingsScreen(),
    );
  }
  
  void _navigateToAddItem() {
    NavigationUtils.navigateWithSlide(
      context,
      const AddItemDefinitionScreen(),
    );
  }
  
  void _handleItemLongPress(BuildContext context, InventoryItemWithCounts item, Offset position) async {
    final action = await ContextualActionMenu.showItemActions(
      context,
      position,
      canMove: item.inventoryCount > 0,
      hasStock: item.stockCount > 0,
    );
    
    if (action == null) return;
    
    switch (action) {
      case 'view':
        NavigationUtils.navigateWithSlide(
          context,
          ItemDetailScreen(itemDefinition: item.itemDefinition),
        ).then((_) {
          // Refresh data when returning from details
          context.read<InventoryBloc>().add(const LoadInventoryItems());
        });
        break;
      case 'edit':
        // Edit action would be handled here
        break;
      case 'sale':
        // Sale action would be handled here
        break;
      case 'move':
        // Move action would be handled here
        break;
      case 'delete':
        // Delete action would be handled here
        break;
    }
  }
}

class _InventoryListView extends StatelessWidget {
  final String searchQuery;
  final Function(BuildContext context, InventoryItemWithCounts item, Offset position)? onLongPress;
  
  const _InventoryListView({
    required this.searchQuery,
    this.onLongPress,
  });

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
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
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
                  const Icon(Icons.search_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
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
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                
                return GestureDetector(
                  onLongPress: onLongPress != null ? () {
                    // Get the global position for the context menu
                    final RenderBox box = context.findRenderObject() as RenderBox;
                    final position = box.localToGlobal(
                      box.size.center(Offset.zero),
                    );
                    onLongPress!(context, item, position);
                  } : null,
                  child: InventoryListItem(
                    itemDefinition: item.itemDefinition,
                    stockCount: item.stockCount,
                    inventoryCount: item.inventoryCount,
                    isEmptyItem: item.isEmptyItem,
                    onTap: () {
                      NavigationUtils.navigateWithSlide(
                        context,
                        ItemDetailScreen(itemDefinition: item.itemDefinition),
                      ).then((_) {
                        // Refresh data when returning from details
                        context.read<InventoryBloc>().add(const LoadInventoryItems());
                      });
                    },
                  ),
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