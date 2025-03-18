import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/features/settings/bloc/preferences_bloc.dart';
import 'package:food_inventory/theme/theme_loader.dart';

class ThemeTypeSelector extends StatelessWidget {
  const ThemeTypeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreferencesBloc, PreferencesState>(
      buildWhen: (previous, current) => previous.themeType != current.themeType,
      builder: (context, state) {
        final theme = Theme.of(context);
        final availableThemes = ThemeLoader.themes;
        
        return Padding(
          padding: EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 8
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.color_lens, size: ConfigService.defaultIconSize),
                title: const Text('Theme Style'),
                subtitle: Text(
                  availableThemes[state.themeType]?.description ?? 'Custom theme',
                  style: const TextStyle(fontSize: 12)
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final entry in availableThemes.entries)
                    _buildThemeOption(
                      context: context,
                      icon: entry.value.icon,
                      label: entry.value.name,
                      selected: state.themeType == entry.key,
                      themeKey: entry.key,
                      // Use the primary color from light scheme for theme option
                      color: entry.value.lightScheme.primary,
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool selected,
    required String themeKey,
    required Color color,
  }) {
    final theme = Theme.of(context);
    
    return InkWell(
      borderRadius: BorderRadius.circular(ConfigService.borderRadiusLarge),
      onTap: () => context.read<PreferencesBloc>().add(SetThemeType(themeKey)),
      child: Container(
        // width: 70,
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected 
              ? color.withAlpha(ConfigService.alphaLight)
              : theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(ConfigService.borderRadiusLarge),
          border: Border.all(
            color: selected 
                ? color
                : theme.colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? [
            BoxShadow(
              color: color.withAlpha(ConfigService.alphaLight),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: ConfigService.configIconSize,
              color: selected
                  ? color
                  : theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? color
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}