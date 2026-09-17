import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/config/app_config.dart';
import 'core/config/providers.dart';
import 'core/network/supabase_client.dart';
import 'shared/utils/paris_clock.dart';
import 'web_intake_app.dart';

/// Point d'entrée Netlify : formulaire QR uniquement, pas le dashboard.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Netlify : .env est gitignoré, donc absent du bundle. Les clés
    // passent par --dart-define (voir scripts/web_build.sh).
  }
  await initializeDateFormatting('fr_FR');
  ParisClock.init();

  final AppConfig appConfig = AppConfig.fromEnv();
  await initSupabaseIfConfigured(appConfig);

  runApp(
    ProviderScope(
      overrides: <Override>[
        appConfigProvider.overrideWithValue(appConfig),
      ],
      child: const WebIntakeApp(),
    ),
  );
}
