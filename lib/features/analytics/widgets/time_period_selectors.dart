import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/features/analytics/models/time_period.dart';

class MinimalistTimePeriodSelector extends StatelessWidget {
  final TimePeriod selectedPeriod;
  final Function(TimePeriod) onPeriodChanged;

  const MinimalistTimePeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(top: ConfigService.smallPadding),
      child: SizedBox(
        height: 28,
        child: DropdownButtonHideUnderline(
          child: DropdownButton<TimePeriod>(
            value: selectedPeriod,
            isDense: true,
            borderRadius: BorderRadius.circular(ConfigService.borderRadiusMedium),
            icon: Icon(
              Icons.keyboard_arrow_down, 
              size: ConfigService.smallIconSize, 
              color: theme.colorScheme.primary,
            ),
            items: TimePeriod.values.map((period) {
              return DropdownMenuItem<TimePeriod>(
                value: period,
                child: Text(
                  getTimePeriodLabel(period),
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              );
            }).toList(),
            onChanged: (period) {
              if (period != null) {
                onPeriodChanged(period);
              }
            },
          ),
        ),
      ),
    );
  }
}

/// Alternative minimalist approach using a simple popup menu button
class PopupTimePeriodSelector extends StatelessWidget {
  final TimePeriod selectedPeriod;
  final Function(TimePeriod) onPeriodChanged;

  const PopupTimePeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      borderRadius: BorderRadius.circular(ConfigService.borderRadiusMedium),
      onTap: () => _showOptionsMenu(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: ConfigService.tinyPadding),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              getTimePeriodLabel(selectedPeriod),
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down, 
              size: ConfigService.smallIconSize, 
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
  
  void _showOptionsMenu(BuildContext context) {
    final theme = Theme.of(context);
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    
    showMenu<TimePeriod>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ConfigService.borderRadiusMedium),
      ),
      items: TimePeriod.values.map((period) {
        return PopupMenuItem<TimePeriod>(
          value: period,
          child: Row(
            children: [
              if (period == selectedPeriod)
                Icon(Icons.check, size: ConfigService.smallIconSize, color: theme.colorScheme.primary),
              if (period == selectedPeriod)
                const SizedBox(width: ConfigService.smallPadding),
              Text(getTimePeriodLabel(period)),
            ],
          ),
        );
      }).toList(),
    ).then((selectedValue) {
      if (selectedValue != null) {
        onPeriodChanged(selectedValue);
      }
    });
  }
}

/// Even more minimalist approach using segmented button
class CompactTimePeriodSelector extends StatelessWidget {
  final TimePeriod selectedPeriod;
  final Function(TimePeriod) onPeriodChanged;

  const CompactTimePeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<TimePeriod>(
      showSelectedIcon: false,
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.selected)) {
              return Theme.of(context).colorScheme.primary.withOpacity(0.1);
            }
            return Colors.transparent;
          },
        ),
        foregroundColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.selected)) {
              return Theme.of(context).colorScheme.primary;
            }
            return Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
          },
        ),
        padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 4, vertical: 0)
        ),
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: MaterialStateProperty.all(const Size(0, 28)),
        side: MaterialStateProperty.all(
          BorderSide.none
        ),
      ),
      segments: _buildSegments(),
      selected: {selectedPeriod},
      onSelectionChanged: (Set<TimePeriod> selection) {
        if (selection.isNotEmpty) {
          onPeriodChanged(selection.first);
        }
      },
    );
  }
  
  List<ButtonSegment<TimePeriod>> _buildSegments() {
    return [
      ButtonSegment<TimePeriod>(
        value: TimePeriod.allTime,
        label: const Text('All', style: TextStyle(fontSize: 11)),
      ),
      ButtonSegment<TimePeriod>(
        value: TimePeriod.lastSixMonths,
        label: const Text('6M', style: TextStyle(fontSize: 11)),
      ),
      ButtonSegment<TimePeriod>(
        value: TimePeriod.lastMonth,
        label: const Text('1M', style: TextStyle(fontSize: 11)),
      ),
      ButtonSegment<TimePeriod>(
        value: TimePeriod.lastWeek,
        label: const Text('1W', style: TextStyle(fontSize: 11)),
      ),
    ];
  }
}