import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/intake/web_intake_router.dart';
import 'l10n/generated/app_localizations.dart';

/// Mini-app web : formulaire d'accueil client uniquement.
class WebIntakeApp extends StatefulWidget {
  const WebIntakeApp({super.key});

  @override
  State<WebIntakeApp> createState() => _WebIntakeAppState();
}

class _WebIntakeAppState extends State<WebIntakeApp> {
  late final GoRouter _router = createWebIntakeRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'DesK Tattoo — Accueil client',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: _router,
      locale: const Locale('fr'),
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
