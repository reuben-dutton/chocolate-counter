import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/features/export/bloc/export_bloc.dart';
import 'package:food_inventory/features/export/models/export_mode.dart';

class ExportModeSelector extends StatelessWidget {
  const ExportModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocBuilder<ExportBloc, ExportState>(
      buildWhen: (previous, current) => 
        previous is! ExportConfigured || 
        current is! ExportConfigured || 
        previous.mode != current.mode,
      builder: (context, state) {
        final currentMode = state is ExportConfigured ? state.mode : null;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose the format you want to export your data in:',
              style: theme.textTheme.bodyLarge,
            ),
            SizedBox(height: ConfigService.largePadding),
            
            // Mode selector cards
            ...ExportMode.values.map((mode) => _buildModeCard(
              context,
              mode: mode,
              isSelected: mode == currentMode,
              onTap: () => _onModeSelected(context, mode),
            )),
            
            SizedBox(height: ConfigService.largePadding),
            
            // Mode description
            if (currentMode != null)
              Container(
                padding: EdgeInsets.all(ConfigService.mediumPadding),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(ConfigService.borderRadiusMedium),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.primary,
                      size: ConfigService.mediumIconSize,
                    ),
                    SizedBox(width: ConfigService.mediumPadding),
                    Expanded(
                      child: Text(
                        currentMode.description,
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
  
  Widget _buildModeCard(
    BuildContext context, {
    required ExportMode mode,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: EdgeInsets.only(bottom: ConfigService.mediumPadding),
      child: Material(
        color: isSelected ? theme.colorScheme.primaryContainer : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(ConfigService.borderRadiusMedium),
        child: InkWell(
          borderRadius: BorderRadius.circular(ConfigService.borderRadiusMedium),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(ConfigService.mediumPadding),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(ConfigService.borderRadiusMedium),
              border: Border.all(
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHigh,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      mode.icon,
                      color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
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
                        mode.displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? theme.colorScheme.primary : null,
                        ),
                      ),
                      SizedBox(height: ConfigService.tinyPadding),
                      Text(
                        mode.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                    size: ConfigService.mediumIconSize,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _onModeSelected(BuildContext context, ExportMode mode) {
    context.read<ExportBloc>().add(SetExportMode(mode));
  }
}