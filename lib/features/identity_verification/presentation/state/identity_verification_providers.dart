import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/presentation/cache_for.dart';
import '../../../../core/time/clock.dart';
import '../../data/datasources/api_identity_verification_data_source.dart';
import '../../data/datasources/dummy_identity_verification_data_source.dart';
import '../../data/datasources/identity_verification_data_source.dart';
import '../../data/device/identity_camera.dart';
import '../../data/device/live_identity_camera.dart';
import '../../data/repositories/identity_verification_repository_impl.dart';
import '../../domain/entities/identity_document.dart';
import '../../domain/entities/identity_verification_session.dart';
import '../../domain/repositories/identity_verification_repository.dart';

/// Selects the identity-verification data source by configuration — the UI
/// never sees this choice, mirroring `reservationDataSourceProvider`.
///
/// The dummy source is kept alive for the whole app session so a session
/// advanced here can be re-read by the result / reservation screens.
final identityVerificationDataSourceProvider =
    Provider<IdentityVerificationDataSource>((Ref ref) {
  final AppConfig config = ref.watch(appConfigProvider);
  return config.useDummyData
      ? DummyIdentityVerificationDataSource(clock: ref.watch(clockProvider))
      : ApiIdentityVerificationDataSource(ref.watch(apiClientProvider));
});

final identityVerificationRepositoryProvider =
    Provider<IdentityVerificationRepository>(
  (Ref ref) => IdentityVerificationRepositoryImpl(
    ref.watch(identityVerificationDataSourceProvider),
  ),
);

/// The current identity-verification session for a reservation — for the
/// booking-detail screen's status timeline. `autoDispose` so leaving the
/// screen drops the fetch.
final identityStatusProvider = FutureProvider.autoDispose
    .family<IdentityVerificationSession, String>((Ref ref, String reservationId) {
  return ref.watch(identityVerificationRepositoryProvider).statusFor(reservationId);
});

/// The document types the guest can pick (and their front/back rule), from
/// the server. Falls back to the built-in defaults when the catalog can't be
/// loaded, so the flow never dead-ends — the server re-validates the upload.
final identityDocumentOptionsProvider =
    FutureProvider.autoDispose<List<IdentityDocumentOption>>((Ref ref) async {
  ref.cacheFor(CacheDurations.reference);
  try {
    final List<IdentityDocumentOption> options =
        await ref.watch(identityVerificationRepositoryProvider).documentTypes();
    return options.isEmpty ? IdentityDocumentOption.defaults : options;
  } catch (_) {
    return IdentityDocumentOption.defaults;
  }
});

/// The device camera used to take the ID photo and the selfie — a live
/// viewfinder where supported ([LiveIdentityCamera]). Overridden with a fake
/// in tests (there is no camera in `flutter test`).
final identityCameraProvider = Provider<IdentityCamera>(
  (Ref ref) => DeviceIdentityCamera(),
);
