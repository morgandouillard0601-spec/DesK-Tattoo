import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/accounting/presentation/accounting_screen.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/clients/presentation/client_detail_screen.dart';
import '../../features/clients/presentation/clients_screen.dart';
import '../../features/planning/presentation/planning_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/stock/presentation/stock_screen.dart';
import '../../shared/widgets/app_shell.dart';

class AppRoutes {
  const AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String planning = '/planning';
  static const String stock = '/stock';
  static const String clients = '/clients';
  static const String accounting = '/accounting';
  static const String profile = '/profile';
}

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((Ref ref) {
  final AuthRouterRefresh refresh = ref.watch(authRouterRefreshProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    refreshListenable: refresh,
    redirect: (BuildContext context, GoRouterState state) {
      final AuthState auth = ref.read(authProvider);
      final String loc = state.matchedLocation;
      final bool onSplash = loc == AppRoutes.splash;
      final bool onLogin = loc == AppRoutes.login;

      if (auth.status == AuthStatus.unknown) {
        return onSplash ? null : AppRoutes.splash;
      }

      if (!auth.isAuthenticated) {
        return onLogin ? null : AppRoutes.login;
      }

      if (onLogin || onSplash) {
        return AppRoutes.planning;
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (_, _) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (
          BuildContext context,
          GoRouterState state,
          StatefulNavigationShell navigationShell,
        ) =>
            AppShell(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.planning,
                name: 'planning',
                builder: (_, _) => const PlanningScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.stock,
                name: 'stock',
                builder: (_, _) => const StockScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.clients,
                name: 'clients',
                builder: (_, _) => const ClientsScreen(),
                routes: <RouteBase>[
                  GoRoute(
                    path: ':id',
                    name: 'client-detail',
                    builder: (BuildContext context, GoRouterState state) =>
                        ClientDetailScreen(
                      clientId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.accounting,
                name: 'accounting',
                builder: (_, _) => const AccountingScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.profile,
                name: 'profile',
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
