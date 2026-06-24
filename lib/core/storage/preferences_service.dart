import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  PreferencesService(this._prefs);

  final SharedPreferences _prefs;

  static const String _themeModeKey = 'theme_mode';
  static const String _localeKey = 'locale';

  String? getThemeMode() => _prefs.getString(_themeModeKey);

  Future<bool> setThemeMode(String mode) =>
      _prefs.setString(_themeModeKey, mode);

  String? getLocale() => _prefs.getString(_localeKey);

  Future<bool> setLocale(String locale) =>
      _prefs.setString(_localeKey, locale);
}

final Provider<SharedPreferences> sharedPreferencesProvider =
    Provider<SharedPreferences>(
  (Ref ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in ProviderScope',
  ),
);

final Provider<PreferencesService> preferencesServiceProvider =
    Provider<PreferencesService>(
  (Ref ref) => PreferencesService(ref.watch(sharedPreferencesProvider)),
);
