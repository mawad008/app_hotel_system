import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/errors/failure.dart';
import '../../data/datasources/api_auth_data_source.dart';
import '../../data/datasources/auth_data_source.dart';
import '../../data/datasources/dummy_auth_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/guest_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

/// Selects the auth data source by configuration — the UI never sees this choice
/// (README — "Development Strategy").
final authDataSourceProvider = Provider<AuthDataSource>((Ref ref) {
  final AppConfig config = ref.watch(appConfigProvider);
  return config.useDummyData
      ? const DummyAuthDataSource()
      : ApiAuthDataSource(ref.watch(apiClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((Ref ref) {
  return AuthRepositoryImpl(
    dataSource: ref.watch(authDataSourceProvider),
    tokenStore: ref.watch(tokenStoreProvider),
  );
});

/// Minimum time the branded splash (`AuthSplashPage`) stays on screen before the
/// router moves on. Session restore is often near-instant (one `me` round-trip),
/// so without a floor the splash would flash by unseen. 1.6s is the v2 Figma
/// `ENTRY_Splash` AFTER_TIMEOUT before the language sheet overlays it.
/// Overridden to [Duration.zero] in tests.
final splashMinDurationProvider = Provider<Duration>(
  (Ref ref) => const Duration(milliseconds: 1600),
);

/// Owns [AuthState] and the transitions between its cases. Feature screens call
/// these methods; the router redirects on the resulting state.
class AuthController extends Notifier<AuthState> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    // Kick off session restore; until it resolves the router shows a splash.
    // Hold it for at least [splashMinDurationProvider] so the brand screen is
    // actually seen even when restore returns immediately. Read dependencies
    // synchronously here — the container may be gone by the time the future runs.
    final AuthRepository repository = _repository;
    final Duration minSplash = ref.read(splashMinDurationProvider);
    bool disposed = false;
    ref.onDispose(() => disposed = true);

    // A 401 on an authenticated call means the server no longer accepts our
    // token (revoked, deleted account, expired) — end the session instead of
    // leaving every screen failing while the app still looks signed in.
    final StreamSubscription<void> rejected =
        ref.read(sessionEventsProvider).tokenRejected.listen((_) {
      if (state is Authenticated || state is AuthAwaitingProfile) expireSession();
    });
    ref.onDispose(rejected.cancel);

    Future<void>(() async {
      final Future<void> minimumSplash = Future<void>.delayed(minSplash);
      AuthState next;
      try {
        final AuthSession? restored = await repository.restoreSession();
        next = restored == null
            ? const AuthState.unauthenticated()
            : _fromSession(restored);
      } catch (_) {
        next = const AuthState.unauthenticated();
      }
      await minimumSplash;
      if (disposed) return;
      state = next;
    });
    return const AuthState.unknown();
  }

  /// Called by the login flow once a code is accepted.
  void onOtpVerified(AuthSession session) => state = _fromSession(session);

  /// Called after the first-time guest saves their name + email.
  void onProfileCompleted(AuthSession session) =>
      state = AuthState.authenticated(session);

  /// `PROFILE_PersonalInfo` "حفظ التعديلات": saves the guest's contact
  /// details on the backend (`PATCH /guest/profile`) and adopts the server's
  /// answer. Throws the `Failure`; the session is unchanged on error.
  Future<void> updateContactDetails({required String fullName, required String email}) async {
    final AuthState current = state;
    if (current is! Authenticated) return;
    final AuthSession updated = await _repository.completeProfile(
      session: current.session,
      fullName: fullName,
      email: email,
    );
    state = AuthState.authenticated(updated);
  }

  /// Revokes the backend token, then signs out locally. The guest is signed
  /// out on this device even if the revoke call failed (offline); the
  /// returned [Failure] (or null) lets the UI say the server could not be
  /// reached.
  Future<Failure?> signOut() async {
    Failure? failure;
    try {
      await _repository.signOut();
    } on Failure catch (f) {
      failure = f;
    }
    state = const AuthState.unauthenticated();
    return failure;
  }

  /// Invoked by the API/error layer when the backend rejects the stored token.
  Future<void> expireSession() async {
    await _repository.clearLocalSession();
    state = const AuthState.sessionExpired();
  }

  /// Leaves the `انتهت الجلسة` screen back to a clean sign-in.
  void acknowledgeExpiry() => state = const AuthState.unauthenticated();

  AuthState _fromSession(AuthSession session) => session.isProfileComplete
      ? AuthState.authenticated(session)
      : AuthState.awaitingProfile(session);
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
