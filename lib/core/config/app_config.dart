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
      // Unique public link encoded in the QR code.
      appDownloadUrl: dotenv.maybeGet('APP_DOWNLOAD_URL') ??
          'https://desktattoo.app/get/dt-get-7f3a9c2e',
    );
  }

  final String appName;
  final AppEnv env;
  final String apiBaseUrl;
  final Duration apiTimeout;
  final String appStoreUrl;
  final String playStoreUrl;

  /// Unique smart-link URL (QR target). Detects iOS/Android and redirects
  /// to [appStoreUrl] / [playStoreUrl] once those stores are live.
  final String appDownloadUrl;

  bool get isDev => env == AppEnv.dev;
  bool get isProd => env == AppEnv.prod;

  bool get storesConfigured =>
      !appStoreUrl.contains('XXXXXXXXX') &&
      !playStoreUrl.contains('idXXXXXXXX');
}
