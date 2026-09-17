import 'package:flutter/material.dart';

/// Page d'accueil du site public : le formulaire ne s'ouvre que via le QR.
class IntakeLandingScreen extends StatelessWidget {
  const IntakeLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.qr_code_2_rounded,
                    size: 72,
                    color: colors.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Fiche d\'accueil client',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Scanne le QR code que ton tatoueur te montre pour '
                    'remplir ta fiche et signer la décharge.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
