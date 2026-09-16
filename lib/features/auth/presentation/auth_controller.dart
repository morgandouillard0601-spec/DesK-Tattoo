import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../billing/data/billing_repository.dart';
import '../../profile/data/artist_repository.dart';
import '../../profile/domain/artist.dart';
import '../data/auth_repository.dart';
import '../domain/auth_user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.hasLocalAccount = false,
    this.entitled = false,
    this.isAdmin = false,
  });

  final AuthStatus status;
  final AuthUser? user;
  final bool hasLocalAccount;
  final bool entitled;
  final bool isAdmin;

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

class RegisterProfileInput {
  const RegisterProfileInput({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.studioName,
    required this.address,
    required this.city,
    required this.siret,
    required this.specialties,
    required this.experienceYears,
    this.bio,
    this.instagram,
  });

  final String firstName;
  final String lastName;
  final String phone;
  final String studioName;
  final String address;
  final String city;
  final String siret;
  final List<String> specialties;
  final int experienceYears;
  final String? bio;
  final String? instagram;
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState(status: AuthStatus.unknown);

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<void> bootstrap() async {
    state = const AuthState(status: AuthStatus.unknown);

    // Compte déjà utilisé : local + tentative création Auth Supabase.
    await _repo.ensureLegacyAccount(
      email: kLegacyAccountEmail,
      password: kLegacyAccountPassword,
    );
    await ref.read(artistProvider.notifier).ensureLegacyMorganProfile();

    final bool hasAccount = await _repo.hasLocalAccount();
    AuthUser? user = await _repo.restoreSession();

    // Auto-connexion legacy si aucune session (Supabase ou local).
    if (user == null) {
      try {
        user = await _repo.login(
          email: kLegacyAccountEmail,
          password: kLegacyAccountPassword,
        );
      } catch (_) {
        user = null;
      }
    }

    if (user != null) {
      await ref.read(artistProvider.notifier).loadForEmail(
            user.email,
            remoteId: user.id,
          );
      final Artist artist = ref.read(artistProvider);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        hasLocalAccount: true,
        entitled: _computeEntitled(user.email, artist),
        isAdmin: artist.isAdmin || user.email == kLegacyAccountEmail,
      );
    } else {
      ref.read(artistProvider.notifier).clearSessionProfile();
      state = AuthState(
        status: AuthStatus.unauthenticated,
        hasLocalAccount: hasAccount,
      );
    }
    _refreshRouter();
  }

  Future<void> register({
    required String email,
    required String password,
    required RegisterProfileInput profile,
  }) async {
    final AuthUser user = await _repo.register(
      email: email,
      password: password,
      metadata: <String, dynamic>{
        'first_name': profile.firstName,
        'last_name': profile.lastName,
        'phone': profile.phone,
        'studio_name': profile.studioName,
        'address': profile.address,
        'city': profile.city,
        'siret': profile.siret,
        'specialties': profile.specialties,
        'experience_years': profile.experienceYears.toString(),
        'bio': profile.bio,
        'instagram': profile.instagram,
      },
    );
    await ref.read(artistProvider.notifier).createFromRegistration(
          email: user.email,
          firstName: profile.firstName,
          lastName: profile.lastName,
          phone: profile.phone,
          studioName: profile.studioName,
          address: profile.address,
          city: profile.city,
          siret: profile.siret,
          specialties: profile.specialties,
          experienceYears: profile.experienceYears,
          bio: profile.bio,
          instagram: profile.instagram,
          remoteId: user.id,
        );
    final Artist artist = ref.read(artistProvider);
    state = AuthState(
      status: AuthStatus.authenticated,
      user: user,
      hasLocalAccount: true,
      entitled: _computeEntitled(user.email, artist),
      isAdmin: artist.isAdmin || user.email == kLegacyAccountEmail,
    );
    _refreshRouter();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final AuthUser user = await _repo.login(
      email: email,
      password: password,
    );
    await ref.read(artistProvider.notifier).loadForEmail(
          user.email,
          remoteId: user.id,
        );
    await refreshEntitlement();
  }

  Future<void> refreshEntitlement() async {
    final AuthUser? user = state.user ??
        (ref.read(artistProvider).email.isNotEmpty
            ? AuthUser(
                email: ref.read(artistProvider).email,
                id: ref.read(artistProvider).id,
              )
            : null);
    if (user == null) return;

    Artist artist = ref.read(artistProvider);
    if (_repo.usesSupabase) {
      try {
        final ArtistEntitlement ent =
            await ref.read(billingRepositoryProvider).refreshSubscriptionStatus();
        ref.read(artistProvider.notifier).applySubscriptionStatus(ent.status);
        artist = ref.read(artistProvider);
        if (ent.raw.isNotEmpty) {
          await ref.read(artistProvider.notifier).refreshFromRemote();
          artist = ref.read(artistProvider);
        }
      } catch (_) {
        // Keep local entitlement snapshot.
      }
    }

    state = AuthState(
      status: AuthStatus.authenticated,
      user: user,
      hasLocalAccount: true,
      entitled: _computeEntitled(user.email, artist),
      isAdmin: artist.isAdmin || user.email == kLegacyAccountEmail,
    );
    _refreshRouter();
  }

  bool _computeEntitled(String email, Artist artist) {
    if (email.trim().toLowerCase() == kLegacyAccountEmail) return true;
    return artist.isEntitled;
  }

  Future<void> logout() async {
    await _repo.logout();
    ref.read(artistProvider.notifier).clearSessionProfile();
    final bool hasAccount = await _repo.hasLocalAccount();
    state = AuthState(
      status: AuthStatus.unauthenticated,
      hasLocalAccount: hasAccount,
    );
    _refreshRouter();
  }

  void _refreshRouter() {
    ref.read(authRouterRefreshProvider).notify();
  }
}

final NotifierProvider<AuthNotifier, AuthState> authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// Notifies [GoRouter] when auth state changes so redirects re-run.
final Provider<AuthRouterRefresh> authRouterRefreshProvider =
    Provider<AuthRouterRefresh>((Ref ref) => AuthRouterRefresh());

class AuthRouterRefresh extends ChangeNotifier {
  void notify() => notifyListeners();
}
