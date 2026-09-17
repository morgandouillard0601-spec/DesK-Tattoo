import 'package:flutter_test/flutter_test.dart';

import 'package:desk_tattoo/core/config/app_config.dart';
import 'package:desk_tattoo/features/clients/domain/client.dart';
import 'package:desk_tattoo/features/intake/domain/intake_qr_link.dart';
import 'package:desk_tattoo/features/planning/domain/appointment.dart';
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
      webAppUrl: 'https://desktattoo.app',
    );

    expect(config.isDev, isTrue);
    expect(config.isProd, isFalse);
    expect(config.appName, 'DesK Tattoo');
    expect(config.supabaseConfigured, isFalse);
    expect(config.intakeUrl('abcdef0123456789'),
        'https://desktattoo.app/intake/abcdef0123456789');
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

  test('appointment status uses snake_case on the wire', () {
    // La contrainte CHECK de public.appointments attend `in_progress`.
    expect(AppointmentStatus.inProgress.wire, 'in_progress');
    expect(AppointmentStatus.scheduled.wire, 'scheduled');
    expect(
      appointmentStatusFromWire('in_progress'),
      AppointmentStatus.inProgress,
    );
    expect(appointmentStatusFromWire(null), AppointmentStatus.scheduled);
  });

  test('appointment maps duration to minutes', () {
    final Appointment appointment = Appointment.fromSupabase(
      <String, dynamic>{
        'id': 'uuid-1',
        'client_id': 'uuid-client',
        'client_name': 'Camille Moreau',
        'title': 'Retouche',
        'start_at': '2026-09-16T10:00:00.000Z',
        'duration_minutes': 90,
        'price': '150.00',
        'status': 'confirmed',
      },
    );
    expect(appointment.duration, const Duration(minutes: 90));
    expect(appointment.price, 150);
    expect(appointment.status, AppointmentStatus.confirmed);
    expect(appointment.toSupabase()['duration_minutes'], 90);
  });

  test('client from intake is flagged', () {
    final Client client = Client.fromSupabase(<String, dynamic>{
      'id': 'uuid-client',
      'first_name': 'Camille',
      'last_name': 'Moreau',
      'phone': '+33 6 12 34 56 78',
      'email': 'camille@example.com',
      'created_at': '2026-09-16T10:00:00.000Z',
      'source': 'intake',
      'total_spent': '920.50',
      'address': '1 rue du Studio',
      'postal_code': '75011',
      'city': 'Paris',
    });
    expect(client.isFromIntake, isTrue);
    expect(client.totalSpent, 920.5);
    expect(client.addressLine, '1 rue du Studio · 75011 · Paris');
  });

  test('manual client is the default source', () {
    final Client client = Client.fromSupabase(<String, dynamic>{
      'id': 'uuid-client',
      'first_name': 'Lucas',
      'last_name': 'Bernard',
      'created_at': '2026-09-16T10:00:00.000Z',
    });
    expect(client.source, ClientSource.manual);
    expect(client.isFromIntake, isFalse);
    expect(client.addressLine, isEmpty);
  });

  test('intake QR encodes the web form of that account only', () {
    const String token = 'a1b2c3d4e5f60789';
    final String url = IntakeQrLink.build(
      webAppUrl: 'https://moonlit-medovik-0ae9fb.netlify.app/',
      token: token,
    );
    expect(url, 'https://moonlit-medovik-0ae9fb.netlify.app/intake/$token');
    expect(IntakeQrLink.isValid(url, expectedToken: token), isTrue);
    expect(IntakeQrLink.tokenOf(url), token);
    expect(
      IntakeQrLink.isValid(url, expectedToken: 'other-token-xx'),
      isFalse,
    );
    expect(IntakeQrLink.isValid('https://evil.example/intake/$token'), isTrue);
    expect(IntakeQrLink.isValid('https://site.netlify.app/login'), isFalse);
  });

  test('intake token generator is valid for the QR URL', () {
    final String token = IntakeQrLink.generateToken();
    expect(IntakeQrLink.isValidToken(token), isTrue);
    expect(token.length, 32);
  });
}
