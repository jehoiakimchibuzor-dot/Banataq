import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart';

/// One selectable filter option.
class FilterOption {
  const FilterOption({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.count,
    this.icon,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final int? count;
  final IconData? icon;
}

/// Horizontally scrollable row of [AppFilterChip]s shared by the workspace
/// list tabs (Sessions, Tasks, Files, Memory, Timeline).
class WorkspaceFilterChips extends StatelessWidget {
  const WorkspaceFilterChips({super.key, required this.options});

  final List<FilterOption> options;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            AppFilterChip(
              label: options[i].label,
              selected: options[i].selected,
              onSelected: options[i].onSelected,
              count: options[i].count,
              icon: options[i].icon,
            ),
            if (i < options.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
