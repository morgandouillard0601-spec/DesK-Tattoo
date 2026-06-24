import 'package:flutter_test/flutter_test.dart';

import 'package:desk_tattoo/core/config/app_config.dart';

void main() {
  test('AppConfig defaults to dev environment', () {
    const AppConfig config = AppConfig(
      appName: 'DesK Tattoo',
      env: AppEnv.dev,
      apiBaseUrl: 'https://api.example.com',
      apiTimeout: Duration(seconds: 15),
    );

    expect(config.isDev, isTrue);
    expect(config.isProd, isFalse);
    expect(config.appName, 'DesK Tattoo');
  });
}
