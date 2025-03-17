import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/features/settings/bloc/preferences_bloc.dart';

class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreferencesBloc, PreferencesState>(
      buildWhen: (previous, current) => previous.themeMode != current.themeMode,
      builder: (context, state) {
        final theme = Theme.of(context);
        
        return Padding(
          padding: EdgeInsets.symmetric(
            vertical: ConfigService.defaultPadding,
            horizontal: ConfigService.smallPadding
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.palette, size: ConfigService.defaultIconSize),
                title: const Text('Theme'),
                subtitle: _getThemeSubtitle(state.themeMode),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildThemeOption(
                    context: context,
                    icon: Icons.brightness_auto,
                    label: 'System',
                    selected: state.themeMode == ThemeMode.system,
                    mode: ThemeMode.system,
                  ),
                  _buildThemeOption(
                    context: context,
                    icon: Icons.light_mode,
                    label: 'Light',
                    selected: state.themeMode == ThemeMode.light,
                    mode: ThemeMode.light,
                  ),
                  _buildThemeOption(
                    context: context,
                    icon: Icons.dark_mode,
                    label: 'Dark',
                    selected: state.themeMode == ThemeMode.dark,
                    mode: ThemeMode.dark,
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
    required ThemeMode mode,
  }) {
    final theme = Theme.of(context);
    
    return InkWell(
      borderRadius: BorderRadius.circular(ConfigService.borderRadiusLarge),
      onTap: () => context.read<PreferencesBloc>().add(SetThemeMode(mode)),
              child: Container(
        width: 90,
        padding: EdgeInsets.all(ConfigService.smallPadding),
        decoration: BoxDecoration(
          color: selected 
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(ConfigService.borderRadiusLarge),
          border: Border.all(
            color: selected 
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.3),
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
              size: 28,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: ConfigService.tinyPadding),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? theme.colorScheme.primary
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

  Widget _getThemeSubtitle(ThemeMode mode) {
    String text;
    switch (mode) {
      case ThemeMode.system:
        text = 'Use system settings';
      case ThemeMode.light:
        text = 'Light mode';
      case ThemeMode.dark:
        text = 'Dark mode';
    }
    return Text(text, style: const TextStyle(fontSize: 12));
  }
}