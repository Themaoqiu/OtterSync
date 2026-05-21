import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ottersync/pages/Account/index.dart';
import 'package:ottersync/pages/AllWork/index.dart';
import 'package:ottersync/pages/BootstrapError/index.dart';
import 'package:ottersync/pages/CreateWorkItem/index.dart';
import 'package:ottersync/pages/Dashboard/index.dart';
import 'package:ottersync/pages/Home/index.dart';
import 'package:ottersync/pages/Login/index.dart';
import 'package:ottersync/pages/Main/index.dart';
import 'package:ottersync/pages/Notifications/index.dart';
import 'package:ottersync/pages/Register/index.dart';
import 'package:ottersync/pages/SpaceDetails/index.dart';
import 'package:ottersync/pages/Spaces/index.dart';
import 'package:ottersync/state/auth_controller.dart';
import 'package:ottersync/state/theme_controller.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/viewmodels/work_item_api.dart';

ThemeData _buildAppTheme(AppPalette palette, Brightness brightness) {
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: palette.scaffold,
  );
  final isDark = brightness == Brightness.dark;
  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppSpace.radiusLarge),
    borderSide: BorderSide(color: palette.border),
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
      surfaceContainerHighest: palette.surfaceRaised,
      outline: palette.border,
      outlineVariant: palette.divider,
    ),
    iconTheme: IconThemeData(color: palette.textSecondary),
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
        side: isDark
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
    dialogTheme: DialogThemeData(
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpace.radiusXLarge),
        side: isDark ? BorderSide(color: palette.border) : BorderSide.none,
      ),
    ),
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        color: palette.textPrimary,
        fontSize: 36,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.8,
      ),
      headlineMedium: TextStyle(
        color: palette.textPrimary,
        fontSize: 26,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.6,
      ),
      titleLarge: TextStyle(
        color: palette.textPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.4,
      ),
      titleMedium: TextStyle(
        color: palette.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w400,
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
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
      ),
      labelLarge: TextStyle(
        color: palette.primary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surfaceRaised,
      hintStyle: TextStyle(color: palette.textSecondary, fontSize: 14),
      labelStyle: TextStyle(color: palette.textSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: inputBorder.copyWith(
        borderSide: BorderSide(color: palette.primary, width: 1.2),
      ),
      errorBorder: inputBorder.copyWith(
        borderSide: BorderSide(color: palette.danger),
      ),
      focusedErrorBorder: inputBorder.copyWith(
        borderSide: BorderSide(color: palette.danger, width: 1.2),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: palette.textSecondary,
        backgroundColor: palette.surface,
        shape: const CircleBorder(),
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
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.primary,
        backgroundColor: palette.surface,
        side: BorderSide(color: palette.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpace.radiusLarge),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: palette.surfaceRaised,
      selectedColor: palette.primary.withValues(alpha: isDark ? 0.26 : 0.16),
      side: BorderSide(color: palette.border),
      labelStyle: TextStyle(color: palette.textSecondary),
      secondaryLabelStyle: TextStyle(color: palette.primary),
      checkmarkColor: palette.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpace.radiusLarge),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.surface,
      contentTextStyle: TextStyle(color: palette.textPrimary),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpace.radiusLarge),
        side: isDark ? BorderSide(color: palette.border) : BorderSide.none,
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: palette.textSecondary,
      textColor: palette.textPrimary,
      tileColor: Colors.transparent,
      contentPadding: EdgeInsets.zero,
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      headerForegroundColor: palette.textPrimary,
      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return palette.textPrimary;
      }),
      dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return palette.primary;
        }
        return Colors.transparent;
      }),
      todayForegroundColor: WidgetStatePropertyAll(palette.primary),
      dividerColor: palette.divider,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpace.radiusXLarge),
      ),
    ),
  );
}

final ThemeController _themeController = ThemeController();
final AuthController _authController = AuthController()
  ..addListener(() {
    final uid = _authController.user?.uid;
    if (uid != null) {
      WorkItemApi.init(uid: uid);
    } else {
      WorkItemApi.clear();
    }
  });

final GoRouter _rootRouter = GoRouter(
  refreshListenable: _authController,
  initialLocation: '/home',
  redirect: (context, state) {
    final isLoggedIn = _authController.isLoggedIn;
    final isAuthRoute = state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';
    final isBootstrapRoute = state.matchedLocation == '/bootstrap-error';

    if (isBootstrapRoute) return null;
    if (!isLoggedIn && !isAuthRoute) return '/login';
    if (isLoggedIn && isAuthRoute) return '/home';
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
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
    GoRoute(
      path: '/space-details/:spaceId',
      builder: (context, state) => SpaceDetailsView(
        spaceId: int.tryParse(state.pathParameters['spaceId'] ?? ''),
      ),
    ),
    GoRoute(
      path: '/create-work-item',
      builder: (context, state) => const CreateWorkItemPage(),
    ),
  ],
);

Widget getRootWidget({Object? bootstrapError}) {
  if (bootstrapError != null) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _buildAppTheme(AppColors.light, Brightness.light),
      darkTheme: _buildAppTheme(AppColors.dark, Brightness.dark),
      home: FirebaseBootstrapErrorPage(error: bootstrapError),
    );
  }

  return AuthScope(
    notifier: _authController,
    child: ThemeControllerScope(
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
    ),
  );
}
