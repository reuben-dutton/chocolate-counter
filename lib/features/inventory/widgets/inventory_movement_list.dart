import 'package:flutter/material.dart';
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
        color: theme.dividerColor.withAlpha(25),
      ),
      itemBuilder: (context, index) {
        final movement = movements[index];
        final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
        
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              borderRadius: BorderRadius.circular(16),
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

  String _getMovementSign(MovementType type) {
    switch (type) {
      case MovementType.stockSale:
        return '';
      case MovementType.inventoryToStock:
        return '';
      case MovementType.shipmentToInventory:
        return '';
    }
  }
      
  Widget _getMovementIcon(MovementType type, ThemeData theme) {
    switch (type) {
      case MovementType.stockSale:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.remove_shopping_cart, 
            color: theme.colorScheme.secondary, 
            size: 18
          ),
        );
      case MovementType.inventoryToStock:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.move_up, 
            color: theme.colorScheme.secondary, 
            size: 18
          ),
        );
      case MovementType.shipmentToInventory:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.move_to_inbox, 
            color: theme.colorScheme.secondary, 
            size: 18
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