import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';
import '../domain/intake_submission.dart';

/// Accès aux deux Edge Functions publiques utilisées par le formulaire
/// d'accueil client. Aucune session utilisateur n'est requise.
class IntakeRepository {
  IntakeRepository(this._client);

  final SupabaseClient? _client;

  SupabaseClient get _requireClient {
    final SupabaseClient? client = _client;
    if (client == null) {
      throw IntakeException(
        'Service indisponible. Le studio doit terminer sa configuration.',
      );
    }
    return client;
  }

  /// En-tête du studio à partir du token encodé dans le QR code.
  Future<IntakeStudio> loadStudio(String token) async {
    final SupabaseClient client = _requireClient;
    try {
      final FunctionResponse res = await client.functions.invoke(
        'intake-artist',
        method: HttpMethod.post,
        body: <String, dynamic>{'token': token},
      );
      final Object? data = res.data;
      if (res.status >= 400 || data is! Map) {
        throw IntakeException(_errorMessage(data, res.status));
      }
      return IntakeStudio.fromJson(Map<String, dynamic>.from(data));
    } on IntakeException {
      rethrow;
    } on FunctionException catch (e) {
      throw IntakeException(_functionMessage(e));
    } catch (_) {
      throw IntakeException('Impossible de contacter le studio. Réessaie.');
    }
  }

  /// Envoie la fiche client, la signature et le contrat signé.
  Future<String> submit({
    required String token,
    required IntakeSubmission submission,
    required Uint8List signaturePng,
    required Uint8List? pdfBytes,
  }) async {
    final SupabaseClient client = _requireClient;
    try {
      final FunctionResponse res = await client.functions.invoke(
        'intake-submit',
        method: HttpMethod.post,
        body: submission.toRequestBody(
          token: token,
          signatureBase64: base64Encode(signaturePng),
          pdfBase64: pdfBytes == null ? null : base64Encode(pdfBytes),
        ),
      );
      final Object? data = res.data;
      if (res.status >= 400 || data is! Map) {
        throw IntakeException(_errorMessage(data, res.status));
      }
      return (data['consent_id'] as String?) ?? '';
    } on IntakeException {
      rethrow;
    } on FunctionException catch (e) {
      throw IntakeException(_functionMessage(e));
    } catch (_) {
      throw IntakeException('Envoi impossible. Vérifie ta connexion.');
    }
  }

  String _errorMessage(Object? data, int status) {
    if (data is Map && data['error'] != null) {
      return data['error'].toString();
    }
    if (status == 404) return 'Ce lien n\'est plus valide.';
    return 'Une erreur est survenue ($status).';
  }

  String _functionMessage(FunctionException e) {
    final Object? details = e.details;
    if (details is Map && details['error'] != null) {
      return details['error'].toString();
    }
    if (e.status == 404) {
      return 'Ce lien n\'est plus valide.';
    }
    return details?.toString() ?? 'Erreur du service (${e.status}).';
  }
}

class IntakeException implements Exception {
  IntakeException(this.message);

  final String message;

  @override
  String toString() => message;
}

final Provider<IntakeRepository> intakeRepositoryProvider =
    Provider<IntakeRepository>(
  (Ref ref) => IntakeRepository(ref.watch(supabaseClientProvider)),
);

/// Charge l'en-tête du studio pour un token donné.
final FutureProviderFamily<IntakeStudio, String> intakeStudioProvider =
    FutureProvider.family<IntakeStudio, String>((Ref ref, String token) {
  return ref.watch(intakeRepositoryProvider).loadStudio(token);
});
