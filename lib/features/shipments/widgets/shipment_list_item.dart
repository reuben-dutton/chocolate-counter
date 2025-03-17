import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';
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
      margin: EdgeInsets.symmetric(horizontal: ConfigService.smallPadding, vertical: ConfigService.tinyPadding),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ConfigService.borderRadiusMedium)
      ),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(ConfigService.borderRadiusMedium),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(ConfigService.smallPadding),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withAlpha(ConfigService.alphaLight),
                  borderRadius: BorderRadius.circular(ConfigService.borderRadiusMedium),
                ),
                child: Center(
                  child: Icon(
                    Icons.local_shipping,
                    color: theme.colorScheme.secondary,
                    size: ConfigService.defaultIconSize,
                  ),
                ),
              ),
              SizedBox(width: ConfigService.mediumPadding),
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
                    SizedBox(height: ConfigService.tinyPadding),
                    Row(
                      children: [
                        CountChipWidget(
                          icon: Icons.event,
                          count: -1, // Special case: use -1 to display text instead of count
                          color: theme.colorScheme.secondary,
                          iconSize: ConfigService.smallIconSize,
                          fontSize: 12,
                          text: formattedDate,
                        ),
                        SizedBox(width: ConfigService.smallPadding),
                        CountChipWidget(
                          icon: Icons.inventory_2,
                          count: shipment.items.length,
                          color: theme.colorScheme.secondary,
                          iconSize: ConfigService.smallIconSize,
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
                size: ConfigService.mediumIconSize, 
                color: theme.colorScheme.onSurface.withAlpha(ConfigService.alphaDefault)
              ),
            ],
          ),
        ),
      ),
    );
  }
}