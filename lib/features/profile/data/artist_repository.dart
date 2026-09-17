import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';
import '../../../core/storage/preferences_service.dart';
import '../../../shared/utils/id_generator.dart';
import '../../intake/domain/intake_qr_link.dart';
import '../domain/artist.dart';

/// Compte local déjà utilisé — on conserve le profil studio d’origine.
const String kLegacyAccountEmail = 'morgandesk@gmail.com';

class ArtistNotifier extends Notifier<Artist> {
  @override
  Artist build() => Artist.empty();

  PreferencesService get _prefs => ref.read(preferencesServiceProvider);
  SupabaseClient? get _supabase => ref.read(supabaseClientProvider);

  /// Profil déjà inscrit avant le multi-étapes (session DesK Tattoo).
  static const Artist legacyMorganProfile = Artist(
    id: 'artist_morgan_desk',
    firstName: 'Morgan',
    lastName: 'Desk',
    email: kLegacyAccountEmail,
    phone: '+33 6 00 00 00 00',
    studioName: 'DesK Tattoo Studio',
    address: '1 rue du Studio',
    city: 'Paris',
    siret: '00000000000000',
    specialties: <String>['Black & Grey', 'Réalisme', 'Géométrique'],
    experienceYears: 6,
    bio:
        'Tatoueur depuis 2020, spécialisé dans le réalisme et le black & grey. Studio basé à Paris.',
    instagram: '@desk.tattoo',
    role: ArtistRole.admin,
    subscriptionStatus: SubscriptionStatus.active,
  );

  Future<void> ensureLegacyMorganProfile() async {
    final Artist? stored = _prefs.readArtistProfile(kLegacyAccountEmail);
    if (stored == null) {
      await _prefs.writeArtistProfile(legacyMorganProfile);
    }
    await _prefs.markLegacyMorganProfileRestored();
  }

  Future<void> loadForEmail(String email, {String? remoteId}) async {
    final String normalized = email.trim().toLowerCase();
    if (normalized == kLegacyAccountEmail) {
      await ensureLegacyMorganProfile();
      Artist legacy =
          _prefs.readArtistProfile(normalized) ?? legacyMorganProfile;
      final String? uuid = _uuidOrNull(remoteId) ?? _uuidOrNull(legacy.id);
      if (uuid != null) {
        legacy = legacy.copyWith(id: uuid);
      }
      state = legacy;
      // Try refresh from Supabase without losing admin entitlement.
      final Artist? remote = await _fetchRemote(uuid ?? '');
      if (remote != null) {
        state = remote.copyWith(
          role: ArtistRole.admin,
          subscriptionStatus: SubscriptionStatus.active,
          publicIntakeToken: _preferredIntakeToken(
            remote.publicIntakeToken,
            legacy.publicIntakeToken,
          ),
        );
        await _prefs.writeArtistProfile(state);
      }
      return;
    }

    if (remoteId != null && remoteId.isNotEmpty) {
      final Artist? remote = await _fetchRemote(remoteId);
      if (remote != null) {
        state = remote;
        await _prefs.writeArtistProfile(remote);
        return;
      }
    }

    final Artist? stored = _prefs.readArtistProfile(normalized);
    state = stored ?? Artist.empty().copyWith(email: normalized);
  }

  Future<Artist?> _fetchRemote(String id) async {
    final SupabaseClient? client = _supabase;
    if (client == null || id.isEmpty) return null;
    try {
      final Map<String, dynamic>? row = await client
          .from('artists')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (row == null) return null;
      return Artist.fromJson(row);
    } catch (_) {
      return null;
    }
  }

  /// Régénère le token du QR d'accueil client : les QR déjà imprimés cessent
  /// de fonctionner. Retourne le nouveau token.
  ///
  /// Si la RPC Supabase n’est pas encore déployée (ou pas de ligne `artists`),
  /// le token est quand même créé en local pour afficher le QR.
  Future<String> rotateIntakeToken() async {
    String token = IntakeQrLink.generateToken();
    final SupabaseClient? client = _supabase;
    final String? uid = _uuidOrNull(client?.auth.currentUser?.id);

    if (client != null && uid != null) {
      try {
        final dynamic result = await client.rpc<dynamic>('rotate_intake_token');
        final String rpcToken = result?.toString().trim() ?? '';
        if (IntakeQrLink.isValidToken(rpcToken)) {
          token = rpcToken;
        } else {
          await _persistIntakeTokenRemote(client, uid, token);
        }
      } catch (_) {
        try {
          await _persistIntakeTokenRemote(client, uid, token);
        } catch (_) {
          // Le QR local reste utilisable même si le cloud n’a pas la colonne.
        }
      }
      if (state.id != uid) {
        state = state.copyWith(id: uid);
      }
    }

    state = state.copyWith(publicIntakeToken: token);
    await _prefs.writeArtistProfile(state);
    return token;
  }

  Future<void> _persistIntakeTokenRemote(
    SupabaseClient client,
    String uid,
    String token,
  ) async {
    final String now = DateTime.now().toUtc().toIso8601String();
    final Map<String, dynamic> row = <String, dynamic>{
      'id': uid,
      'email': state.email,
      'first_name': state.firstName,
      'last_name': state.lastName,
      'phone': state.phone,
      'studio_name': state.studioName,
      'address': state.address,
      'city': state.city,
      'siret': state.siret,
      'specialties': state.specialties,
      'experience_years': state.experienceYears,
      'bio': state.bio,
      'instagram': state.instagram,
      'public_intake_token': token,
      'updated_at': now,
    };
    try {
      await client.from('artists').upsert(row);
    } catch (_) {
      await client.from('artists').update(<String, dynamic>{
        'public_intake_token': token,
        'updated_at': now,
      }).eq('id', uid);
    }
  }

  String? _uuidOrNull(String? value) {
    if (value == null || value.isEmpty || value.startsWith('artist_')) {
      return null;
    }
    return value;
  }

  String? _preferredIntakeToken(String? remote, String? local) {
    if (remote != null && IntakeQrLink.isValidToken(remote)) return remote;
    if (local != null && IntakeQrLink.isValidToken(local)) return local;
    return remote ?? local;
  }

  Future<void> refreshFromRemote() async {
    final String id = state.id;
    if (id.isEmpty || id.startsWith('artist_')) return;
    final String? localToken = state.publicIntakeToken;
    final Artist? remote = await _fetchRemote(id);
    if (remote != null) {
      state = remote.copyWith(
        publicIntakeToken: _preferredIntakeToken(
          remote.publicIntakeToken,
          localToken,
        ),
      );
      await _prefs.writeArtistProfile(state);
    }
  }

  Future<void> saveProfile(Artist artist) async {
    final Artist toSave = artist.id.isEmpty
        ? artist.copyWith(id: generateId('artist'))
        : artist;
    await _prefs.writeArtistProfile(toSave);

    final SupabaseClient? client = _supabase;
    if (client != null &&
        toSave.id.isNotEmpty &&
        !toSave.id.startsWith('artist_')) {
      try {
        await client.from('artists').update(toSave.toSupabaseUpdate()).eq(
              'id',
              toSave.id,
            );
      } catch (_) {
        // Local profile remains source of truth offline.
      }
    }
    state = toSave;
  }

  Future<Artist> createFromRegistration({
    required String email,
    required String firstName,
    required String lastName,
    required String phone,
    required String studioName,
    required String address,
    required String city,
    required String siret,
    required List<String> specialties,
    required int experienceYears,
    String? bio,
    String? instagram,
    String? remoteId,
  }) async {
    final String normalized = email.trim().toLowerCase();

    if (normalized == kLegacyAccountEmail) {
      await ensureLegacyMorganProfile();
      state = legacyMorganProfile.copyWith(id: remoteId ?? legacyMorganProfile.id);
      return state;
    }

    final bool isLegacyId = remoteId == null || remoteId.isEmpty;
    final Artist artist = Artist(
      id: isLegacyId ? generateId('artist') : remoteId,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: normalized,
      phone: phone.trim(),
      studioName: studioName.trim(),
      address: address.trim(),
      city: city.trim(),
      siret: siret.trim(),
      specialties: specialties,
      experienceYears: experienceYears,
      bio: (bio == null || bio.trim().isEmpty) ? null : bio.trim(),
      instagram: (instagram == null || instagram.trim().isEmpty)
          ? null
          : instagram.trim(),
      role: ArtistRole.artist,
      subscriptionStatus: SubscriptionStatus.none,
      onboardingCompletedAt: DateTime.now(),
    );

    await _prefs.writeArtistProfile(artist);

    final SupabaseClient? client = _supabase;
    if (client != null && !isLegacyId) {
      try {
        await client.from('artists').update(<String, dynamic>{
          ...artist.toSupabaseUpdate(),
          'onboarding_completed_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', artist.id);
      } catch (_) {}
    }

    state = artist;
    return artist;
  }

  Future<List<Artist>> listAllStudiosForAdmin() async {
    final SupabaseClient? client = _supabase;
    if (client != null) {
      try {
        final List<dynamic> rows = await client
            .from('artists')
            .select()
            .order('created_at', ascending: false);
        return rows
            .map((dynamic e) => Artist.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
    // Local fallback: current profile only.
    if (state.email.isNotEmpty) return <Artist>[state];
    return const <Artist>[];
  }

  void applySubscriptionStatus(SubscriptionStatus status) {
    state = state.copyWith(subscriptionStatus: status);
    _prefs.writeArtistProfile(state);
  }

  void clearSessionProfile() {
    state = Artist.empty();
  }
}

final NotifierProvider<ArtistNotifier, Artist> artistProvider =
    NotifierProvider<ArtistNotifier, Artist>(ArtistNotifier.new);
