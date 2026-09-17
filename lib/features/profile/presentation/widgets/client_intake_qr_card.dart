import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/config/providers.dart';
import '../../../intake/domain/intake_qr_link.dart';
import '../../data/artist_repository.dart';
import '../../domain/artist.dart';

/// QR unique du compte, encodant uniquement `/intake/{token}` de ce studio.
class ClientIntakeQrCard extends ConsumerStatefulWidget {
  const ClientIntakeQrCard({super.key});

  @override
  ConsumerState<ClientIntakeQrCard> createState() =>
      _ClientIntakeQrCardState();
}

class _ClientIntakeQrCardState extends ConsumerState<ClientIntakeQrCard> {
  static const Color _violet = Color(0xFF5E1B89);
  static const Color _ink = Color(0xFF1A1224);

  bool _busy = false;
  bool _autoGenerateTried = false;

  String? _intakeUrl(AppConfig config, Artist artist) {
    final String? token = artist.publicIntakeToken;
    if (token == null || !IntakeQrLink.isValidToken(token)) return null;
    final String url = config.intakeUrl(token);
    if (!IntakeQrLink.isValid(url, expectedToken: token)) return null;
    return url;
  }

  Future<void> _copy(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lien d\'accueil copié')),
    );
  }

  Future<void> _createOrRotate({required bool rotate}) async {
    if (rotate) {
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
    }

    setState(() => _busy = true);
    try {
      await ref.read(artistProvider.notifier).rotateIntakeToken();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            rotate ? 'Nouveau QR généré' : 'QR d\'accueil créé pour ce compte',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Génération impossible : $error'),
        ),
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
    final String? url = _intakeUrl(config, artist);
    if (url == null && !_autoGenerateTried && !_busy) {
      _autoGenerateTried = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _createOrRotate(rotate: false);
      });
    }

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
              url == null
                  ? 'Génère le QR unique de ce compte. Tes clients le '
                      'scannent pour ouvrir uniquement TON formulaire web.'
                  : 'QR unique de ${artist.studioName.isEmpty ? 'ton compte' : artist.studioName}. '
                      'Le client scanne, remplit sa fiche et signe la décharge. '
                      'Ça arrive dans sa fiche, sans toucher aux autres comptes.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (url != null) ...<Widget>[
              const SizedBox(height: 16),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: _violet.withValues(alpha: 0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: <Widget>[
                      QrImageView(
                        data: url,
                        version: QrVersions.auto,
                        size: 220,
                        backgroundColor: Colors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.Q,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.circle,
                          color: _ink,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.circle,
                          color: _violet,
                        ),
                        embeddedImage:
                            const AssetImage('assets/icon/app_icon.png'),
                        embeddedImageStyle: const QrEmbeddedImageStyle(
                          size: Size(36, 36),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        artist.studioName.isEmpty
                            ? 'DesK Tattoo'
                            : artist.studioName,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: _ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(
                url,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _copy(url),
                icon: const Icon(Icons.link_rounded),
                label: const Text('Copier le lien d\'accueil'),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _busy
                    ? null
                    : () => _createOrRotate(rotate: true),
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.autorenew_rounded, size: 18),
                label: const Text('Régénérer le QR'),
              ),
            ] else ...<Widget>[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _busy
                    ? null
                    : () => _createOrRotate(rotate: false),
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.qr_code_2_rounded),
                label: const Text('Générer mon QR d\'accueil'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
