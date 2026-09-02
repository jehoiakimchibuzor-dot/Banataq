import 'package:flutter/material.dart';

/// One destination in a [AppBottomNav] or [AppNavigationRail].
class AppNavDestination {
  const AppNavDestination({
    required this.icon,
    required this.label,
    this.activeIcon,
    this.tooltip,
  });

  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final String? tooltip;
}

/// Themed bottom navigation bar for compact layouts.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<AppNavDestination> destinations;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: [
        for (final destination in destinations)
          NavigationDestination(
            icon: Icon(destination.icon),
            selectedIcon: destination.activeIcon != null
                ? Icon(destination.activeIcon)
                : null,
            label: destination.label,
            tooltip: destination.tooltip,
          ),
      ],
    );
  }
}
