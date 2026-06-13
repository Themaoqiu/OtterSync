import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ottersync/pages/Account/index.dart';
import 'package:ottersync/pages/AiChat/index.dart';
import 'package:ottersync/pages/Settings/index.dart';
import 'package:ottersync/pages/AllWork/index.dart';
import 'package:ottersync/pages/BootstrapError/index.dart';
import 'package:ottersync/pages/CreateWorkItem/index.dart';
import 'package:ottersync/pages/Dashboard/index.dart';
import 'package:ottersync/pages/Home/index.dart';
import 'package:ottersync/pages/Login/index.dart';
import 'package:ottersync/pages/Login/sign_in.dart';
import 'package:ottersync/pages/Main/index.dart';
import 'package:ottersync/pages/Notifications/index.dart';
import 'package:ottersync/pages/Register/index.dart';
import 'package:ottersync/pages/Search/index.dart';
import 'package:ottersync/pages/SpaceDetails/index.dart';
import 'package:ottersync/pages/Spaces/index.dart';
import 'package:ottersync/pages/WorkItemDetail/index.dart';
import 'package:ottersync/services/messaging_service.dart';
import 'package:ottersync/state/auth_controller.dart';
import 'package:ottersync/state/theme_controller.dart';
import 'package:ottersync/theme/app_theme.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/viewmodels/jira_models.dart';

final ThemeController _themeController = ThemeController();
final AuthController _authController = AuthController()
  ..addListener(() {
    final uid = _authController.user?.uid;
    if (uid != null) {
      MessagingService.instance.registerToken(uid);
    }
  });

final GoRouter _rootRouter = GoRouter(
  refreshListenable: _authController,
  initialLocation: '/home',
  redirect: (context, state) {
    final isLoggedIn = _authController.isLoggedIn;
    final isAuthRoute = state.matchedLocation == '/login' ||
        state.matchedLocation == '/sign-in' ||
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
      path: '/sign-in',
      builder: (context, state) => const SignInPage(),
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
    GoRoute(path: '/settings', builder: (context, state) => const SettingsView()),
    GoRoute(path: '/ai-chat', builder: (context, state) => const AiChatView()),
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
    GoRoute(
      path: '/work-item/:workItemId',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['workItemId'] ?? '');
        final extra = state.extra;
        return WorkItemDetailView(
          workItemId: id,
          heroSeed: extra is IssueSummary ? extra : null,
        );
      },
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) {
        final scope = state.uri.queryParameters['scope'] ?? 'workItems';
        return SearchView(scope: scope);
      },
    ),
  ],
);

Widget getRootWidget({Object? bootstrapError}) {
  if (bootstrapError != null) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(AppColors.light, Brightness.light),
      darkTheme: buildAppTheme(AppColors.dark, Brightness.dark),
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
            theme: buildAppTheme(AppColors.light, Brightness.light),
            darkTheme: buildAppTheme(AppColors.dark, Brightness.dark),
            themeMode: _themeController.themeMode,
            routerConfig: _rootRouter,
          );
        },
      ),
    ),
  );
}
