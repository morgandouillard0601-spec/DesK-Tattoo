import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../profile/data/artist_repository.dart';
import '../../profile/domain/artist.dart';
import '../data/billing_repository.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _busy = false;
  String? _error;
  bool _didHandleReturn = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didHandleReturn) return;
    _didHandleReturn = true;
    final String? checkout =
        GoRouterState.of(context).uri.queryParameters['checkout'];
    if (checkout == 'success') {
      WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    } else if (checkout == 'cancel') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _error = 'Paiement annulé. Tu peux réessayer quand tu veux.';
        });
      });
    }
  }

  Future<void> _subscribe() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final bool already =
          await ref.read(billingRepositoryProvider).openCheckout();
      if (already) {
        await ref.read(authProvider.notifier).refreshEntitlement();
      }
    } on BillingException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Impossible d\'ouvrir le paiement : $e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).refreshEntitlement();
      final AuthState auth = ref.read(authProvider);
      if (!auth.entitled && mounted) {
        setState(
          () => _error =
              'Abonnement pas encore actif. Si tu viens de payer, patiente quelques secondes puis réessaie.',
        );
      }
    } on BillingException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Vérification impossible pour le moment.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Artist artist = ref.watch(artistProvider);
    final String price = ref.watch(appConfigProvider).monthlyPriceLabel;
    final bool pastDue =
        artist.subscriptionStatus == SubscriptionStatus.pastDue;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              theme.colorScheme.surface,
              theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Icon(
                      Icons.workspace_premium_rounded,
                      size: 56,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      pastDue
                          ? 'Accès temporairement suspendu'
                          : 'Active ton studio DesK Tattoo',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      pastDue
                          ? 'Le paiement du mois n\'a pas pu être prélevé. Régularise pour retrouver le dashboard.'
                          : 'Sans engagement — $price / mois. Accès immédiat au planning, clients, stock et compta.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Material(
                      color: theme.colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Text(
                              artist.studioName.isEmpty
                                  ? 'Abonnement DesK Tattoo'
                                  : artist.studioName,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Statut : ${artist.subscriptionStatus.labelFr}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 18),
                            const _Perk(text: 'Planning & clients illimités'),
                            const _Perk(text: 'Stock + compta studio'),
                            const _Perk(text: 'Résiliable à tout moment'),
                            const SizedBox(height: 10),
                            Text(
                              '$price / mois',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.primary,
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
                            const SizedBox(height: 18),
                            FilledButton(
                              onPressed: _busy ? null : _subscribe,
                              child: _busy
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      pastDue
                                          ? 'Régulariser le paiement'
                                          : 'S\'abonner — $price / mois',
                                    ),
                            ),
                            TextButton(
                              onPressed: _busy ? null : _refresh,
                              child: const Text('J\'ai payé — actualiser'),
                            ),
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => ref.read(authProvider.notifier).logout(),
                              child: const Text('Se déconnecter'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Perk extends StatelessWidget {
  const _Perk({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
