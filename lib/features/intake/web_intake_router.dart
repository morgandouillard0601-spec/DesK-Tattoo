import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'presentation/intake_form_screen.dart';
import 'presentation/intake_landing_screen.dart';

/// Router public : uniquement le formulaire QR, pas le dashboard studio.
GoRouter createWebIntakeRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        name: 'intake-landing',
        builder: (_, _) => const IntakeLandingScreen(),
      ),
      GoRoute(
        path: '/intake/:token',
        name: 'intake',
        builder: (BuildContext context, GoRouterState state) =>
            IntakeFormScreen(
          token: state.pathParameters['token'] ?? '',
        ),
      ),
    ],
    errorBuilder: (_, _) => const IntakeLandingScreen(),
  );
}
