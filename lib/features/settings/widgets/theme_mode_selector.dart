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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: ThemeMode.values.map((mode) {
                    return _buildThemeOption(
                      context: context,
                      mode: mode,
                      selected: state.themeMode == mode,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required ThemeMode mode,
    required bool selected,
  }) {
    final theme = Theme.of(context);
    
    IconData icon;
    String label;
    
    switch (mode) {
      case ThemeMode.system:
        icon = Icons.brightness_auto;
        label = 'System';
        break;
      case ThemeMode.light:
        icon = Icons.light_mode;
        label = 'Light';
        break;
      case ThemeMode.dark:
        icon = Icons.dark_mode;
        label = 'Dark';
        break;
    }
    
    return GestureDetector(
      onTap: () => context.read<PreferencesBloc>().add(SetThemeMode(mode)),
      child: Container(
        width: 110,
        margin: const EdgeInsets.symmetric(horizontal: 8),
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