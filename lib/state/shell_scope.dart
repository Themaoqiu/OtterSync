import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShellScope extends InheritedWidget {
  const MainShellScope({
    super.key,
    required this.shell,
    required super.child,
  });

  final StatefulNavigationShell shell;

  static StatefulNavigationShell? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<MainShellScope>()
        ?.shell;
  }

  @override
  bool updateShouldNotify(MainShellScope oldWidget) =>
      oldWidget.shell != shell;
}

const Map<String, int> kShellRouteIndex = {
  '/home': 0,
  '/spaces': 1,
  '/all-work': 2,
  '/dashboards': 3,
  '/notifications': 4,
};

void navigateOrSwitchTab(BuildContext context, String route) {
  final shell = MainShellScope.maybeOf(context);
  final index = kShellRouteIndex[route];
  if (shell != null && index != null) {
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
    return;
  }
  GoRouter.of(context).push(route);
}
