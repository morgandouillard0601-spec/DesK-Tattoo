import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/providers.dart';
import '../../../core/network/supabase_client.dart';
import '../../profile/domain/artist.dart';

class BillingRepository {
  BillingRepository(this._client, this._config);

  final SupabaseClient? _client;
  final AppConfig _config;

  Future<String?> createCheckoutUrl() async {
    final SupabaseClient? client = _client;
    if (client == null) {
      throw BillingException(
        'Supabase n\'est pas configuré. Ajoute SUPABASE_URL et SUPABASE_ANON_KEY dans .env.',
      );
    }

    try {
      final Map<String, dynamic> body = <String, dynamic>{};
      if (kIsWeb) {
        // Retour Stripe → même origine Vercel (preview ou prod).
        body['return_base_url'] = Uri.base.origin;
      }

      final FunctionResponse res = await client.functions.invoke(
        'create-checkout-session',
        method: HttpMethod.post,
        body: body,
      );

      final Object? data = res.data;
      if (res.status == 404) {
        throw BillingException(
          'La function Stripe n\'est pas déployée (404). Déploie create-checkout-session sur Supabase.',
        );
      }
      if (res.status >= 400) {
        final String message = data is Map && data['error'] != null
            ? data['error'].toString()
            : 'Impossible de créer la session Stripe (${res.status}).';
        throw BillingException(message);
      }

      if (data is Map && data['already_entitled'] == true) {
        return null;
      }
      if (data is Map && data['url'] is String) {
        return data['url'] as String;
      }
      throw BillingException('Réponse Checkout invalide.');
    } on BillingException {
      rethrow;
    } on FunctionException catch (e) {
      if (e.status == 404) {
        throw BillingException(
          'Functions Stripe non déployées. Lance: supabase functions deploy create-checkout-session',
        );
      }
      throw BillingException(
        e.details?.toString() ?? e.reasonPhrase ?? 'Erreur function (${e.status})',
      );
    } catch (e) {
      throw BillingException(e.toString());
    }
  }

  Future<bool> openCheckout() async {
    final String? url = await createCheckoutUrl();
    if (url == null) return true; // already entitled
    final Uri uri = Uri.parse(url);
    final bool ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      throw BillingException('Impossible d\'ouvrir Stripe Checkout.');
    }
    return false;
  }

  Future<ArtistEntitlement> refreshSubscriptionStatus() async {
    final SupabaseClient? client = _client;
    if (client == null) {
      // Local / offline: trust artist provider caller.
      return const ArtistEntitlement(
        entitled: false,
        status: SubscriptionStatus.none,
      );
    }

    final FunctionResponse res = await client.functions.invoke(
      'subscription-status',
      method: HttpMethod.post,
    );
    final Object? data = res.data;
    if (res.status >= 400 || data is! Map) {
      throw BillingException('Impossible de vérifier l\'abonnement.');
    }

    final SubscriptionStatus status = SubscriptionStatus.fromWire(
      (data['subscription_status'] as String?) ?? 'none',
    );
    final bool entitled = data['entitled'] == true ||
        data['role'] == 'admin' ||
        status == SubscriptionStatus.active ||
        status == SubscriptionStatus.trialing;

    return ArtistEntitlement(
      entitled: entitled,
      status: status,
      periodEnd: data['subscription_current_period_end'] != null
          ? DateTime.tryParse(
              data['subscription_current_period_end'].toString(),
            )
          : null,
      raw: Map<String, dynamic>.from(data),
    );
  }

  String get priceLabel => _config.monthlyPriceLabel;
}

class ArtistEntitlement {
  const ArtistEntitlement({
    required this.entitled,
    required this.status,
    this.periodEnd,
    this.raw = const <String, dynamic>{},
  });

  final bool entitled;
  final SubscriptionStatus status;
  final DateTime? periodEnd;
  final Map<String, dynamic> raw;
}

class BillingException implements Exception {
  BillingException(this.message);
  final String message;
  @override
  String toString() => message;
}

final Provider<BillingRepository> billingRepositoryProvider =
    Provider<BillingRepository>((Ref ref) {
  return BillingRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appConfigProvider),
  );
});
