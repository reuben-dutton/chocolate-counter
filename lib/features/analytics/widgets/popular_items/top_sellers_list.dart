import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/features/analytics/models/analytics_data.dart';

class TopSellersList extends StatelessWidget {
  final List<PopularItemData> topItems;
  final int totalSales;

  const TopSellersList({
    super.key,
    required this.topItems,
    required this.totalSales,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: EdgeInsets.zero,
      child: Column(
        children: topItems.map((item) {
          final percentage = (item.salesCount / totalSales * 100).toStringAsFixed(1);
          final index = topItems.indexOf(item);
          
          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ConfigService.tinyPadding, 
              vertical: ConfigService.smallPadding
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                SizedBox(width: ConfigService.defaultPadding),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.itemName,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: ConfigService.tinyPadding),
                      LinearProgressIndicator(
                        value: item.salesCount / topItems.first.salesCount,
                        backgroundColor: theme.colorScheme.surface,
                        color: theme.colorScheme.primary,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(ConfigService.borderRadiusMedium),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: ConfigService.defaultPadding),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${item.salesCount}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      '$percentage%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(ConfigService.alphaDefault),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}