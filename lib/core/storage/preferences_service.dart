import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/profile/domain/artist.dart';

class PreferencesService {
  PreferencesService(this._prefs);

  final SharedPreferences _prefs;

  static const String _themeModeKey = 'theme_mode';
  static const String _localeKey = 'locale';
  static const String _artistProfilePrefix = 'artist_profile_';

  String? getThemeMode() => _prefs.getString(_themeModeKey);

  Future<bool> setThemeMode(String mode) =>
      _prefs.setString(_themeModeKey, mode);

  String? getLocale() => _prefs.getString(_localeKey);

  Future<bool> setLocale(String locale) =>
      _prefs.setString(_localeKey, locale);

  String _artistKey(String email) =>
      '$_artistProfilePrefix${email.trim().toLowerCase()}';

  Artist? readArtistProfile(String email) {
    final String? raw = _prefs.getString(_artistKey(email));
    if (raw == null || raw.isEmpty) return null;
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return Artist.fromJson(decoded);
      }
      if (decoded is Map) {
        return Artist.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<bool> writeArtistProfile(Artist artist) {
    return _prefs.setString(
      _artistKey(artist.email),
      jsonEncode(artist.toJson()),
    );
  }

  bool get legacyMorganProfileRestored =>
      _prefs.getBool('legacy_profile_restored_morgandesk_v1') ?? false;

  Future<bool> markLegacyMorganProfileRestored() =>
      _prefs.setBool('legacy_profile_restored_morgandesk_v1', true);
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
