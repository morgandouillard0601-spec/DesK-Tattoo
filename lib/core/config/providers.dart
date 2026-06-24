import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_config.dart';

final Provider<AppConfig> appConfigProvider = Provider<AppConfig>(
  (Ref ref) => throw UnimplementedError(
    'appConfigProvider must be overridden in ProviderScope',
  ),
);
