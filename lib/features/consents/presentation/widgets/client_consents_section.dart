import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../../shared/utils/date_format.dart';
import '../../../intake/domain/consent_text.dart';
import '../../data/consents_repository.dart';
import '../../domain/client_consent.dart';

/// Section « Contrats et consentements » de la fiche client.
/// Autonome : elle charge elle-même les contrats du client.
class ClientConsentsSection extends ConsumerWidget {
  const ClientConsentsSection({required this.clientId, super.key});

  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);

    if (!ref.watch(consentsRepositoryProvider).isAvailable) {
      return const SizedBox.shrink();
    }

    final AsyncValue<List<ClientConsent>> consents =
        ref.watch(clientConsentsProvider(clientId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Contrats et consentements',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Actualiser',
              icon: const Icon(Icons.refresh_rounded, size: 20),
              onPressed: () => ref.invalidate(clientConsentsProvider(clientId)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        consents.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (Object e, _) => Card(
            color: theme.colorScheme.surfaceContainerHigh,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                'Contrats indisponibles pour le moment.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          data: (List<ClientConsent> list) {
            if (list.isEmpty) {
              return Card(
                color: theme.colorScheme.surfaceContainerHigh,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.qr_code_2_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Aucun contrat signé. Fais scanner ton QR fiche '
                          'client depuis l\'onglet Profil.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Column(
              children: <Widget>[
                for (int i = 0; i < list.length; i++)
                  _ConsentTile(
                    consent: list[i],
                    isLatest: i == 0,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ConsentTile extends ConsumerStatefulWidget {
  const _ConsentTile({
    required this.consent,
    this.isLatest = false,
  });

  final ClientConsent consent;
  final bool isLatest;

  @override
  ConsumerState<_ConsentTile> createState() => _ConsentTileState();
}

class _ConsentTileState extends ConsumerState<_ConsentTile> {
  bool _busy = false;

  Future<Uint8List?> _loadPdf() async {
    final String? path = widget.consent.pdfPath;
    if (path == null) return null;
    return ref.read(consentsRepositoryProvider).downloadPdf(path);
  }

  Future<void> _preview() async {
    setState(() => _busy = true);
    try {
      final Uint8List? bytes = await _loadPdf();
      if (bytes == null || !mounted) return;
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'contrat-${widget.consent.fullName}.pdf',
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contrat illisible')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final Uint8List? bytes = await _loadPdf();
      if (bytes == null || !mounted) return;
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'contrat-${widget.consent.fullName}.pdf',
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Partage impossible')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _healthLabel(String key) {
    for (final HealthQuestion q in ConsentText.healthQuestions) {
      if (q.key == key) return q.label;
    }
    return key;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ClientConsent consent = widget.consent;
    final Map<String, String> health = consent.filledHealthAnswers;

    return Card(
      color: theme.colorScheme.surfaceContainerHigh,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          leading: Icon(
            Icons.assignment_turned_in_rounded,
            color: theme.colorScheme.primary,
          ),
          title: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Consentement signé',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (widget.isLatest)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Plus récente',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Text(
            '${AppDateFormat.dayLong(consent.signedAt)} · '
            '${AppDateFormat.hourMinute(consent.signedAt)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          children: <Widget>[
            _Line(label: 'Nom signé', value: consent.fullName),
            if (consent.birthDate != null)
              _Line(
                label: 'Naissance',
                value: AppDateFormat.dayLong(consent.birthDate!),
              ),
            if (consent.phone.isNotEmpty)
              _Line(label: 'Téléphone', value: consent.phone),
            if (consent.email.isNotEmpty)
              _Line(label: 'Email', value: consent.email),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                _Flag(ok: consent.acceptedTerms, label: 'Contrat'),
                _Flag(ok: consent.acceptedHealth, label: 'Santé'),
                _Flag(ok: consent.acceptedAftercare, label: 'Soins'),
                _Flag(
                  ok: consent.acceptedImageRights,
                  label: 'Droit à l\'image',
                ),
              ],
            ),
            if (health.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                'Déclaration de santé',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              for (final MapEntry<String, String> e in health.entries)
                _Line(label: _healthLabel(e.key), value: e.value),
            ],
            const SizedBox(height: 10),
            if (consent.hasPdf)
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _preview,
                      icon: const Icon(Icons.visibility_rounded, size: 18),
                      label: const Text('Voir'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _share,
                      icon: const Icon(Icons.ios_share_rounded, size: 18),
                      label: const Text('Partager'),
                    ),
                  ),
                ],
              )
            else
              Text(
                'Le PDF n\'a pas pu être archivé, mais la signature et les '
                'réponses du client sont conservées.',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
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
          Expanded(
            child: Text(value, style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _Flag extends StatelessWidget {
  const _Flag({required this.ok, required this.label});

  final bool ok;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color =
        ok ? theme.colorScheme.primary : theme.colorScheme.outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            ok ? Icons.check_rounded : Icons.remove_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
