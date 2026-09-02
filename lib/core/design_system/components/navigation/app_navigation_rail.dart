import 'package:flutter/material.dart';
import 'app_bottom_nav.dart';

/// Themed navigation rail for wide layouts. Extended mode shows labels;
/// collapsed mode shows icons only.
class AppNavigationRail extends StatelessWidget {
  const AppNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.extended = true,
    this.leading,
    this.trailing,
    this.minExtendedWidth = 180,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<AppNavDestination> destinations;
  final bool extended;
  final Widget? leading;
  final Widget? trailing;
  final double minExtendedWidth;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      extended: extended,
      minExtendedWidth: minExtendedWidth,
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      leading: leading,
      trailing: trailing,
      destinations: [
        for (final destination in destinations)
          NavigationRailDestination(
            icon: Icon(destination.icon),
            selectedIcon: destination.activeIcon != null
                ? Icon(destination.activeIcon)
                : null,
            label: Text(destination.label),
          ),
      ],
    );
  }
}
