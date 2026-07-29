import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/date_format.dart';
import '../../../shared/utils/paris_clock.dart';
import '../../../shared/widgets/empty_state.dart';
import '../data/planning_repository.dart';
import '../domain/appointment.dart';
import 'appointment_form_sheet.dart';
import 'widgets/appointment_card.dart';
import 'widgets/week_strip.dart';

class PlanningScreen extends ConsumerStatefulWidget {
  const PlanningScreen({super.key});

  @override
  ConsumerState<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends ConsumerState<PlanningScreen> {
  late DateTime _selectedDay;
  bool _stickToToday = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = ParisClock.today();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    ref.watch(planningProvider);

    final DateTime parisToday =
        ref.watch(parisTodayProvider).valueOrNull ?? ParisClock.today();
    if (_stickToToday && _selectedDay != parisToday) {
      _selectedDay = parisToday;
    }

    final List<Appointment> appointments =
        ref.read(planningProvider.notifier).forDay(_selectedDay);

    final double totalRevenue = appointments
        .where((Appointment a) => a.status != AppointmentStatus.cancelled)
        .fold<double>(0, (double sum, Appointment a) => sum + a.price);
    final Duration totalDuration = appointments.fold<Duration>(
      Duration.zero,
      (Duration sum, Appointment a) => sum + a.duration,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planning'),
        actions: <Widget>[
          const _ParisClockBadge(),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Aujourd\'hui',
            icon: const Icon(Icons.today_rounded),
            onPressed: _goToToday,
          ),
          IconButton(
            tooltip: 'Choisir une date',
            icon: const Icon(Icons.calendar_today_rounded),
            onPressed: _pickDate,
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          AppDateFormat.relativeDay(_selectedDay),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppDateFormat.dayLong(_selectedDay),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: WeekStrip(
              selectedDay: _selectedDay,
              onDaySelected: (DateTime d) => setState(() {
                _selectedDay = d;
                _stickToToday = d == ParisClock.today();
              }),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _StatChip(
                      icon: Icons.event_available_rounded,
                      label: '${appointments.length} RDV',
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatChip(
                      icon: Icons.schedule_rounded,
                      label: AppDateFormat.duration(totalDuration),
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatChip(
                      icon: Icons.euro_rounded,
                      label: AppDateFormat.currencyEur(totalRevenue),
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (appointments.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.event_busy_rounded,
                title: 'Aucun rendez-vous',
                message: 'Profite-en pour préparer tes prochaines pièces.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList.separated(
                itemCount: appointments.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (BuildContext context, int index) {
                  return AppointmentCard(
                    appointment: appointments[index],
                    onTap: () => _editAppointment(appointments[index]),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createAppointment,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouveau RDV'),
      ),
    );
  }

  void _goToToday() {
    setState(() {
      _selectedDay = ParisClock.today();
      _stickToToday = true;
    });
  }

  Future<void> _pickDate() async {
    final DateTime now = ParisClock.today();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() {
        _selectedDay = picked;
        _stickToToday = picked == ParisClock.today();
      });
    }
  }

  Future<void> _createAppointment() async {
    final Appointment? created = await showAppointmentFormSheet(
      context,
      initialDay: _selectedDay,
    );
    if (!mounted) return;
    if (created != null) {
      final DateTime newDay = DateTime(
        created.start.year,
        created.start.month,
        created.start.day,
      );
      setState(() {
        _selectedDay = newDay;
        _stickToToday = newDay == ParisClock.today();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('RDV créé · ${created.clientName}')),
      );
    }
  }

  Future<void> _editAppointment(Appointment a) async {
    final Appointment? saved = await showAppointmentFormSheet(
      context,
      initial: a,
    );
    if (!mounted) return;
    if (saved != null) {
      // Follow the RDV if its date changed.
      final DateTime newDay = DateTime(
        saved.start.year,
        saved.start.month,
        saved.start.day,
      );
      setState(() {
        _selectedDay = newDay;
        _stickToToday = newDay == ParisClock.today();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('RDV mis à jour · ${saved.clientName}')),
      );
    }
  }
}

class _ParisClockBadge extends ConsumerWidget {
  const _ParisClockBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final DateTime now =
        ref.watch(parisTickerProvider).valueOrNull ?? ParisClock.now();
    final String hhmm = AppDateFormat.hourMinute(now);

    return Tooltip(
      message: 'Heure de Paris',
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.public_rounded,
              size: 14,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 4),
            Text(
              hhmm,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
                fontFeatures: const <FontFeature>[
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

