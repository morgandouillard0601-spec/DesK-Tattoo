import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/preferences_service.dart';
import '../../../shared/utils/id_generator.dart';
import '../domain/artist.dart';

/// Compte local déjà utilisé — on conserve le profil studio d’origine.
const String kLegacyAccountEmail = 'morgandesk@gmail.com';

class ArtistNotifier extends Notifier<Artist> {
  @override
  Artist build() => Artist.empty();

  PreferencesService get _prefs => ref.read(preferencesServiceProvider);

  /// Profil déjà inscrit avant le multi-étapes (session DesK Tattoo).
  static const Artist legacyMorganProfile = Artist(
    id: 'artist_morgan_desk',
    firstName: 'Morgan',
    lastName: 'Desk',
    email: kLegacyAccountEmail,
    phone: '+33 6 00 00 00 00',
    studioName: 'DesK Tattoo Studio',
    specialties: <String>['Black & Grey', 'Réalisme', 'Géométrique'],
    experienceYears: 6,
    bio:
        'Tatoueur depuis 2020, spécialisé dans le réalisme et le black & grey. Studio basé à Paris.',
    instagram: '@desk.tattoo',
  );

  Future<void> ensureLegacyMorganProfile() async {
    // Toujours rattacher le profil studio déjà inscrit à ce compte.
    await _prefs.writeArtistProfile(legacyMorganProfile);
    await _prefs.markLegacyMorganProfileRestored();
  }

  Future<void> loadForEmail(String email) async {
    final String normalized = email.trim().toLowerCase();
    if (normalized == kLegacyAccountEmail) {
      await ensureLegacyMorganProfile();
      state = legacyMorganProfile;
      return;
    }
    final Artist? stored = _prefs.readArtistProfile(normalized);
    state = stored ?? Artist.empty().copyWith(email: normalized);
  }

  Future<void> saveProfile(Artist artist) async {
    final Artist toSave = artist.id.isEmpty
        ? artist.copyWith(id: generateId('artist'))
        : artist;
    await _prefs.writeArtistProfile(toSave);
    state = toSave;
  }

  Future<Artist> createFromRegistration({
    required String email,
    required String firstName,
    required String lastName,
    required String phone,
    required String studioName,
    required List<String> specialties,
    required int experienceYears,
    String? bio,
    String? instagram,
  }) async {
    final String normalized = email.trim().toLowerCase();

    // Ne pas écraser le profil déjà inscrit de ce compte historique.
    if (normalized == kLegacyAccountEmail) {
      await ensureLegacyMorganProfile();
      final Artist? existing = _prefs.readArtistProfile(normalized);
      if (existing != null && existing.isComplete) {
        state = existing;
        return existing;
      }
      await _prefs.writeArtistProfile(legacyMorganProfile);
      state = legacyMorganProfile;
      return legacyMorganProfile;
    }

    final Artist artist = Artist(
      id: generateId('artist'),
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: normalized,
      phone: phone.trim(),
      studioName: studioName.trim(),
      specialties: specialties,
      experienceYears: experienceYears,
      bio: (bio == null || bio.trim().isEmpty) ? null : bio.trim(),
      instagram: (instagram == null || instagram.trim().isEmpty)
          ? null
          : instagram.trim(),
    );
    await saveProfile(artist);
    return artist;
  }

  void clearSessionProfile() {
    state = Artist.empty();
  }
}

final NotifierProvider<ArtistNotifier, Artist> artistProvider =
    NotifierProvider<ArtistNotifier, Artist>(ArtistNotifier.new);
