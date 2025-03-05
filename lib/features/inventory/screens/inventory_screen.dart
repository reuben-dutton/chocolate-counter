import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/service_locator.dart';
import 'package:food_inventory/features/inventory/bloc/inventory_bloc.dart';
import 'package:food_inventory/features/inventory/screens/item_detail_screen.dart';
import 'package:food_inventory/features/inventory/widgets/inventory_list_item.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late InventoryBloc _inventoryBloc;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _inventoryBloc = ServiceLocator.instance<InventoryBloc>();
    _loadItems();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadItems() {
    _inventoryBloc.loadInventoryItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock & Inventory'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 2),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search items...',
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
          ),
          
          // Items list
          Expanded(
            child: StreamBuilder<List<InventoryItemWithCounts>>(
              stream: _inventoryBloc.inventoryItems,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allItems = snapshot.data ?? [];
                
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
                final items = _searchQuery.isEmpty
                    ? allItems
                    : allItems.where((item) => 
                        item.itemDefinition.name.toLowerCase().contains(_searchQuery) ||
                        (item.itemDefinition.barcode?.toLowerCase().contains(_searchQuery) ?? false)
                      ).toList();
                
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text('No results found for "$_searchQuery"'),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    _loadItems();
                  },
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      
                      return InventoryListItem(
                        itemDefinition: item.itemDefinition,
                        stockCount: item.stockCount,
                        inventoryCount: item.inventoryCount,
                        isEmptyItem: item.isEmptyItem,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ItemDetailScreen(itemDefinition: item.itemDefinition),
                            ),
                          ).then((_) {
                            // Refresh data when returning from details
                            _loadItems();
                          });
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}