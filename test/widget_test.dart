import 'package:flutter_test/flutter_test.dart';

import 'package:desk_tattoo/core/config/app_config.dart';
import 'package:desk_tattoo/features/profile/domain/artist.dart';

void main() {
  test('AppConfig defaults to dev environment', () {
    const AppConfig config = AppConfig(
      appName: 'DesK Tattoo',
      env: AppEnv.dev,
      apiBaseUrl: 'https://api.example.com',
      apiTimeout: Duration(seconds: 15),
      appStoreUrl: 'https://apps.apple.com/app/idXXXXXXXXX',
      playStoreUrl: 'https://play.google.com/store/apps/details?id=x',
      appDownloadUrl: 'https://desktattoo.app/get/x',
      supabaseUrl: '',
      supabaseAnonKey: '',
      stripePublishableKey: '',
      stripeProductId: 'prod_VFctn7oeEEtvpK',
      monthlyPriceLabel: '19,99 €',
    );

    expect(config.isDev, isTrue);
    expect(config.isProd, isFalse);
    expect(config.appName, 'DesK Tattoo');
    expect(config.supabaseConfigured, isFalse);
  });

  test('legacy artist is entitled as admin', () {
    const Artist artist = Artist(
      id: '1',
      firstName: 'Morgan',
      lastName: 'Desk',
      email: 'morgandesk@gmail.com',
      phone: '1',
      studioName: 'DesK',
      specialties: <String>['Réalisme'],
      experienceYears: 6,
      role: ArtistRole.admin,
      subscriptionStatus: SubscriptionStatus.active,
    );
    expect(artist.isEntitled, isTrue);
    expect(artist.isAdmin, isTrue);
  });

  test('unpaid artist is not entitled', () {
    final Artist artist = Artist.empty().copyWith(
      email: 'studio@test.com',
      subscriptionStatus: SubscriptionStatus.none,
    );
    expect(artist.isEntitled, isFalse);
  });

  test('past_due subscription blocks access', () {
    final Artist artist = Artist.empty().copyWith(
      subscriptionStatus: SubscriptionStatus.pastDue,
    );
    expect(artist.isEntitled, isFalse);
    expect(artist.subscriptionStatus.labelFr, 'Paiement en échec');
  });
}
