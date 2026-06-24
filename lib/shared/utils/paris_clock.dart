import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Centralized clock that returns Paris (Europe/Paris) wall-clock time.
///
/// The returned [DateTime] objects are detached from any timezone (their
/// `isUtc` is false) but their `year/month/day/hour/...` fields match the
/// current civil time in Paris. This avoids any drift when the device is
/// configured in a different timezone.
class ParisClock {
  ParisClock._();

  static late tz.Location _paris;
  static bool _initialized = false;

  static const String _zoneName = 'Europe/Paris';

  static void init() {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    _paris = tz.getLocation(_zoneName);
    _initialized = true;
  }

  /// Current Paris time as a wall-clock [DateTime].
  static DateTime now() {
    _ensureInit();
    final tz.TZDateTime tNow = tz.TZDateTime.now(_paris);
    return DateTime(
      tNow.year,
      tNow.month,
      tNow.day,
      tNow.hour,
      tNow.minute,
      tNow.second,
      tNow.millisecond,
      tNow.microsecond,
    );
  }

  /// Today at 00:00 Paris time.
  static DateTime today() {
    final DateTime n = now();
    return DateTime(n.year, n.month, n.day);
  }

  /// Duration until the next Paris midnight (with a 1s safety margin).
  static Duration durationUntilNextMidnight() {
    final DateTime n = now();
    final DateTime nextMidnight =
        DateTime(n.year, n.month, n.day).add(const Duration(days: 1));
    return nextMidnight.difference(n) + const Duration(seconds: 1);
  }

  static void _ensureInit() {
    if (!_initialized) init();
  }
}

/// Stream that emits a [DateTime] every second, ticking on Paris wall-clock.
final StreamProvider<DateTime> parisTickerProvider =
    StreamProvider<DateTime>((Ref ref) async* {
  yield ParisClock.now();
  await for (final _ in Stream<int>.periodic(const Duration(seconds: 1))) {
    yield ParisClock.now();
  }
});

/// Provider that emits today (Paris) and refreshes at the next Paris midnight.
final StreamProvider<DateTime> parisTodayProvider =
    StreamProvider<DateTime>((Ref ref) async* {
  while (true) {
    yield ParisClock.today();
    await Future<void>.delayed(ParisClock.durationUntilNextMidnight());
  }
});
