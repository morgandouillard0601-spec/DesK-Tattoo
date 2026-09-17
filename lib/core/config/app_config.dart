import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../features/intake/domain/intake_qr_link.dart';

enum AppEnv { dev, staging, prod }

class AppConfig {
  const AppConfig({
    required this.appName,
    required this.env,
    required this.apiBaseUrl,
    required this.apiTimeout,
    required this.appStoreUrl,
    required this.playStoreUrl,
    required this.appDownloadUrl,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.stripePublishableKey,
    required this.stripeProductId,
    required this.monthlyPriceLabel,
    required this.webAppUrl,
  });

  factory AppConfig.fromEnv() {
    String read(String key, String fromDefine) {
      String fromFile = '';
      try {
        fromFile = (dotenv.maybeGet(key) ?? '').trim();
      } catch (_) {}
      if (fromFile.isNotEmpty) return fromFile;
      return fromDefine.trim();
    }

    final String envName = read('APP_ENV', const String.fromEnvironment('APP_ENV'));
    final AppEnv env = AppEnv.values.firstWhere(
      (AppEnv e) => e.name == (envName.isEmpty ? 'dev' : envName),
      orElse: () => AppEnv.dev,
    );

    final int timeoutMs = int.tryParse(
          read('API_TIMEOUT_MS', const String.fromEnvironment('API_TIMEOUT_MS')),
        ) ??
        15000;

    return AppConfig(
      appName: read('APP_NAME', const String.fromEnvironment('APP_NAME')).isEmpty
          ? 'DesK Tattoo'
          : read('APP_NAME', const String.fromEnvironment('APP_NAME')),
      env: env,
      apiBaseUrl: read(
                'API_BASE_URL',
                const String.fromEnvironment('API_BASE_URL'),
              ).isEmpty
          ? 'https://api.example.com'
          : read('API_BASE_URL', const String.fromEnvironment('API_BASE_URL')),
      apiTimeout: Duration(milliseconds: timeoutMs),
      appStoreUrl: read(
                'APP_STORE_URL',
                const String.fromEnvironment('APP_STORE_URL'),
              ).isEmpty
          ? 'https://apps.apple.com/app/idXXXXXXXXX'
          : read('APP_STORE_URL', const String.fromEnvironment('APP_STORE_URL')),
      playStoreUrl: read(
                'PLAY_STORE_URL',
                const String.fromEnvironment('PLAY_STORE_URL'),
              ).isEmpty
          ? 'https://play.google.com/store/apps/details?id=com.desktattoo.desk_tattoo'
          : read(
              'PLAY_STORE_URL',
              const String.fromEnvironment('PLAY_STORE_URL'),
            ),
      appDownloadUrl: read(
                'APP_DOWNLOAD_URL',
                const String.fromEnvironment('APP_DOWNLOAD_URL'),
              ).isEmpty
          ? 'https://desktattoo.app/get/dt-get-7f3a9c2e'
          : read(
              'APP_DOWNLOAD_URL',
              const String.fromEnvironment('APP_DOWNLOAD_URL'),
            ),
      supabaseUrl: read(
        'SUPABASE_URL',
        const String.fromEnvironment('SUPABASE_URL'),
      ),
      supabaseAnonKey: read(
        'SUPABASE_ANON_KEY',
        const String.fromEnvironment('SUPABASE_ANON_KEY'),
      ),
      stripePublishableKey: read(
        'STRIPE_PUBLISHABLE_KEY',
        const String.fromEnvironment('STRIPE_PUBLISHABLE_KEY'),
      ),
      stripeProductId: read(
                'STRIPE_PRODUCT_ID',
                const String.fromEnvironment('STRIPE_PRODUCT_ID'),
              ).isEmpty
          ? 'prod_VFctn7oeEEtvpK'
          : read(
              'STRIPE_PRODUCT_ID',
              const String.fromEnvironment('STRIPE_PRODUCT_ID'),
            ),
      monthlyPriceLabel: read(
                'STRIPE_PRICE_LABEL',
                const String.fromEnvironment('STRIPE_PRICE_LABEL'),
              ).isEmpty
          ? '19,99 €'
          : read(
              'STRIPE_PRICE_LABEL',
              const String.fromEnvironment('STRIPE_PRICE_LABEL'),
            ),
      webAppUrl: _resolveWebAppUrl(
        read('WEB_APP_URL', const String.fromEnvironment('WEB_APP_URL')),
      ),
    );
  }

  /// Base publique de la webapp, utilisée pour construire le lien encodé dans
  /// le QR d'accueil client. Sur le web on préfère l'origine réelle de la page
  /// (deploy preview, domaine custom) à une valeur figée dans `.env`.
  static String _resolveWebAppUrl(String? configured) {
    final Uri current = Uri.base;
    if (current.scheme == 'http' || current.scheme == 'https') {
      return current.origin;
    }
    final String value = (configured ?? '').trim();
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value.replaceAll(RegExp(r'/+$'), '');
    }
    return 'https://desktattoo.app';
  }

  final String appName;
  final AppEnv env;
  final String apiBaseUrl;
  final Duration apiTimeout;
  final String appStoreUrl;
  final String playStoreUrl;
  final String appDownloadUrl;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String stripePublishableKey;
  final String stripeProductId;
  final String monthlyPriceLabel;

  /// Origine de la webapp (sans slash final), ex. `https://desktattoo.netlify.app`.
  final String webAppUrl;

  /// Lien public du formulaire d'accueil client pour un token donné.
  /// Toujours `{WEB_APP_URL}/intake/{token}` — même chemin que le site Netlify.
  String intakeUrl(String token) => IntakeQrLink.build(
        webAppUrl: webAppUrl,
        token: token,
      );

  bool get isDev => env == AppEnv.dev;
  bool get isProd => env == AppEnv.prod;

  bool get storesConfigured =>
      !appStoreUrl.contains('XXXXXXXXX') &&
      !playStoreUrl.contains('idXXXXXXXX');

  bool get supabaseConfigured {
    if (!supabaseUrl.startsWith('https://')) return false;
    if (supabaseUrl.contains('xxxx.supabase.co')) return false;
    if (supabaseAnonKey.isEmpty) return false;
    if (supabaseAnonKey == 'eyJ...' ||
        supabaseAnonKey.startsWith('sb_publishable_...')) {
      return false;
    }
    return true;
  }
}
