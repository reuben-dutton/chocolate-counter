import 'package:flutter/material.dart';

/// A class for handling long-press contextual menu actions
class ContextualActionMenu {
  /// Shows a contextual menu at the given position with the provided actions
  static Future<T?> show<T>(
    BuildContext context,
    Offset position,
    List<ContextualAction<T>> actions, {
    String? title,
  }) async {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
    final items = <PopupMenuEntry<T>>[];
    
    // Add title if provided
    if (title != null) {
      items.add(
        PopupMenuItem<T>(
          enabled: false,
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
      items.add(const PopupMenuDivider());
    }
    
    // Add each action
    for (final action in actions) {
      if (action.isEnabled) {
        items.add(
          PopupMenuItem<T>(
            value: action.value,
            child: _buildMenuItem(action),
          ),
        );
      } else {
        items.add(
          PopupMenuItem<T>(
            enabled: false,
            child: Opacity(
              opacity: 0.5,
              child: _buildMenuItem(action),
            ),
          ),
        );
      }
    }
    
    return showMenu<T>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(
          position,
          position,
        ),
        Offset.zero & overlay.size,
      ),
      items: items,
    );
  }
  
  static Widget _buildMenuItem<T>(ContextualAction<T> action) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (action.icon != null) ...[
          Icon(
            action.icon,
            color: action.color,
            size: 20,
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(action.label),
        ),
      ],
    );
  }
  
  /// Shows a specific menu for item detail actions
  static Future<String?> showItemActions(
    BuildContext context,
    Offset position, {
    bool canEdit = true,
    bool canDelete = true,
    bool canMove = true,
    bool hasStock = true,
  }) async {
    final actions = <ContextualAction<String>>[
      ContextualAction<String>(
        label: 'View Details',
        icon: Icons.info_outline,
        value: 'view',
        isEnabled: true,
      ),
      ContextualAction<String>(
        label: 'Edit Item',
        icon: Icons.edit,
        value: 'edit',
        isEnabled: canEdit,
      ),
      if (hasStock)
        ContextualAction<String>(
          label: 'Record Sale',
          icon: Icons.remove_shopping_cart,
          value: 'sale',
          isEnabled: true,
        ),
      if (canMove)
        ContextualAction<String>(
          label: 'Move to Stock',
          icon: Icons.move_up,
          value: 'move',
          isEnabled: true,
        ),
      ContextualAction<String>(
        label: 'Delete Item',
        icon: Icons.delete,
        color: Colors.red,
        value: 'delete',
        isEnabled: canDelete,
      ),
    ];
    
    return show<String>(
      context,
      position,
      actions,
      title: 'Item Actions',
    );
  }
  
  /// Shows a specific menu for shipment actions
  static Future<String?> showShipmentActions(
    BuildContext context,
    Offset position, {
    bool canEdit = true,
    bool canDelete = true,
  }) async {
    final actions = <ContextualAction<String>>[
      ContextualAction<String>(
        label: 'View Details',
        icon: Icons.info_outline,
        value: 'view',
        isEnabled: true,
      ),
      ContextualAction<String>(
        label: 'Edit Shipment',
        icon: Icons.edit,
        value: 'edit',
        isEnabled: canEdit,
      ),
      ContextualAction<String>(
        label: 'Delete Shipment',
        icon: Icons.delete,
        color: Colors.red,
        value: 'delete',
        isEnabled: canDelete,
      ),
    ];
    
    return show<String>(
      context,
      position,
      actions,
      title: 'Shipment Actions',
    );
  }
}

/// Model class for a contextual menu action
class ContextualAction<T> {
  final String label;
  final IconData? icon;
  final T value;
  final bool isEnabled;
  final Color? color;
  
  ContextualAction({
    required this.label,
    this.icon,
    required this.value,
    this.isEnabled = true,
    this.color,
  });
}