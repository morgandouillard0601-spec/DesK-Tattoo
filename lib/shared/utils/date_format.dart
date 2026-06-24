import 'package:intl/intl.dart';

import 'paris_clock.dart';

class AppDateFormat {
  const AppDateFormat._();

  static String dayLong(DateTime date, [String locale = 'fr_FR']) =>
      DateFormat('EEEE d MMMM', locale).format(date);

  static String dayShort(DateTime date, [String locale = 'fr_FR']) =>
      DateFormat('EEE d MMM', locale).format(date);

  static String hourMinute(DateTime date) => DateFormat.Hm().format(date);

  static String monthYear(DateTime date, [String locale = 'fr_FR']) =>
      DateFormat('MMMM yyyy', locale).format(date);

  static String relativeDay(
    DateTime date, [
    String locale = 'fr_FR',
  ]) {
    final DateTime today = ParisClock.today();
    final DateTime target = DateTime(date.year, date.month, date.day);
    final int diff = target.difference(today).inDays;
    if (diff == 0) return "Aujourd'hui";
    if (diff == 1) return 'Demain';
    if (diff == -1) return 'Hier';
    return dayLong(date, locale);
  }

  static String duration(Duration d) {
    final int hours = d.inHours;
    final int minutes = d.inMinutes.remainder(60);
    if (hours == 0) return '${minutes}min';
    if (minutes == 0) return '${hours}h';
    return '${hours}h${minutes.toString().padLeft(2, '0')}';
  }

  static String currencyEur(double value) =>
      NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(value);
}
