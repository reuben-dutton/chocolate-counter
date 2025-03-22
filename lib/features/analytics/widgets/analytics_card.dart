import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';

class AnalyticsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? titleChild;
  final VoidCallback? onTap;
  final bool isLoading;

  const AnalyticsCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.titleChild,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ConfigService.smallPadding, 
        vertical: ConfigService.smallPadding
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ConfigService.defaultBorderRadius),
        child: Padding(
          padding: EdgeInsets.all(ConfigService.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row with optional widget
              Row(
                mainAxisAlignment: titleChild != null 
                    ? MainAxisAlignment.spaceBetween 
                    : MainAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        icon, 
                        size: ConfigService.mediumIconSize,
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(width: ConfigService.smallPadding),
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  if (titleChild != null) titleChild!,
                ],
              ),
              
              SizedBox(height: ConfigService.defaultPadding),
              
              // Loading indicator or content
              if (isLoading)
                const Center(
                  heightFactor: 2,
                  child: CircularProgressIndicator(),
                )
              else
                child,
            ],
          ),
        ),
      ),
    );
  }
}