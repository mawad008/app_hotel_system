import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/errors/app_exception.dart';
import 'package:hotel_guest_app/features/identity_verification/data/datasources/dummy_identity_verification_data_source.dart';
import 'package:hotel_guest_app/features/identity_verification/data/repositories/identity_verification_repository_impl.dart';
import 'package:hotel_guest_app/features/identity_verification/domain/entities/identity_document.dart';
import 'package:hotel_guest_app/features/identity_verification/domain/entities/identity_verification_status.dart';
import 'package:hotel_guest_app/features/identity_verification/presentation/state/identity_verification_controller.dart';
import 'package:hotel_guest_app/features/identity_verification/presentation/state/identity_verification_providers.dart';

import 'identity_test_support.dart';

Future<void> _settle() async {
  for (int i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

ProviderContainer _container(DummyIdentityVerificationDataSource ds) {
  final c = ProviderContainer(overrides: <Override>[
    identityVerificationRepositoryProvider
        .overrideWithValue(IdentityVerificationRepositoryImpl(ds)),
  ]);
  addTearDown(c.dispose);
  return c;
}

DummyIdentityVerificationDataSource _ds() =>
    DummyIdentityVerificationDataSource(clock: () => DateTime(2026, 9, 8));

Future<void> _drive(
  ProviderContainer c,
  String id, {
  int selfies = 1,
}) async {
  final n =
      c.read(identityVerificationControllerProvider(id).notifier);
  await _settle();
  for (int i = 0; i < selfies; i++) {
    await n.submitDocument(IdentityDocumentType.passport, image: CapturedImage.dummy);
    await n.submitSelfie(image: CapturedImage.dummy);
  }
}

void main() {
  test('loads the initial NOT_STARTED session', () async {
    final id = reservationIdForScenario(DummyVerificationScenario.autoApprove);
    final c = _container(_ds());
    c.listen(identityVerificationControllerProvider(id), (_, _) {});
    expect(c.read(identityVerificationControllerProvider(id)).phase,
        IdentityFlowPhase.loading);
    await _settle();
    final s = c.read(identityVerificationControllerProvider(id));
    expect(s.phase, IdentityFlowPhase.ready);
    expect(s.session!.status, IdentityVerificationStatus.notStarted);
  });

  test('document → selfie → AUTO_APPROVED', () async {
    final id = reservationIdForScenario(DummyVerificationScenario.autoApprove);
    final c = _container(_ds());
    await _drive(c, id);
    final s = c.read(identityVerificationControllerProvider(id));
    expect(s.session!.isApproved, isTrue);
    expect(s.phase, IdentityFlowPhase.ready);
  });

  test('manual-review scenario resolves to PENDING_MANUAL_REVIEW', () async {
    final id = reservationIdForScenario(DummyVerificationScenario.manualReview);
    final c = _container(_ds());
    await _drive(c, id);
    expect(c.read(identityVerificationControllerProvider(id)).session!.status,
        IdentityVerificationStatus.pendingManualReview);
  });

  test('retry scenario: RETRY_ALLOWED then a fresh attempt approves', () async {
    final id =
        reservationIdForScenario(DummyVerificationScenario.retryThenApprove);
    final c = _container(_ds());
    await _drive(c, id);
    expect(c.read(identityVerificationControllerProvider(id)).session!.status,
        IdentityVerificationStatus.retryAllowed);
    // A retry is a fresh document + selfie from the retryable state.
    await _drive(c, id);
    expect(c.read(identityVerificationControllerProvider(id)).session!.isApproved,
        isTrue);
  });

  test('rejected scenario shows a retryable STAFF_REJECTED', () async {
    final id =
        reservationIdForScenario(DummyVerificationScenario.rejectThenReview);
    final c = _container(_ds());
    await _drive(c, id);
    final s = c.read(identityVerificationControllerProvider(id)).session!;
    expect(s.status, IdentityVerificationStatus.staffRejected);
    expect(s.canRetry, isTrue);
  });

  test('an infrastructure failure is surfaced; a retry recovers', () async {
    final id = reservationIdForScenario(DummyVerificationScenario.autoApprove);
    final ds = _ds();
    final c = _container(ds);
    final n = c.read(identityVerificationControllerProvider(id).notifier);
    await _settle();

    ds.failWith = const NetworkException();
    await n.submitDocument(IdentityDocumentType.passport, image: CapturedImage.dummy);
    expect(c.read(identityVerificationControllerProvider(id)).hasFailure, isTrue);

    ds.failWith = null;
    await n.submitDocument(IdentityDocumentType.passport, image: CapturedImage.dummy);
    await n.submitSelfie(image: CapturedImage.dummy);
    expect(c.read(identityVerificationControllerProvider(id)).session!.isApproved,
        isTrue);
  });

  test('a duplicate submit while one is in flight is a no-op', () async {
    final id = reservationIdForScenario(DummyVerificationScenario.autoApprove);
    final c = _container(_ds());
    final n = c.read(identityVerificationControllerProvider(id).notifier);
    await _settle();

    final f = n.submitDocument(IdentityDocumentType.passport, image: CapturedImage.dummy);
    await n.submitDocument(IdentityDocumentType.egyptianNationalId, image: CapturedImage.dummy); // ignored
    await f;
    await n.submitSelfie(image: CapturedImage.dummy);
    final s = c.read(identityVerificationControllerProvider(id)).session!;
    expect(s.isApproved, isTrue);
    expect(s.attempts, 1);
  });

  test('sessions for different reservations never cross over', () async {
    final a = reservationIdForScenario(DummyVerificationScenario.autoApprove);
    final b = reservationIdForScenario(DummyVerificationScenario.manualReview);
    final c = _container(_ds());
    await _drive(c, a);
    await _drive(c, b);
    expect(c.read(identityVerificationControllerProvider(a)).session!.isApproved,
        isTrue);
    expect(c.read(identityVerificationControllerProvider(b)).session!.status,
        IdentityVerificationStatus.pendingManualReview);
  });
}
