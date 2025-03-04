import 'package:flutter/material.dart';
import 'package:food_inventory/data/models/item_definition.dart';
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
  late InventoryService _inventoryService;
  late Future<List<ItemDefinition>> _itemsFuture;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _inventoryService = Provider.of<InventoryService>(context, listen: false);
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
    setState(() {
      _itemsFuture = _inventoryService.getAllItemDefinitions();
    });
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
            child: FutureBuilder<List<ItemDefinition>>(
              future: _itemsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
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
                
                // Filter items by search query
                final items = _searchQuery.isEmpty
                    ? allItems
                    : allItems.where((item) => 
                        item.name.toLowerCase().contains(_searchQuery) ||
                        (item.barcode?.toLowerCase().contains(_searchQuery) ?? false)
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
                      return FutureBuilder<Map<String, int>>(
                        future: _inventoryService.getItemCounts(item.id!),
                        builder: (context, countsSnapshot) {
                          final stockCount = countsSnapshot.data?['stock'] ?? 0;
                          final inventoryCount = countsSnapshot.data?['inventory'] ?? 0;
                          
                          // Check if item should be displayed with reduced opacity
                          final isEmptyItem = stockCount == 0 && inventoryCount == 0;
                          
                          return InventoryListItem(
                            itemDefinition: item,
                            stockCount: stockCount,
                            inventoryCount: inventoryCount,
                            isEmptyItem: isEmptyItem,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ItemDetailScreen(itemDefinition: item),
                                ),
                              ).then((_) {
                                // Refresh data when returning from details
                                _loadItems();
                              });
                            },
                          );
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