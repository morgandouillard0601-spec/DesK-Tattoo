import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/config/providers.dart';

/// Partage simple du lien de l'app (Messages, Mail, WhatsApp, etc.).
class AppShareCard extends ConsumerWidget {
  const AppShareCard({super.key});

  String _message(String url) =>
      'Je gère mon studio avec DesK Tattoo : $url';

  Future<void> _share(BuildContext context, String url) async {
    await SharePlus.instance.share(
      ShareParams(
        text: _message(url),
        subject: 'DesK Tattoo',
      ),
    );
  }

  Future<void> _copy(BuildContext context, String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lien copié')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final String url = ref.watch(appConfigProvider).appDownloadUrl;

    return Card(
      color: theme.colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Envoie le lien à un copain tatoueur, par Messages, Mail '
              'ou WhatsApp.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => _share(context, url),
              icon: const Icon(Icons.ios_share_rounded),
              label: const Text('Partager'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _copy(context, url),
              icon: const Icon(Icons.link_rounded),
              label: const Text('Copier le lien'),
            ),
          ],
        ),
      ),
    );
  }
}
