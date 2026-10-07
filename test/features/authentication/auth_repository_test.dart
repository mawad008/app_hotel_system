import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/errors/app_exception.dart';
import 'package:hotel_guest_app/core/errors/failure.dart';
import 'package:hotel_guest_app/core/security/in_memory_token_store.dart';
import 'package:hotel_guest_app/core/security/token_store.dart';
import 'package:hotel_guest_app/features/authentication/data/datasources/auth_data_source.dart';
import 'package:hotel_guest_app/features/authentication/data/datasources/auth_demo_config.dart';
import 'package:hotel_guest_app/features/authentication/data/datasources/dummy_auth_data_source.dart';
import 'package:hotel_guest_app/features/authentication/data/models/auth_models.dart';
import 'package:hotel_guest_app/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:hotel_guest_app/features/authentication/domain/entities/guest_phone.dart';
import 'package:hotel_guest_app/features/authentication/domain/entities/guest_profile.dart';
import 'package:hotel_guest_app/features/authentication/domain/entities/otp_challenge.dart';

const GuestPhone _phone =
    GuestPhone(dialCode: '+966', nationalNumber: '512345678');

AuthRepositoryImpl _repo({
  AuthDataSource dataSource = const DummyAuthDataSource(),
  TokenStore? tokenStore,
}) =>
    AuthRepositoryImpl(
      dataSource: dataSource,
      tokenStore: tokenStore ?? InMemoryTokenStore(),
    );

void main() {
  test('requestOtp maps the model to a domain challenge carrying the phone',
      () async {
    final OtpChallenge challenge = await _repo().requestOtp(_phone);
    expect(challenge.phone, _phone);
    expect(challenge.attemptsRemaining, AuthDemoConfig.maxAttempts);
  });

  test('a correct code authenticates and persists the token', () async {
    final TokenStore store = InMemoryTokenStore();
    final AuthRepositoryImpl repo = _repo(tokenStore: store);
    final OtpChallenge challenge = await repo.requestOtp(_phone);

    final OtpVerification result =
        await repo.verifyOtp(challenge: challenge, code: AuthDemoConfig.acceptedCode);

    expect(result, isA<OtpAuthenticated>());
    expect(await store.readAccessToken(), isNotNull);
  });

  test('a wrong code returns rejected with the decremented challenge', () async {
    final AuthRepositoryImpl repo = _repo();
    final OtpChallenge challenge = await repo.requestOtp(_phone);

    final OtpVerification result =
        await repo.verifyOtp(challenge: challenge, code: '000000');

    expect(result, isA<OtpRejected>());
    expect((result as OtpRejected).challenge.attemptsRemaining, 2);
  });

  test('infrastructure errors from the data source surface as Failure',
      () async {
    final AuthRepositoryImpl repo = _repo(dataSource: _ThrowingDataSource());
    await expectLater(
      repo.requestOtp(_phone),
      throwsA(isA<Failure>().having((Failure f) => f.kind, 'kind',
          FailureKind.network)),
    );
  });

  test('completeProfile persists the completed session', () async {
    final TokenStore store = InMemoryTokenStore();
    final AuthRepositoryImpl repo = _repo(tokenStore: store);
    final OtpChallenge challenge = await repo.requestOtp(_phone);
    final OtpAuthenticated authed = await repo.verifyOtp(
      challenge: challenge,
      code: AuthDemoConfig.acceptedCode,
    ) as OtpAuthenticated;

    final updated = await repo.completeProfile(
      session: authed.session,
      fullName: 'Mahmoud Nabil',
      email: 'm@example.com',
    );

    expect(updated.isProfileComplete, isTrue);
    expect(updated.profile.phone, _phone);
  });

  test('signOut clears the token', () async {
    final TokenStore store = InMemoryTokenStore();
    await store.writeAccessToken('stale');
    await _repo(tokenStore: store).signOut();
    expect(await store.readAccessToken(), isNull);
  });

  test('signOut revokes the backend token before clearing it', () async {
    final TokenStore store = InMemoryTokenStore();
    await store.writeAccessToken('live');
    final _RevokeSpy spy = _RevokeSpy();
    await _repo(dataSource: spy, tokenStore: store).signOut();
    expect(spy.revoked, 1);
    expect(await store.readAccessToken(), isNull);
  });

  test('signOut still clears locally when the revoke call fails', () async {
    final TokenStore store = InMemoryTokenStore();
    await store.writeAccessToken('live');
    await expectLater(
      _repo(dataSource: _ThrowingDataSource(), tokenStore: store).signOut(),
      throwsA(isA<Failure>()),
    );
    expect(await store.readAccessToken(), isNull);
  });

  test('clearLocalSession never calls the backend', () async {
    final TokenStore store = InMemoryTokenStore();
    await store.writeAccessToken('rejected');
    final _RevokeSpy spy = _RevokeSpy();
    await _repo(dataSource: spy, tokenStore: store).clearLocalSession();
    expect(spy.revoked, 0);
    expect(await store.readAccessToken(), isNull);
  });

  test('restoreSession returns null on a cold start with an orphan token',
      () async {
    final TokenStore store = InMemoryTokenStore();
    await store.writeAccessToken('orphan');
    expect(await _repo(tokenStore: store).restoreSession(), isNull);
    expect(await store.readAccessToken(), isNull);
  });

  test('a fresh repository over the same store restores the signed-in guest '
      '(app closed and reopened)', () async {
    final TokenStore store = InMemoryTokenStore();
    final AuthRepositoryImpl firstRun = _repo(tokenStore: store);
    final OtpAuthenticated authed = await firstRun.verifyOtp(
      challenge: await firstRun.requestOtp(_phone),
      code: AuthDemoConfig.acceptedCode,
    ) as OtpAuthenticated;

    final AuthSession? restored = await _repo(tokenStore: store).restoreSession();

    expect(restored, isNotNull);
    expect(restored!.accessToken, authed.session.accessToken);
    expect(restored.profile.phone.e164, _phone.e164);
  });

  test('restoreSession keeps the token when the backend is unreachable',
      () async {
    final TokenStore store = InMemoryTokenStore();
    await store.writeAccessToken('dummy-token:${_phone.e164}');
    await expectLater(
      _repo(dataSource: _ThrowingDataSource(), tokenStore: store).restoreSession(),
      throwsA(isA<Failure>()),
    );
    expect(await store.readAccessToken(), isNotNull);
  });

  test('restoreSession keeps the guest signed in from the saved profile when '
      'the backend is unreachable (offline cold start)', () async {
    final TokenStore store = InMemoryTokenStore();
    final AuthRepositoryImpl firstRun = _repo(tokenStore: store);
    final OtpAuthenticated authed = await firstRun.verifyOtp(
      challenge: await firstRun.requestOtp(_phone),
      code: AuthDemoConfig.acceptedCode,
    ) as OtpAuthenticated;

    final AuthSession? restored = await _repo(
      dataSource: _ThrowingDataSource(),
      tokenStore: store,
    ).restoreSession();

    expect(restored, isNotNull);
    expect(restored!.accessToken, authed.session.accessToken);
    expect(restored.profile.phone.e164, _phone.e164);
  });

  test('signOut removes the saved profile with the token', () async {
    final TokenStore store = InMemoryTokenStore();
    final AuthRepositoryImpl repo = _repo(tokenStore: store);
    await repo.verifyOtp(
      challenge: await repo.requestOtp(_phone),
      code: AuthDemoConfig.acceptedCode,
    );
    expect(await store.readProfileSnapshot(), isNotNull);

    await repo.signOut();

    expect(await store.readAccessToken(), isNull);
    expect(await store.readProfileSnapshot(), isNull);
  });
}

class _ThrowingDataSource implements AuthDataSource {
  @override
  Future<AuthSessionModel?> fetchCurrentSession(String accessToken) async =>
      throw const NetworkException();

  @override
  Future<OtpChallengeModel> requestOtp(String phoneE164) async =>
      throw const NetworkException();

  @override
  Future<OtpChallengeModel> resendOtp({
    required String challengeId,
    required String phoneE164,
  }) async =>
      throw const NetworkException();

  @override
  Future<OtpVerifyResult> verifyOtp({
    required String challengeId,
    required String phoneE164,
    required int attemptsRemaining,
    required String code,
  }) async =>
      throw const NetworkException();

  @override
  Future<AuthSessionModel> completeProfile({
    required String accessToken,
    required String phoneE164,
    required String fullName,
    required String email,
  }) async =>
      throw const NetworkException();

  @override
  Future<void> revokeSession() async => throw const NetworkException();
}

class _RevokeSpy extends DummyAuthDataSource {
  _RevokeSpy();
  int revoked = 0;

  @override
  Future<void> revokeSession() async => revoked++;
}
