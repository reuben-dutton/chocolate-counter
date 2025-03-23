// lib/features/export/widgets/export_format_card.dart
import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';

class ExportFormatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool isLoading;

  const ExportFormatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ConfigService.borderRadiusMedium),
      ),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        child: Padding(
          padding: EdgeInsets.all(ConfigService.defaultPadding),
          child: isLoading 
              ? _buildLoadingState(theme)
              : _buildContent(theme),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: ConfigService.largeIconSize,
          color: theme.colorScheme.primary,
        ),
        SizedBox(height: ConfigService.smallPadding),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: ConfigService.tinyPadding),
        Text(
          description,
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: ConfigService.largeIconSize,
          width: ConfigService.largeIconSize,
          child: CircularProgressIndicator(),
        ),
        SizedBox(height: ConfigService.smallPadding),
        Text(
          'Exporting...',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: ConfigService.tinyPadding),
        Text(
          'Please wait',
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}