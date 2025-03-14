import 'package:flutter/material.dart';
import 'package:food_inventory/data/models/shipment.dart';
import 'package:food_inventory/common/widgets/count_chip_widget.dart';
import 'package:intl/intl.dart';

class ShipmentListItem extends StatelessWidget {
  final Shipment shipment;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ShipmentListItem({
    super.key,
    required this.shipment,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = DateFormat('yyyy-MM-dd').format(shipment.date);
    
    return Card(
      color: theme.colorScheme.surface,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    Icons.local_shipping,
                    color: theme.colorScheme.secondary,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shipment.name ?? 'Shipment $formattedDate',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        CountChipWidget(
                          icon: Icons.event,
                          count: -1, // Special case: use -1 to display text instead of count
                          color: theme.colorScheme.secondary,
                          iconSize: 14,
                          fontSize: 12,
                          text: formattedDate,
                        ),
                        const SizedBox(width: 8),
                        CountChipWidget(
                          icon: Icons.inventory_2,
                          count: shipment.items.length,
                          color: theme.colorScheme.secondary,
                          iconSize: 14,
                          fontSize: 12,
                          text: shipment.items.length == 1 ? '1 item' : '${shipment.items.length} items',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right, 
                size: 18, 
                color: theme.colorScheme.onSurface.withAlpha(128)
              ),
            ],
          ),
        ),
      ),
    );
  }
}