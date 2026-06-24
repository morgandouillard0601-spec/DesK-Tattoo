import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/artist.dart';

class ArtistRepository {
  ArtistRepository() : _artist = _seed;

  Artist _artist;

  static const Artist _seed = Artist(
    id: 'me',
    firstName: 'Alex',
    lastName: 'Durand',
    email: 'alex@desk-tattoo.fr',
    phone: '+33 6 00 00 00 00',
    studioName: 'DesK Tattoo Studio',
    specialties: <String>['Black & Grey', 'Réalisme', 'Géométrique'],
    experienceYears: 6,
    bio:
        'Tatoueur depuis 2020, spécialisé dans le réalisme et le black & grey. Studio basé à Paris.',
    instagram: '@desk.tattoo',
  );

  Artist get() => _artist;

  void update(Artist next) => _artist = next;
}

final Provider<ArtistRepository> artistRepositoryProvider =
    Provider<ArtistRepository>((Ref ref) => ArtistRepository());

final Provider<Artist> artistProvider = Provider<Artist>(
  (Ref ref) => ref.watch(artistRepositoryProvider).get(),
);
