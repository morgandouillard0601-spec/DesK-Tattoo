import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/auth_controller.dart';

/// Mot à saisir pour confirmer, afin d'éviter une suppression accidentelle.
const String _confirmationWord = 'SUPPRIMER';

const List<String> _deletedItems = <String>[
  'Ton profil studio et tes identifiants de connexion',
  'Tes clients, leurs fiches et leurs contrats signés (PDF inclus)',
  'Tes rendez-vous, ton stock et ta comptabilité',
  'Ton QR d\'accueil client : les QR imprimés cessent de fonctionner',
];

/// Section « Compte » du profil : suppression définitive du compte studio.
class DeleteAccountSection extends StatelessWidget {
  const DeleteAccountSection({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
      child: ListTile(
        leading: Icon(
          Icons.delete_forever_rounded,
          color: theme.colorScheme.error,
        ),
        title: Text(
          'Supprimer mon compte',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.error,
          ),
        ),
        subtitle: const Text(
          'Efface définitivement ton studio et toutes ses données.',
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: theme.colorScheme.error,
        ),
        onTap: () => showDeleteAccountDialog(context),
      ),
    );
  }
}

/// Ouvre le parcours complet de suppression : récapitulatif, confirmation
/// explicite, puis suppression côté serveur.
Future<void> showDeleteAccountDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _DeleteAccountDialog(),
  );
}

class _DeleteAccountDialog extends ConsumerStatefulWidget {
  const _DeleteAccountDialog();

  @override
  ConsumerState<_DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<_DeleteAccountDialog> {
  final TextEditingController _confirmation = TextEditingController();

  bool _busy = false;
  String? _error;

  bool get _canDelete =>
      _confirmation.text.trim().toUpperCase() == _confirmationWord;

  @override
  void dispose() {
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final NavigatorState navigator = Navigator.of(context);

    try {
      await ref.read(authProvider.notifier).deleteAccount();
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Compte supprimé. Toutes tes données ont été effacées.'),
          duration: Duration(seconds: 6),
        ),
      );
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Suppression impossible pour le moment. Réessaie.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AlertDialog(
      icon: Icon(
        Icons.delete_forever_rounded,
        color: theme.colorScheme.error,
        size: 32,
      ),
      title: const Text('Supprimer mon compte ?'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Cette action est définitive et immédiate. Seront supprimés :',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            for (final String item in _deletedItems)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      Icons.remove_circle_outline_rounded,
                      size: 16,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(item, style: theme.textTheme.bodySmall),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            Text(
              'Ton abonnement est résilié automatiquement : aucun prélèvement '
              'ne sera effectué après la suppression.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Saisis $_confirmationWord pour confirmer.',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmation,
              enabled: !_busy,
              autocorrect: false,
              textCapitalization: TextCapitalization.characters,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: _confirmationWord,
                isDense: true,
              ),
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 14),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _busy || !_canDelete ? null : _delete,
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          child: _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : const Text('Supprimer définitivement'),
        ),
      ],
    );
  }
}
