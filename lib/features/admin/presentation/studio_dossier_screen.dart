import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/date_format.dart';
import '../../profile/data/artist_repository.dart';
import '../../profile/domain/artist.dart';

class StudioDossierScreen extends ConsumerStatefulWidget {
  const StudioDossierScreen({required this.studioId, super.key});

  final String studioId;

  @override
  ConsumerState<StudioDossierScreen> createState() =>
      _StudioDossierScreenState();
}

class _StudioDossierScreenState extends ConsumerState<StudioDossierScreen> {
  Artist? _artist;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final List<Artist> all =
        await ref.read(artistProvider.notifier).listAllStudiosForAdmin();
    Artist? found;
    for (final Artist a in all) {
      if (a.id == widget.studioId) {
        found = a;
        break;
      }
    }
    if (mounted) {
      setState(() {
        _artist = found;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dossier studio'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _artist == null
              ? const Center(child: Text('Dossier introuvable'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: <Widget>[
                    Text(
                      _artist!.studioName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _artist!.fullName,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    _Section(
                      title: 'Abonnement',
                      children: <Widget>[
                        _RowKV('Statut', _artist!.subscriptionStatus.labelFr),
                        _RowKV('Rôle', _artist!.role.wire),
                        if (_artist!.subscriptionCurrentPeriodEnd != null)
                          _RowKV(
                            'Fin de période',
                            AppDateFormat.dayLong(
                              _artist!.subscriptionCurrentPeriodEnd!,
                            ),
                          ),
                        if (_artist!.stripeCustomerId != null)
                          _RowKV('Stripe customer', _artist!.stripeCustomerId!),
                        if (_artist!.stripeSubscriptionId != null)
                          _RowKV(
                            'Stripe subscription',
                            _artist!.stripeSubscriptionId!,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _Section(
                      title: 'Salon',
                      children: <Widget>[
                        _RowKV('Adresse', _artist!.address),
                        _RowKV('Ville', _artist!.city),
                        _RowKV('SIRET', _artist!.siret),
                        _RowKV('Téléphone', _artist!.phone),
                        _RowKV('Email', _artist!.email),
                        if (_artist!.instagram != null)
                          _RowKV('Instagram', _artist!.instagram!),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _Section(
                      title: 'Profil artiste',
                      children: <Widget>[
                        _RowKV(
                          'Expérience',
                          '${_artist!.experienceYears} ans',
                        ),
                        _RowKV(
                          'Spécialités',
                          _artist!.specialties.join(', '),
                        ),
                        if (_artist!.bio != null) _RowKV('Bio', _artist!.bio!),
                      ],
                    ),
                  ],
                ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _RowKV extends StatelessWidget {
  const _RowKV(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value.isEmpty ? '—' : value)),
        ],
      ),
    );
  }
}
