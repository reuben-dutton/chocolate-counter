import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/common/widgets/section_header_widget.dart';

class AnalyticsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final VoidCallback? onTap;
  final int totalStockCount;  // Added the required parameter

  const AnalyticsCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    required this.totalStockCount, // Made this required
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: ConfigService.smallPadding, 
        vertical: ConfigService.smallPadding
      ),
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ConfigService.defaultBorderRadius)
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ConfigService.defaultBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(ConfigService.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SectionHeaderWidget(
                    title: title,
                    icon: icon,
                    iconColor: theme.colorScheme.primary,
                  ),
                  
                  // Added a chip to display the total stock count
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Total Stock: $totalStockCount',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ConfigService.defaultPadding),
              child,
            ],
          ),
        ),
      ),
    );
  }
}