import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/data/models/inventory_movement.dart';
import 'package:intl/intl.dart';

class InventoryMovementList extends StatelessWidget {
  final List<InventoryMovement> movements;

  const InventoryMovementList({
    super.key,
    required this.movements,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: movements.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        thickness: 1,
        color: theme.dividerColor.withAlpha(ConfigService.alphaLight),
      ),
      itemBuilder: (context, index) {
        final movement = movements[index];
        final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
        
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: ConfigService.tinyPadding, vertical: ConfigService.tinyPadding),
          dense: true,
          leading: _getMovementIcon(movement.type, theme),
          title: Text(
            _getMovementTitle(movement.type),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            dateFormat.format(movement.timestamp),
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: ConfigService.mediumPadding, vertical: ConfigService.smallPadding),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              borderRadius: BorderRadius.circular(ConfigService.smallIconSize),
            ),
            child: Text(
              '${movement.quantity}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: theme.colorScheme.onSecondary,
              ),
            ),
          ),
        );
      },
    );
  }
      
  Widget _getMovementIcon(MovementType type, ThemeData theme) {
    switch (type) {
      case MovementType.stockSale:
        return Container(
          padding: const EdgeInsets.all(ConfigService.smallPadding),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withAlpha(ConfigService.alphaLight),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.remove_shopping_cart, 
            color: theme.colorScheme.secondary, 
            size: ConfigService.mediumIconSize
          ),
        );
      case MovementType.inventoryToStock:
        return Container(
          padding: const EdgeInsets.all(ConfigService.smallPadding),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withAlpha(ConfigService.alphaLight),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.move_up, 
            color: theme.colorScheme.secondary, 
            size: ConfigService.mediumIconSize
          ),
        );
      case MovementType.shipmentToInventory:
        return Container(
          padding: const EdgeInsets.all(ConfigService.smallPadding),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withAlpha(ConfigService.alphaLight),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.move_to_inbox, 
            color: theme.colorScheme.secondary, 
            size: ConfigService.mediumIconSize
          ),
        );
    }
  }
  
  String _getMovementTitle(MovementType type) {
    switch (type) {
      case MovementType.stockSale:
        return 'Stock Sale';
      case MovementType.inventoryToStock:
        return 'Moved to Stock';
      case MovementType.shipmentToInventory:
        return 'Purchased';
    }
  }
}