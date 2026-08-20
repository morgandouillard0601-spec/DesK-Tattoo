import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/data/artist_repository.dart';
import '../data/auth_repository.dart';
import '../domain/auth_user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.hasLocalAccount = false,
  });

  final AuthStatus status;
  final AuthUser? user;
  final bool hasLocalAccount;

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

class RegisterProfileInput {
  const RegisterProfileInput({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.studioName,
    required this.specialties,
    required this.experienceYears,
    this.bio,
    this.instagram,
  });

  final String firstName;
  final String lastName;
  final String phone;
  final String studioName;
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

    // Compte déjà utilisé : conserve les identifiants + le profil studio d’origine.
    await _repo.ensureLegacyAccount(
      email: kLegacyAccountEmail,
      password: 'Erachid93',
    );
    await ref.read(artistProvider.notifier).ensureLegacyMorganProfile();

    final bool hasAccount = await _repo.hasLocalAccount();
    final AuthUser? user = await _repo.restoreSession();
    if (user != null) {
      await ref.read(artistProvider.notifier).loadForEmail(user.email);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        hasLocalAccount: true,
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
    );
    await ref.read(artistProvider.notifier).createFromRegistration(
          email: user.email,
          firstName: profile.firstName,
          lastName: profile.lastName,
          phone: profile.phone,
          studioName: profile.studioName,
          specialties: profile.specialties,
          experienceYears: profile.experienceYears,
          bio: profile.bio,
          instagram: profile.instagram,
        );
    state = AuthState(
      status: AuthStatus.authenticated,
      user: user,
      hasLocalAccount: true,
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
    await ref.read(artistProvider.notifier).loadForEmail(user.email);
    state = AuthState(
      status: AuthStatus.authenticated,
      user: user,
      hasLocalAccount: true,
    );
    _refreshRouter();
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
