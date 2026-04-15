import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ottersync/pages/Account/index.dart';
import 'package:ottersync/pages/AllWork/index.dart';
import 'package:ottersync/pages/Dashboard/index.dart';
import 'package:ottersync/pages/Home/index.dart';
import 'package:ottersync/pages/Main/index.dart';
import 'package:ottersync/pages/Notifications/index.dart';
import 'package:ottersync/pages/SpaceDetails/index.dart';
import 'package:ottersync/pages/Spaces/index.dart';
import 'package:ottersync/state/theme_controller.dart';
import 'package:ottersync/theme/design_tokens.dart';

ThemeData _buildAppTheme(AppPalette palette, Brightness brightness) {
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: palette.scaffold,
  );

  return base.copyWith(
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: palette.primary,
      onPrimary: Colors.white,
      secondary: palette.primaryStrong,
      onSecondary: Colors.white,
      error: palette.danger,
      onError: Colors.white,
      surface: palette.surface,
      onSurface: palette.textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: palette.scaffold,
      foregroundColor: palette.textPrimary,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: palette.surface,
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpace.radiusLarge),
        side: brightness == Brightness.dark
            ? BorderSide(color: palette.border)
            : BorderSide.none,
      ),
    ),
    dividerColor: palette.divider,
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.surface,
      elevation: 8,
      shadowColor: palette.shadow,
      height: 76, // More compact bottom bar
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(
          color: palette.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      indicatorColor: palette.primarySoft.withValues(alpha: 0.7),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? palette.primary : palette.textTertiary,
          size: 26,
        );
      }),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.scaffold,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpace.radiusLarge),
        ),
      ),
    ),
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        color: palette.textPrimary,
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
      ),
      headlineMedium: TextStyle(
        color: palette.textPrimary,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
      ),
      titleLarge: TextStyle(
        color: palette.textPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
      ),
      titleMedium: TextStyle(
        color: palette.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
      bodyLarge: TextStyle(
        color: palette.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      bodyMedium: TextStyle(
        color: palette.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
      ),
      bodySmall: TextStyle(
        color: palette.textTertiary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      ),
      labelLarge: TextStyle(
        color: palette.primary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surface,
      hintStyle: TextStyle(color: palette.textSecondary, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpace.radius),
        borderSide: BorderSide(color: palette.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpace.radius),
        borderSide: BorderSide(color: palette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpace.radius),
        borderSide: BorderSide(color: palette.primary),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: palette.primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpace.radius),
        ),
      ),
    ),
  );
}

final ThemeController _themeController = ThemeController();

final GoRouter _rootRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(path: '/', redirect: (context, state) => '/home'),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainPage(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeView(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/spaces',
              builder: (context, state) => const SpacesView(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/all-work',
              builder: (context, state) => const AllWorkView(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboards',
              builder: (context, state) => const DashboardView(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/notifications',
              builder: (context, state) => const NotificationsView(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(path: '/account', builder: (context, state) => const AccountView()),
    GoRoute(
      path: '/space-details',
      builder: (context, state) => const SpaceDetailsView(),
    ),
  ],
);

Widget getRootWidget() {
  return ThemeControllerScope(
    notifier: _themeController,
    child: AnimatedBuilder(
      animation: _themeController,
      builder: (context, child) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: _buildAppTheme(AppColors.light, Brightness.light),
          darkTheme: _buildAppTheme(AppColors.dark, Brightness.dark),
          themeMode: _themeController.themeMode,
          routerConfig: _rootRouter,
        );
      },
    ),
  );
}
