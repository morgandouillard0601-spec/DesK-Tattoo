import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState(status: AuthStatus.unknown);

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<void> bootstrap() async {
    state = const AuthState(status: AuthStatus.unknown);
    final bool hasAccount = await _repo.hasLocalAccount();
    final AuthUser? user = await _repo.restoreSession();
    if (user != null) {
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        hasLocalAccount: true,
      );
    } else {
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
  }) async {
    final AuthUser user = await _repo.register(
      email: email,
      password: password,
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
    state = AuthState(
      status: AuthStatus.authenticated,
      user: user,
      hasLocalAccount: true,
    );
    _refreshRouter();
  }

  Future<void> logout() async {
    await _repo.logout();
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
