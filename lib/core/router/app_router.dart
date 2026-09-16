import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/accounting/presentation/accounting_screen.dart';
import '../../features/admin/presentation/admin_studios_screen.dart';
import '../../features/admin/presentation/studio_dossier_screen.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/billing/presentation/paywall_screen.dart';
import '../../features/clients/presentation/client_detail_screen.dart';
import '../../features/clients/presentation/clients_screen.dart';
import '../../features/intake/presentation/intake_form_screen.dart';
import '../../features/planning/presentation/planning_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/stock/presentation/stock_screen.dart';
import '../../shared/widgets/app_shell.dart';

class AppRoutes {
  const AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String paywall = '/paywall';
  static const String planning = '/planning';
  static const String stock = '/stock';
  static const String clients = '/clients';
  static const String accounting = '/accounting';
  static const String profile = '/profile';
  static const String adminStudios = '/admin/studios';
  static const String adminStudioDetail = '/admin/studios/:id';

  /// Formulaire d'accueil client ouvert par le QR du tatoueur. Route publique.
  static const String intake = '/intake/:token';

  /// Préfixes accessibles sans compte ni abonnement.
  static const List<String> publicPrefixes = <String>['/intake'];
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
      final String loc = state.matchedLocation;

      // Les pages publiques passent avant tout test de session : le client qui
      // scanne le QR n'a pas de compte, et l'auto-connexion legacy ne doit pas
      // le renvoyer vers le dashboard.
      for (final String prefix in AppRoutes.publicPrefixes) {
        if (loc.startsWith(prefix)) return null;
      }

      final AuthState auth = ref.read(authProvider);
      final bool onSplash = loc == AppRoutes.splash;
      final bool onLogin = loc == AppRoutes.login;
      final bool onPaywall = loc == AppRoutes.paywall;
      final bool onAdmin = loc.startsWith('/admin');

      if (auth.status == AuthStatus.unknown) {
        return onSplash ? null : AppRoutes.splash;
      }

      if (!auth.isAuthenticated) {
        return onLogin ? null : AppRoutes.login;
      }

      // Authenticated but not subscribed → paywall (legacy/admin exempt).
      if (!auth.entitled) {
        return onPaywall ? null : AppRoutes.paywall;
      }

      if (onLogin || onSplash || onPaywall) {
        return AppRoutes.planning;
      }

      if (onAdmin && !auth.isAdmin) {
        return AppRoutes.profile;
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
      GoRoute(
        path: AppRoutes.intake,
        name: 'intake',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) => IntakeFormScreen(
          token: state.pathParameters['token'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.paywall,
        name: 'paywall',
        builder: (_, _) => const PaywallScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminStudios,
        name: 'admin-studios',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const AdminStudiosScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: ':id',
            name: 'admin-studio-detail',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (BuildContext context, GoRouterState state) =>
                StudioDossierScreen(studioId: state.pathParameters['id']!),
          ),
        ],
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
