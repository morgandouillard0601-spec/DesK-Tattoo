import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/config/providers.dart';
import 'core/network/supabase_client.dart';
import 'core/storage/preferences_service.dart';
import 'shared/utils/paris_clock.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  await dotenv.load(fileName: '.env');
  await initializeDateFormatting('fr_FR');
  ParisClock.init();

  final AppConfig appConfig = AppConfig.fromEnv();
  await initSupabaseIfConfigured(appConfig);
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: <Override>[
        appConfigProvider.overrideWithValue(appConfig),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const DeskTattooApp(),
    ),
  );
}
