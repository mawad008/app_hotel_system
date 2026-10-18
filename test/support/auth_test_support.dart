import 'package:flutter_riverpod/misc.dart';
import 'package:hotel_guest_app/features/identity_verification/presentation/state/identity_verification_providers.dart';
import 'package:hotel_guest_app/core/config/app_config.dart';
import 'package:hotel_guest_app/core/di/core_providers.dart';
import 'package:hotel_guest_app/features/authentication/data/datasources/dummy_auth_data_source.dart';
import 'package:hotel_guest_app/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:hotel_guest_app/features/authentication/domain/entities/guest_phone.dart';
import 'package:hotel_guest_app/features/authentication/domain/entities/guest_profile.dart';
import 'package:hotel_guest_app/features/authentication/domain/entities/otp_challenge.dart';
import 'package:hotel_guest_app/features/authentication/domain/repositories/auth_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:hotel_guest_app/core/localization/locale_controller.dart';
import 'package:hotel_guest_app/features/authentication/presentation/state/auth_controller.dart';
import 'package:hotel_guest_app/features/authentication/presentation/state/language_selection_controller.dart';
import 'package:hotel_guest_app/features/authentication/presentation/state/login_flow_controller.dart';
import 'package:hotel_guest_app/core/security/in_memory_token_store.dart';

import 'fake_identity_camera.dart';
import 'test_config.dart';

const GuestPhone kTestPhone =
    GuestPhone(dialCode: '+966', nationalNumber: '512345678');

GuestProfile completeProfile() => const GuestProfile(
      phone: kTestPhone,
      fullName: 'Test Guest',
      email: 'test.guest@example.com',
    );

AuthSession completeSession() => AuthSession(
      accessToken: 'test-token',
      profile: completeProfile(),
    );

/// An [AuthRepository] backed by the real dummy stack for the flow methods, with
/// an overridable cold-start [restoreSession] so widget tests can boot straight
/// into an authenticated (or awaiting-profile) state.

class TestAuthRepository implements AuthRepository {
  TestAuthRepository({this.bootSession});

  final AuthRepositoryImpl _delegate = AuthRepositoryImpl(
    dataSource: const DummyAuthDataSource(),
    tokenStore: InMemoryTokenStore(),
  );

  AuthSession? bootSession;
  int signOutCount = 0;

  @override
  Future<AuthSession?> restoreSession() async => bootSession;

  @override
  Future<OtpChallenge> requestOtp(GuestPhone phone) =>
      _delegate.requestOtp(phone);

  @override
  Future<OtpChallenge> resendOtp(OtpChallenge challenge) =>
      _delegate.resendOtp(challenge);

  @override
  Future<OtpVerification> verifyOtp({
    required OtpChallenge challenge,
    required String code,
  }) =>
      _delegate.verifyOtp(challenge: challenge, code: code);

  @override
  Future<AuthSession> completeProfile({
    required AuthSession session,
    required String fullName,
    required String email,
  }) =>
      _delegate.completeProfile(
        session: session,
        fullName: fullName,
        email: email,
      );

  @override
  Future<void> signOut() async {
    signOutCount++;
    await _delegate.signOut();
  }

  @override
  Future<void> clearLocalSession() => _delegate.clearLocalSession();
}

/// A [LanguageSelectionController] seeded to a fixed value so tests can skip (or
/// exercise) the first-run language screen.
class SeededLanguageSelection extends LanguageSelectionController {
  SeededLanguageSelection({required this.chosen});

  final bool chosen;

  @override
  bool build() => chosen;
}

/// A [LocaleController] that starts on the device locale instead of the app's
/// Arabic default, so the test suite asserts against English copy unless a test
/// opts into Arabic (`pumpApp(locale: arabic)`).
class DeviceLocaleController extends LocaleController {
  @override
  Locale? build() => null;
}

/// Riverpod 3 rejects a provider overridden twice in one container, but tests
/// layer per-test overrides on top of [authOverrides]: the last one wins.
List<Override> mergeOverrides(Iterable<Override> overrides) {
  final Map<Object, Override> byOrigin = <Object, Override>{};
  for (final Override override in overrides) {
    byOrigin.remove(override.origin);
    byOrigin[override.origin] = override;
  }
  return byOrigin.values.toList();
}

/// Base overrides for an authentication test: deterministic config + a
/// [TestAuthRepository]. Pass a [bootSession] to start signed in.
///
/// [languageChosen] defaults to `true` so tests boot straight past the first-run
/// language screen onto the entry / auth / app surface; set it `false` to land
/// on `/welcome/language`.
List<Override> authOverrides({
  AppConfig config = testConfig,
  AuthSession? bootSession,
  Duration resendCooldown = Duration.zero,
  bool languageChosen = true,
}) {
  return <Override>[
    appConfigProvider.overrideWithValue(config),
    authRepositoryProvider.overrideWithValue(
      TestAuthRepository(bootSession: bootSession),
    ),
    otpResendCooldownProvider.overrideWithValue(resendCooldown),
    splashMinDurationProvider.overrideWithValue(Duration.zero),
    localeControllerProvider.overrideWith(DeviceLocaleController.new),
    languageSelectedProvider.overrideWith(
      () => SeededLanguageSelection(chosen: languageChosen),
    ),
    // There is no device camera in `flutter test`.
    identityCameraProvider.overrideWithValue(FakeIdentityCamera()),
  ];
}
