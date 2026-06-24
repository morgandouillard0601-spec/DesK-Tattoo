import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../shared/utils/paris_clock.dart';

class WeekStrip extends StatelessWidget {
  const WeekStrip({
    required this.selectedDay,
    required this.onDaySelected,
    super.key,
  });

  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final DateTime today = ParisClock.today();
    final List<DateTime> days = List<DateTime>.generate(
      14,
      (int i) => today.add(Duration(days: i - 1)),
    );

    final DateFormat weekdayFmt = DateFormat('E', 'fr_FR');

    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final DateTime day = days[index];
          final bool isSelected = _isSameDay(day, selectedDay);
          final bool isToday = _isSameDay(day, today);

          final ThemeData theme = Theme.of(context);
          final Color bg = isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHigh;
          final Color fg = isSelected
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurface;

          return InkWell(
            onTap: () => onDaySelected(day),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 60,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(16),
                border: isToday && !isSelected
                    ? Border.all(color: theme.colorScheme.primary, width: 1.5)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    weekdayFmt.format(day).toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: fg.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.day}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
