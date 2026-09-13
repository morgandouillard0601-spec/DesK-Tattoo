import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../shared/utils/date_format.dart';
import '../../accounting/data/accounting_repository.dart';
import '../../accounting/domain/transaction.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../clients/data/clients_repository.dart';
import '../../planning/data/planning_repository.dart';
import '../../planning/domain/appointment.dart';
import '../data/artist_repository.dart';
import '../domain/artist.dart';
import 'widgets/app_store_qr_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final Artist artist = ref.watch(artistProvider);
    final ThemeMode themeMode = ref.watch(themeModeProvider);
    final AuthState auth = ref.watch(authProvider);

    final int clientsCount = ref.watch(clientsProvider).length;
    final List<Appointment> appointments = ref.watch(planningProvider);
    final Duration totalHours = appointments.fold<Duration>(
      Duration.zero,
      (Duration s, Appointment a) => s + a.duration,
    );
    final double totalIncome = ref
        .watch(accountingProvider)
        .where((Transaction t) => t.type == TransactionType.income)
        .fold<double>(0, (double s, Transaction t) => s + t.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Modifier',
            icon: const Icon(Icons.edit_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Édition — bientôt')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: <Widget>[
          _Header(artist: artist),
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              Expanded(
                child: _Stat(
                  label: 'Clients',
                  value: '$clientsCount',
                  icon: Icons.people_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Stat(
                  label: 'Heures',
                  value: '${totalHours.inHours}h',
                  icon: Icons.timer_rounded,
                  color: theme.colorScheme.tertiary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Stat(
                  label: 'CA',
                  value: AppDateFormat.currencyEur(totalIncome),
                  icon: Icons.euro_rounded,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Spécialités',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: artist.specialties
                .map((String s) => Chip(label: Text(s)))
                .toList(),
          ),
          if (artist.bio != null) ...<Widget>[
            const SizedBox(height: 24),
            Text(
              'À propos',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              color: theme.colorScheme.surfaceContainerHigh,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(artist.bio!),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'Coordonnées',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            color: theme.colorScheme.surfaceContainerHigh,
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.storefront_rounded),
                  title: const Text('Studio'),
                  subtitle: Text(artist.studioName),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.home_outlined),
                  title: const Text('Adresse'),
                  subtitle: Text(
                    () {
                      final String line = [
                        if (artist.address.isNotEmpty) artist.address,
                        if (artist.city.isNotEmpty) artist.city,
                      ].join(', ');
                      return line.isEmpty ? '—' : line;
                    }(),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('SIRET'),
                  subtitle: Text(artist.siret.isEmpty ? '—' : artist.siret),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.email_rounded),
                  title: const Text('Email'),
                  subtitle: Text(artist.email),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.phone_rounded),
                  title: const Text('Téléphone'),
                  subtitle: Text(artist.phone),
                ),
                if (artist.instagram != null) ...<Widget>[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.camera_alt_rounded),
                    title: const Text('Instagram'),
                    subtitle: Text(artist.instagram!),
                  ),
                ],
              ],
            ),
          ),
          if (auth.isAdmin) ...<Widget>[
            const SizedBox(height: 24),
            Text(
              'Administration',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              color: theme.colorScheme.surfaceContainerHigh,
              child: ListTile(
                leading: const Icon(Icons.folder_shared_rounded),
                title: const Text('Dossiers studios'),
                subtitle: const Text('Onboarding & abonnements'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(AppRoutes.adminStudios),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'Partager l\'app',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const AppStoreQrCard(),
          const SizedBox(height: 24),
          Text(
            'Préférences',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            color: theme.colorScheme.surfaceContainerHigh,
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: Icon(_iconForMode(themeMode)),
                  title: const Text('Thème'),
                  subtitle: Text(_labelForMode(themeMode)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () =>
                      ref.read(themeModeProvider.notifier).toggle(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_rounded),
                  title: const Text('Notifications'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bientôt disponible')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock_rounded),
                  title: const Text('Sécurité'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bientôt disponible')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }

  IconData _iconForMode(ThemeMode mode) => switch (mode) {
        ThemeMode.light => Icons.light_mode_rounded,
        ThemeMode.dark => Icons.dark_mode_rounded,
        ThemeMode.system => Icons.brightness_auto_rounded,
      };

  String _labelForMode(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'Clair',
        ThemeMode.dark => 'Sombre',
        ThemeMode.system => 'Automatique',
      };
}

class _Header extends StatelessWidget {
  const _Header({required this.artist});

  final Artist artist;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 36,
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              artist.initials,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  artist.fullName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  artist.studioName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${artist.experienceYears} ans d\'expérience',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
