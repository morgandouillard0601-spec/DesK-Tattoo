import 'package:flutter_dotenv/flutter_dotenv.dart';

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
    final String envName = dotenv.maybeGet('APP_ENV') ?? 'dev';
    final AppEnv env = AppEnv.values.firstWhere(
      (AppEnv e) => e.name == envName,
      orElse: () => AppEnv.dev,
    );

    final int timeoutMs = int.tryParse(
          dotenv.maybeGet('API_TIMEOUT_MS') ?? '',
        ) ??
        15000;

    return AppConfig(
      appName: dotenv.maybeGet('APP_NAME') ?? 'DesK Tattoo',
      env: env,
      apiBaseUrl:
          dotenv.maybeGet('API_BASE_URL') ?? 'https://api.example.com',
      apiTimeout: Duration(milliseconds: timeoutMs),
      appStoreUrl: dotenv.maybeGet('APP_STORE_URL') ??
          'https://apps.apple.com/app/idXXXXXXXXX',
      playStoreUrl: dotenv.maybeGet('PLAY_STORE_URL') ??
          'https://play.google.com/store/apps/details?id=com.desktattoo.desk_tattoo',
      appDownloadUrl: dotenv.maybeGet('APP_DOWNLOAD_URL') ??
          'https://desktattoo.app/get/dt-get-7f3a9c2e',
      supabaseUrl: dotenv.maybeGet('SUPABASE_URL') ?? '',
      supabaseAnonKey: dotenv.maybeGet('SUPABASE_ANON_KEY') ?? '',
      stripePublishableKey: dotenv.maybeGet('STRIPE_PUBLISHABLE_KEY') ?? '',
      stripeProductId:
          dotenv.maybeGet('STRIPE_PRODUCT_ID') ?? 'prod_VFctn7oeEEtvpK',
      monthlyPriceLabel: dotenv.maybeGet('STRIPE_PRICE_LABEL') ?? '19,99 €',
      webAppUrl: _resolveWebAppUrl(dotenv.maybeGet('WEB_APP_URL')),
    );
  }

  /// Base publique de la webapp, utilisée pour construire le lien encodé dans
  /// le QR d'accueil client. Sur le web on préfère l'origine réelle de la page
  /// (preview Vercel, domaine custom) à une valeur figée dans `.env`.
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

  /// Origine de la webapp (sans slash final), ex. `https://desktattoo.vercel.app`.
  final String webAppUrl;

  /// Lien public du formulaire d'accueil client pour un token donné.
  String intakeUrl(String token) => '$webAppUrl/intake/$token';

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
