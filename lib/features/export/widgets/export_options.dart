import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/features/export/bloc/export_bloc.dart';

class ExportOptions extends StatelessWidget {
  const ExportOptions({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocBuilder<ExportBloc, ExportState>(
      buildWhen: (previous, current) => 
        previous is! ExportConfigured || 
        current is! ExportConfigured || 
        previous.includeImages != current.includeImages,
      builder: (context, state) {
        final includeImages = state is ExportConfigured ? state.includeImages : false;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Options',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ConfigService.mediumPadding),
            
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ConfigService.borderRadiusMedium),
                side: BorderSide(color: theme.colorScheme.outline),
              ),
              child: Padding(
                padding: EdgeInsets.all(ConfigService.mediumPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Include images
                    SwitchListTile(
                      title: const Text('Include Images'),
                      subtitle: const Text(
                        'Export item images with the data (increases export size)',
                      ),
                      value: includeImages,
                      onChanged: (value) {
                        context.read<ExportBloc>().add(SetIncludeImages(value));
                      },
                    ),
                    
                    // More options can be added here in the future
                  ],
                ),
              ),
            ),
            
            SizedBox(height: ConfigService.defaultPadding),
            
            // Note about options
            Container(
              padding: EdgeInsets.all(ConfigService.mediumPadding),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(ConfigService.borderRadiusMedium),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                    size: ConfigService.mediumIconSize,
                  ),
                  SizedBox(width: ConfigService.mediumPadding),
                  Expanded(
                    child: Text(
                      'All exports include reference information about the data structure and enum values to help you understand the exported data.',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}