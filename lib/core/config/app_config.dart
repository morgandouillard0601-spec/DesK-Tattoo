import 'package:flutter_dotenv/flutter_dotenv.dart';

enum AppEnv { dev, staging, prod }

class AppConfig {
  const AppConfig({
    required this.appName,
    required this.env,
    required this.apiBaseUrl,
    required this.apiTimeout,
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
    );
  }

  final String appName;
  final AppEnv env;
  final String apiBaseUrl;
  final Duration apiTimeout;

  bool get isDev => env == AppEnv.dev;
  bool get isProd => env == AppEnv.prod;
}
