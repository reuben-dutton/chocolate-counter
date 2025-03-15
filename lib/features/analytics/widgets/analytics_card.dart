import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/common/widgets/section_header_widget.dart';

class AnalyticsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final VoidCallback? onTap;

  const AnalyticsCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
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
              SectionHeaderWidget(
                title: title,
                icon: icon,
                iconColor: theme.colorScheme.primary,
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