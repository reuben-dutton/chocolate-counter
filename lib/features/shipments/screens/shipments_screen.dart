import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/common/utils/gesture_handler.dart';
import 'package:food_inventory/common/utils/navigation_utils.dart';
import 'package:food_inventory/common/widgets/contextual_action_menu.dart';
import 'package:food_inventory/features/inventory/screens/add_item_definition_screen.dart';
import 'package:food_inventory/features/shipments/bloc/shipment_bloc.dart';
import 'package:food_inventory/features/shipments/screens/add_shipment_screen.dart';
import 'package:food_inventory/features/shipments/screens/shipment_detail_screen.dart';
import 'package:food_inventory/features/shipments/services/shipment_service.dart';
import 'package:food_inventory/features/shipments/widgets/shipment_list_item.dart';
import 'package:food_inventory/features/settings/screens/settings_screen.dart';
import 'package:provider/provider.dart';

class ShipmentsScreen extends StatefulWidget {
  const ShipmentsScreen({super.key});

  @override
  _ShipmentsScreenState createState() => _ShipmentsScreenState();
}

class _ShipmentsScreenState extends State<ShipmentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
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
    final shipmentService = Provider.of<ShipmentService>(context, listen: false);
    
    return BlocProvider(
      create: (context) => ShipmentBloc(shipmentService)
        ..add(const InitializeShipmentsScreen()),
      child: BlocListener<ShipmentBloc, ShipmentState>(
        listenWhen: (previous, current) => current.error != null && previous.error != current.error,
        listener: (context, state) {
          if (state.error != null) {
            context.read<ShipmentBloc>().handleError(context, state.error!);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: _isSearchVisible 
                ? TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Search shipments...',
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
                : const Text('Shipments'),
            actions: [
              if (!_isSearchVisible) 
                IconButton(
                  icon: const Icon(Icons.search, size: 24),
                  onPressed: () => _toggleSearch(true),
                ),
            ],
          ),
          body: _buildGestureDetector(),
        ),
      ),
    );
  }
  
  Widget _buildGestureDetector() {
    // Create gesture handler for this screen
    final gestureHandler = GestureHandler(
      onCreateAction: _navigateToAddShipment,
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
    return _ShipmentsList(
      searchQuery: _searchQuery,
      onLongPress: _handleShipmentLongPress,
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
  
  void _navigateToAddItemDefinition(BuildContext context) {
    NavigationUtils.navigateWithSlide(
      context,
      const AddItemDefinitionScreen(),
    );
  }
  
  void _navigateToAddShipment() {
    NavigationUtils.navigateWithSlide(
      context,
      const AddShipmentScreen(),
    ).then((_) {
      if (mounted) {
        context.read<ShipmentBloc>().add(const LoadShipments());
      }
    });
  }
  
  void _handleShipmentLongPress(BuildContext context, dynamic shipment, Offset position) async {
    final action = await ContextualActionMenu.showShipmentActions(
      context,
      position,
    );
    
    if (action == null) return;
    
    switch (action) {
      case 'view':
        NavigationUtils.navigateWithSlide(
          context,
          ShipmentDetailScreen(shipment: shipment),
        ).then((_) {
          // Refresh data when returning from details
          context.read<ShipmentBloc>().add(const LoadShipments());
        });
        break;
      case 'delete':
        if (shipment.id != null) {
          try {
            context.read<ShipmentBloc>().add(DeleteShipment(shipment.id));
            ErrorHandler.showSuccessSnackBar(context, 'Shipment deleted');
          } catch (e, stackTrace) {
            ErrorHandler.handleServiceError(
              context, 
              e,
              service: 'Shipment',
              operation: 'deletion',
              stackTrace: stackTrace
            );
          }
        }
        break;
      // Other actions would be implemented here
    }
  }
}

class _ShipmentsList extends StatelessWidget {
  final String searchQuery;
  final Function(BuildContext context, dynamic shipment, Offset position)? onLongPress;
  
  const _ShipmentsList({
    required this.searchQuery,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShipmentBloc, ShipmentState>(
      buildWhen: (previous, current) => 
        (current is ShipmentLoading && previous is! ShipmentLoading) || 
        (current is ShipmentsLoaded && (previous is! ShipmentsLoaded || 
            previous.shipments != (current).shipments)),
      builder: (context, state) {
        if (state is ShipmentLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ShipmentsLoaded) {
          final allShipments = state.shipments;
          
          if (allShipments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No shipments found'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Shipment'),
                    onPressed: () => _navigateToAddShipment(context),
                  ),
                ],
              ),
            );
          }
          
          // Filter shipments by search query (in memory)
          final shipments = searchQuery.isEmpty
              ? allShipments
              : allShipments.where((shipment) => 
                  (shipment.name?.toLowerCase().contains(searchQuery) ?? false) ||
                  shipment.date.toString().contains(searchQuery)
                ).toList();

          if (shipments.isEmpty) {
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
              context.read<ShipmentBloc>().add(const LoadShipments());
            },
            child: ListView.builder(
              itemCount: shipments.length,
              itemBuilder: (context, index) {
                final shipment = shipments[index];
                return GestureDetector(
                  onLongPress: onLongPress != null ? () {
                    // Get the global position for the context menu
                    final RenderBox box = context.findRenderObject() as RenderBox;
                    final position = box.localToGlobal(
                      box.size.center(Offset.zero),
                    );
                    onLongPress!(context, shipment, position);
                  } : null,
                  child: ShipmentListItem(
                    shipment: shipment,
                    onTap: () {
                      NavigationUtils.navigateWithSlide(
                        context,
                        ShipmentDetailScreen(shipment: shipment),
                      ).then((_) {
                        // Refresh data when returning from details
                        context.read<ShipmentBloc>().add(const LoadShipments());
                      });
                    },
                    onDelete: () async {
                      try {
                        context.read<ShipmentBloc>().add(DeleteShipment(shipment.id!));
                        ErrorHandler.showSuccessSnackBar(context, 'Shipment deleted');
                      } catch (e, stackTrace) {
                        ErrorHandler.handleServiceError(
                          context, 
                          e,
                          service: 'Shipment',
                          operation: 'deletion',
                          stackTrace: stackTrace
                        );
                      }
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

  void _navigateToAddShipment(BuildContext context) {
    NavigationUtils.navigateWithSlide(
      context,
      const AddShipmentScreen(),
    ).then((_) {
      context.read<ShipmentBloc>().add(const LoadShipments());
    });
  }
}