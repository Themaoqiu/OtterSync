import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ottersync/theme/design_tokens.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    _TabItem('主页', Icons.home_outlined, Icons.home_rounded),
    _TabItem('空间', Icons.public_outlined, Icons.public_rounded),
    _TabItem(
      '所有工作',
      Icons.library_add_check_outlined,
      Icons.library_add_check_rounded,
    ),
    _TabItem('仪表板', Icons.dashboard_outlined, Icons.dashboard_rounded),
    _TabItem(
      '通知',
      Icons.notifications_none_rounded,
      Icons.notifications_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);

    return Scaffold(
      body: SafeArea(bottom: false, child: navigationShell),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: palette.surface,
          boxShadow: [
            BoxShadow(
              color: palette.shadow.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            backgroundColor: palette.surface,
            destinations: _tabs
                .map(
                  (tab) => NavigationDestination(
                    icon: Icon(tab.icon),
                    selectedIcon: Icon(tab.selectedIcon),
                    label: tab.label,
                  ),
                )
                .toList(),
            onDestinationSelected: (index) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
