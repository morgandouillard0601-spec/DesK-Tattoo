// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'DesK Tattoo';

  @override
  String get welcome => 'Welcome';

  @override
  String get homeSubtitle => 'The foundation of your mobile app is ready.';

  @override
  String get toggleTheme => 'Toggle theme';

  @override
  String counter(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tapped $countString times',
      one: 'Tapped $countString time',
      zero: 'No taps yet',
    );
    return '$_temp0';
  }
}
