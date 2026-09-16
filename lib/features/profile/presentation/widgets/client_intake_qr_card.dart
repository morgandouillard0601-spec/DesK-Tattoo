import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/config/providers.dart';
import '../../data/artist_repository.dart';
import '../../domain/artist.dart';

/// QR code personnel du tatoueur. Le client le scanne en boutique pour
/// remplir sa fiche et signer le contrat de consentement.
class ClientIntakeQrCard extends ConsumerStatefulWidget {
  const ClientIntakeQrCard({super.key});

  @override
  ConsumerState<ClientIntakeQrCard> createState() =>
      _ClientIntakeQrCardState();
}

class _ClientIntakeQrCardState extends ConsumerState<ClientIntakeQrCard> {
  bool _busy = false;

  Future<void> _copy(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lien d\'accueil copié')),
    );
  }

  Future<void> _rotate() async {
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Régénérer le QR ?'),
            content: const Text(
              'Les QR déjà imprimés ou affichés en boutique cesseront de '
              'fonctionner. Il faudra les remplacer.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Régénérer'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    setState(() => _busy = true);
    try {
      await ref.read(artistProvider.notifier).rotateIntakeToken();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nouveau QR généré')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Régénération impossible pour le moment')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Artist artist = ref.watch(artistProvider);
    final AppConfig config = ref.watch(appConfigProvider);

    return Card(
      color: theme.colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.how_to_reg_rounded,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'QR fiche client',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              artist.hasIntakeToken
                  ? 'Le client scanne ce QR, remplit sa fiche et signe le '
                      'contrat. Tout arrive dans sa fiche client.'
                  : 'Ton lien d\'accueil n\'est pas encore disponible. '
                      'Reconnecte-toi une fois la base à jour.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (artist.hasIntakeToken) ...<Widget>[
              const SizedBox(height: 16),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: config.intakeUrl(artist.publicIntakeToken!),
                    version: QrVersions.auto,
                    size: 180,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF1A1224),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF1A1224),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(
                config.intakeUrl(artist.publicIntakeToken!),
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () => _copy(config.intakeUrl(artist.publicIntakeToken!)),
                icon: const Icon(Icons.link_rounded),
                label: const Text('Copier le lien d\'accueil'),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _busy ? null : _rotate,
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.autorenew_rounded, size: 18),
                label: const Text('Régénérer le QR'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
