// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'DesK Tattoo';

  @override
  String get welcome => 'Bienvenue';

  @override
  String get homeSubtitle => 'La base de votre application mobile est prête.';

  @override
  String get toggleTheme => 'Changer de thème';

  @override
  String counter(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Appuyé $countString fois',
      one: 'Appuyé $countString fois',
      zero: 'Aucun appui pour le moment',
    );
    return '$_temp0';
  }
}
