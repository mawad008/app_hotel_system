import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/app/router/app_router.dart';
import 'package:hotel_guest_app/core/localization/generated/app_localizations.dart';
import 'package:hotel_guest_app/core/errors/app_exception.dart';
import 'package:hotel_guest_app/core/storage/app_preferences.dart';
import 'package:hotel_guest_app/features/identity_verification/data/datasources/dummy_identity_verification_data_source.dart';
import 'package:hotel_guest_app/features/identity_verification/data/datasources/identity_verification_data_source.dart';
import 'package:hotel_guest_app/features/identity_verification/data/models/identity_verification_models.dart';
import 'package:hotel_guest_app/features/identity_verification/domain/entities/identity_verification_request.dart';
import 'package:hotel_guest_app/features/identity_verification/data/device/identity_camera.dart';
import 'package:hotel_guest_app/features/identity_verification/data/device/live_identity_camera.dart';
import 'package:hotel_guest_app/features/identity_verification/domain/entities/identity_document.dart';
import 'package:hotel_guest_app/features/identity_verification/domain/entities/identity_document_check.dart';
import 'package:hotel_guest_app/features/identity_verification/domain/entities/identity_verification_session.dart';
import 'package:hotel_guest_app/features/identity_verification/domain/entities/identity_verification_status.dart';
import 'package:hotel_guest_app/features/identity_verification/presentation/state/identity_verification_providers.dart';
import 'package:hotel_guest_app/features/identity_verification/presentation/state/pending_identity_capture.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/create_reservation_request.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/extend_stay.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation_status.dart';
import 'package:hotel_guest_app/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:hotel_guest_app/features/reservation/presentation/state/reservation_providers.dart';

import '../../support/auth_test_support.dart';
import '../../support/fake_identity_camera.dart';
import '../../support/pump_app.dart';
import '../payment/payment_test_support.dart' show fakeReservation;
import 'identity_test_support.dart';

class _StubReservationRepository implements ReservationRepository {
  @override
  Future<Reservation> create(CreateReservationRequest request) async =>
      fakeReservation(status: ReservationStatus.depositHeld);
  @override
  Future<Reservation> getById(String id) async =>
      fakeReservation(id: id, status: ReservationStatus.depositHeld);
  @override
  Future<List<Reservation>> list() async => <Reservation>[];

  @override
  Future<Reservation> cancel(String id) async => fakeReservation(id: id);

  @override
  Future<ExtendStayResult> extend(ExtendStayRequest request) async {
    throw UnimplementedError('extend not used in this test');
  }
}


/// Records every document request (to assert front/back and the claim).
class _RecordingSource extends DummyIdentityVerificationDataSource {
  final List<SubmitIdentityDocumentRequest> requests = <SubmitIdentityDocumentRequest>[];

  @override
  Future<IdentityVerificationSessionModel> submitDocument(
    SubmitIdentityDocumentRequest request, {
    UploadProgress? onProgress,
  }) {
    requests.add(request);
    return super.submitDocument(request, onProgress: onProgress);
  }
}

/// The backend's document-only mode: no details, the photo approves at once.
class _DocumentOnlySource extends DummyIdentityVerificationDataSource {
  final List<SubmitIdentityDocumentRequest> requests = <SubmitIdentityDocumentRequest>[];

  @override
  Future<List<IdentityDocumentOption>> documentTypes() async => <IdentityDocumentOption>[
        for (final IdentityDocumentOption o in IdentityDocumentOption.defaults)
          IdentityDocumentOption(type: o.type, back: o.back, automaticCheck: true, detailsRequired: false),
      ];

  @override
  Future<IdentityVerificationSessionModel> submitDocument(
    SubmitIdentityDocumentRequest request, {
    UploadProgress? onProgress,
  }) async {
    requests.add(request);
    return IdentityVerificationSessionModel(
      reservationId: request.reservationId,
      status: IdentityVerificationStatus.autoApproved,
      attempts: 1,
      latestOutcome: IdentityMatchOutcome.fromWire(null),
    );
  }
}

/// Holds the upload open so the progress / "reading" states can be seen.
class _GatedSource extends DummyIdentityVerificationDataSource {
  final Completer<void> sent = Completer<void>();
  final Completer<void> read = Completer<void>();

  @override
  Future<IdentityVerificationSessionModel> submitDocument(
    SubmitIdentityDocumentRequest request, {
    UploadProgress? onProgress,
  }) async {
    onProgress?.call(0.4);
    await sent.future;
    onProgress?.call(1);
    await read.future;
    return super.submitDocument(request, onProgress: null);
  }
}

/// A live viewfinder that is "ready" at once (or fails with [failWith]).
class _FakeViewfinder extends IdentityViewfinder {
  _FakeViewfinder(this.target, this.failWith);

  final IdentityCaptureTarget target;
  final IdentityCameraUnavailable? failWith;

  /// Back to "opening" — as after the permission prompt or a trip to the
  /// background — without a rebuild, so the preview is still on screen.
  void reopenSilently() => _status = IdentityViewfinderStatus.initializing;
  IdentityViewfinderStatus _status = IdentityViewfinderStatus.initializing;
  int shots = 0;
  bool disposed = false;

  @override
  IdentityViewfinderStatus get status => _status;

  @override
  IdentityCameraUnavailable? get problem => failWith;

  @override
  Future<void> start() async {
    _status = failWith == null ? IdentityViewfinderStatus.ready : IdentityViewfinderStatus.unavailable;
    notifyListeners();
  }

  @override
  Future<void> pause() async {}

  @override
  Widget buildPreview() => ColoredBox(key: ValueKey('fake-live-${target.name}'), color: Colors.teal);

  @override
  Future<IdentityCaptureResult> takePicture() async {
    shots++;
    return const IdentityCaptured(CapturedImage.dummy);
  }

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}

/// A device camera with a live viewfinder; its one-shot [capture] is the
/// image_picker fallback (recorded by [FakeIdentityCamera]).
class _FakeLiveCamera extends FakeIdentityCamera implements LiveIdentityCamera {
  _FakeLiveCamera({this.failWith});

  final IdentityCameraUnavailable? failWith;
  final List<_FakeViewfinder> opened = <_FakeViewfinder>[];

  @override
  bool get supportsLiveViewfinder => true;

  @override
  IdentityViewfinder openViewfinder(IdentityCaptureTarget target) {
    final _FakeViewfinder v = _FakeViewfinder(target, failWith);
    opened.add(v);
    return v;
  }
}

const Key _shutterButton = ValueKey('identityShutterButton');

Future<AppLocalizations> _l10n(String code) =>
    AppLocalizations.delegate.load(Locale(code));

Future<void> _open(
  WidgetTester tester,
  String id, {
  Locale? locale,
  FakeIdentityCamera? camera,
  DummyIdentityVerificationDataSource? source,
}) async {
  final c = await pumpApp(
    tester,
    bootSession: completeSession(),
    locale: locale,
    extraOverrides: <Override>[
      reservationRepositoryProvider
          .overrideWithValue(_StubReservationRepository()),
      if (camera != null) identityCameraProvider.overrideWithValue(camera),
      if (source != null)
        identityVerificationDataSourceProvider.overrideWithValue(source),
    ],
  );
  c.read(appRouterProvider).go('/reservation/$id/identity');
  await tester.pumpAndSettle();
}

/// Capture (tap the shutter) + confirm the ID review step — the two taps that
/// call `submitDocument`.
Future<void> _captureAndSubmitDocument(WidgetTester tester, AppLocalizations l10n) async {
  await tester.tap(find.byKey(_shutterButton));
  await tester.pumpAndSettle();
  // Card types ask for the back as a second shot.
  if (find.text(l10n.identityCaptureBackTitle).evaluate().isNotEmpty) {
    await tester.tap(find.byKey(_shutterButton));
    await tester.pumpAndSettle();
  }
  await tester
      .tap(find.widgetWithText(FilledButton, l10n.identityReviewContinueCta));
  await tester.pumpAndSettle();
  // "Document accepted" / "manual review" → continue to the selfie.
  if (find.text(l10n.identityDocumentAcceptedTitle).evaluate().isNotEmpty ||
      find.text(l10n.identityDocumentReviewTitle).evaluate().isNotEmpty) {
    await tester
        .tap(find.widgetWithText(FilledButton, l10n.identityReviewContinueCta));
    await tester.pumpAndSettle();
  }
}

/// The selfie step submits on capture — no separate review step.
Future<void> _captureSelfie(WidgetTester tester) async {
  await tester.tap(find.byKey(_shutterButton));
  await tester.pumpAndSettle();
}

/// Intro → ID details form (filled and confirmed) → document capture.
Future<void> _dismissIntro(WidgetTester tester, AppLocalizations l10n) async {
  await tester.tap(find.widgetWithText(FilledButton, l10n.identityIntroCta));
  await tester.pumpAndSettle();
  await _fillDetails(tester, l10n);
}

/// Fills the ID details form with SYNTHETIC values and continues.
Future<void> _fillDetails(WidgetTester tester, AppLocalizations l10n,
    {IdentityDocumentType type = IdentityDocumentType.passport, String? number}) async {
  expect(find.text(l10n.identityDetailsTitle), findsOneWidget);
  await tester.tap(find.byKey(ValueKey('idv-type-${type.wireValue}')));
  await tester.pumpAndSettle();
  number ??= switch (type) {
    IdentityDocumentType.egyptianNationalId => '٢٩٠٠١١٥٠١١٢٣٥٧',
    IdentityDocumentType.saudiNationalId => '1098765432',
    IdentityDocumentType.saudiIqama => '2098765432',
    IdentityDocumentType.passport => 'L898902C3',
  };
  await tester.enterText(
      find.descendant(of: find.byKey(const ValueKey('idv-name')), matching: find.byType(TextField)),
      'Anna Maria Eriksson');
  await tester.enterText(
      find.descendant(of: find.byKey(const ValueKey('idv-number')), matching: find.byType(TextField)),
      number);
  if (!type.birthDateInNumber) {
    await tester.tap(find.byKey(const ValueKey('idv-dob')));
    await tester.pumpAndSettle();
    final String ok = MaterialLocalizations.of(tester.element(find.byType(DatePickerDialog))).okButtonLabel;
    await tester.tap(find.text(ok));
    await tester.pumpAndSettle();
  } else {
    expect(find.byKey(const ValueKey('idv-dob')), findsNothing);
    expect(find.text(l10n.identityBirthDateFromNumber), findsOneWidget);
  }
  await _continueDetails(tester);
}

Future<void> _continueDetails(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('idv-details-continue')));
  await tester.pumpAndSettle();
}

Future<void> _submitDocumentAndSelfie(
  WidgetTester tester,
  AppLocalizations l10n,
) async {
  await _dismissIntro(tester, l10n);
  await _captureAndSubmitDocument(tester, l10n);
  await _captureSelfie(tester);
}

void main() {
  testWidgets('document → selfie → processing → verified → reservation (EN)',
      (WidgetTester tester) async {
    final en = await _l10n('en');
    final id = reservationIdForScenario(DummyVerificationScenario.autoApprove);
    await _open(tester, id);

    expect(find.text(en.identityIntroBannerTitle), findsOneWidget);
    await _submitDocumentAndSelfie(tester, en);

    expect(find.text(en.identityApprovedTitle), findsOneWidget);
    await tester.tap(
      find.widgetWithText(OutlinedButton, en.identityBackToReservation),
    );
    await tester.pumpAndSettle();
    expect(find.text(en.bookingDetailTitle), findsWidgets);
  });

  testWidgets('the ID uses the rear camera and the selfie the front one',
      (WidgetTester tester) async {
    final en = await _l10n('en');
    final FakeIdentityCamera camera = FakeIdentityCamera();
    await _open(
      tester,
      reservationIdForScenario(DummyVerificationScenario.autoApprove),
      camera: camera,
    );
    await _submitDocumentAndSelfie(tester, en);
    expect(camera.captures, <IdentityCaptureTarget>[
      IdentityCaptureTarget.document,
      IdentityCaptureTarget.selfie,
    ]);
  });

  testWidgets('closing the camera without a photo stays on the capture step',
      (WidgetTester tester) async {
    final en = await _l10n('en');
    final FakeIdentityCamera camera =
        FakeIdentityCamera(result: const IdentityCaptureCancelled());
    await _open(
      tester,
      reservationIdForScenario(DummyVerificationScenario.autoApprove),
      camera: camera,
    );
    await _dismissIntro(tester, en);
    await tester.tap(find.byKey(_shutterButton));
    await tester.pumpAndSettle();

    expect(find.text(en.identityCaptureDocumentTitle), findsOneWidget);
    expect(find.text(en.identityReviewDocumentTitle), findsNothing);
  });

  testWidgets('a denied camera permission shows the open-settings screen',
      (WidgetTester tester) async {
    final en = await _l10n('en');
    final FakeIdentityCamera camera = FakeIdentityCamera(
      result: const IdentityCameraUnavailable(permissionDenied: true),
    );
    await _open(
      tester,
      reservationIdForScenario(DummyVerificationScenario.autoApprove),
      camera: camera,
    );
    await _dismissIntro(tester, en);
    await tester.tap(find.byKey(_shutterButton));
    await tester.pumpAndSettle();

    expect(find.text(en.identityCameraDeniedTitle), findsOneWidget);
    expect(find.widgetWithText(FilledButton, en.identityOpenSettingsCta), findsOneWidget);

    // "Back" returns to the capture screen.
    await tester.tap(find.widgetWithText(OutlinedButton, en.commonBack));
    await tester.pumpAndSettle();
    expect(find.text(en.identityCaptureDocumentTitle), findsOneWidget);
  });

  testWidgets('manual-review scenario shows the safe waiting state',
      (tester) async {
    final en = await _l10n('en');
    final id = reservationIdForScenario(DummyVerificationScenario.manualReview);
    await _open(tester, id);
    await _submitDocumentAndSelfie(tester, en);
    expect(find.text(en.identityManualReviewTitle), findsOneWidget);
  });

  testWidgets('retry scenario (face not matched) shows a retry CTA and recovers',
      (tester) async {
    final en = await _l10n('en');
    final id =
        reservationIdForScenario(DummyVerificationScenario.retryThenApprove);
    await _open(tester, id);
    await _submitDocumentAndSelfie(tester, en);

    // Back on a retry-eligible failure screen — no intro shown again.
    expect(find.text(en.identityFaceNotMatchedBannerTitle), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, en.identityRetryCta));
    await tester.pumpAndSettle();

    // The details are kept from the first attempt — just confirm them.
    await _continueDetails(tester);
    await _captureAndSubmitDocument(tester, en);
    await _captureSelfie(tester);
    expect(find.text(en.identityApprovedTitle), findsOneWidget);
  });

  testWidgets(
      'retry scenario (document unclear) shows the distinct failure screen',
      (tester) async {
    final en = await _l10n('en');
    final id = reservationIdForScenario(
      DummyVerificationScenario.retryUnclearThenApprove,
    );
    await _open(tester, id);
    await _submitDocumentAndSelfie(tester, en);

    expect(find.text(en.identityDocumentUnclearBannerTitle), findsOneWidget);
    // Never confused with the face-mismatch copy.
    expect(find.text(en.identityFaceNotMatchedBannerTitle), findsNothing);
  });

  testWidgets('rejected scenario shows a safe rejection with retry',
      (tester) async {
    final en = await _l10n('en');
    final id =
        reservationIdForScenario(DummyVerificationScenario.rejectThenReview);
    await _open(tester, id);
    await _submitDocumentAndSelfie(tester, en);
    expect(find.text(en.identityRejectedTitle), findsWidgets);
    // No provider/internal detail leaked.
    expect(find.textContaining('score'), findsNothing);
  });

  testWidgets('the flow renders right-to-left in Arabic', (tester) async {
    final ar = await _l10n('ar');
    final id = reservationIdForScenario(DummyVerificationScenario.autoApprove);
    await _open(tester, id, locale: arabic);

    expect(
      Directionality.of(
          tester.element(find.text(ar.identityIntroBannerTitle))),
      TextDirection.rtl,
    );
    await _submitDocumentAndSelfie(tester, ar);
    expect(find.text(ar.identityApprovedTitle), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text(ar.identityApprovedTitle))),
      TextDirection.rtl,
    );
  });

  testWidgets('the details form requires name, number and date of birth',
      (tester) async {
    final en = await _l10n('en');
    await _open(tester, reservationIdForScenario(DummyVerificationScenario.autoApprove));
    await tester.tap(find.widgetWithText(FilledButton, en.identityIntroCta));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.descendant(of: find.byKey(const ValueKey('idv-name')), matching: find.byType(TextField)), '');
    await _continueDetails(tester);

    expect(find.text(en.identityDetailsTitle), findsOneWidget);
    expect(find.text(en.identityFieldRequired), findsWidgets);
    expect(find.text(en.identityCaptureDocumentTitle), findsNothing);
  });

  testWidgets('document-only mode: pick the type, photograph the ID, verified — no details, no selfie',
      (tester) async {
    final en = await _l10n('en');
    final source = _DocumentOnlySource();
    await _open(tester, reservationIdForScenario(DummyVerificationScenario.autoApprove),
        camera: FakeIdentityCamera(), source: source);

    expect(find.text(en.identityIntroBannerBodyDocumentOnly), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, en.identityIntroCta));
    await tester.pumpAndSettle();

    expect(find.text(en.identityDocumentOnlyBody), findsOneWidget);
    expect(find.byKey(const ValueKey('idv-name')), findsNothing);
    expect(find.byKey(const ValueKey('idv-number')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('idv-type-passport')));
    await tester.pumpAndSettle();
    await _continueDetails(tester);

    await _captureAndSubmitDocument(tester, en);

    expect(source.requests, hasLength(1));
    expect(source.requests.single.claim, isNull);
    expect(find.text(en.identityCaptureSelfieHint), findsNothing);
    expect(find.text(en.identityApprovedTitle), findsWidgets);
  });

  testWidgets('a details mismatch explains what to check; editing re-uploads the kept photo',
      (tester) async {
    final en = await _l10n('en');
    final source = DummyIdentityVerificationDataSource()
      ..nextDocumentCheck = DocumentCheckStatus.mismatch;
    final FakeIdentityCamera camera = FakeIdentityCamera();
    await _open(tester, reservationIdForScenario(DummyVerificationScenario.autoApprove),
        source: source, camera: camera);
    await _dismissIntro(tester, en);
    await _captureAndSubmitDocument(tester, en);

    expect(find.text(en.identityMismatchTitle), findsOneWidget);
    expect(find.text(en.identityMismatchFieldsBody(en.identityFieldDocumentNumber)), findsOneWidget);
    expect(find.text(en.identityCaptureSelfieHint), findsNothing, reason: 'no selfie while rejected');
    // Never a dead end: reception can finish the check by hand.
    expect(find.text(en.identityStuckContactReception), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, en.identityEditDetailsCta));
    await tester.pumpAndSettle();
    // The contradicted field is flagged on the form.
    expect(find.text(en.identityMismatchTitle), findsOneWidget);
    await _continueDetails(tester);

    // Photo kept → straight to review, no second camera capture.
    expect(find.text(en.identityReviewDocumentTitle), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, en.identityReviewContinueCta));
    await tester.pumpAndSettle();
    expect(find.text(en.identityDocumentAcceptedTitle), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, en.identityReviewContinueCta));
    await tester.pumpAndSettle();
    await _captureSelfie(tester);

    expect(find.text(en.identityApprovedTitle), findsOneWidget);
    expect(camera.captures, <IdentityCaptureTarget>[
      IdentityCaptureTarget.document,
      IdentityCaptureTarget.selfie,
    ]);
  });

  testWidgets('an expired document asks for another document', (tester) async {
    final en = await _l10n('en');
    final source = DummyIdentityVerificationDataSource()
      ..nextDocumentCheck = DocumentCheckStatus.documentExpired;
    await _open(tester, reservationIdForScenario(DummyVerificationScenario.autoApprove), source: source);
    await _dismissIntro(tester, en);
    await _captureAndSubmitDocument(tester, en);

    expect(find.text(en.identityExpiredTitle), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, en.identityUseAnotherDocumentCta));
    await tester.pumpAndSettle();
    expect(find.text(en.identityDetailsTitle), findsOneWidget);
  });

  testWidgets('an unreadable document offers a retake', (tester) async {
    final en = await _l10n('en');
    final source = DummyIdentityVerificationDataSource()
      ..nextDocumentCheck = DocumentCheckStatus.ocrFailed;
    await _open(tester, reservationIdForScenario(DummyVerificationScenario.autoApprove), source: source);
    await _dismissIntro(tester, en);
    await _captureAndSubmitDocument(tester, en);

    expect(find.text(en.identityDocumentUnclearBannerTitle), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, en.identityReviewRetakeCta));
    await tester.pumpAndSettle();
    expect(find.text(en.identityCaptureDocumentTitle), findsOneWidget);
  });

  testWidgets('an unsupported document names the accepted ones', (tester) async {
    final en = await _l10n('en');
    final source = DummyIdentityVerificationDataSource()
      ..nextDocumentCheck = DocumentCheckStatus.documentUnsupported;
    await _open(tester, reservationIdForScenario(DummyVerificationScenario.autoApprove), source: source);
    await _dismissIntro(tester, en);
    await _captureAndSubmitDocument(tester, en);

    expect(find.text(en.identityUnsupportedTitle), findsOneWidget);
    expect(find.text(en.identityUnsupportedBody), findsOneWidget);
  });

  testWidgets('Egyptian ID (Arabic, RTL): no birth-date field, front + back uploaded, accepted, verified',
      (tester) async {
    final ar = await _l10n('ar');
    final source = _RecordingSource();
    final camera = FakeIdentityCamera();
    await _open(tester, reservationIdForScenario(DummyVerificationScenario.autoApprove),
        locale: arabic, source: source, camera: camera);
    await tester.tap(find.widgetWithText(FilledButton, ar.identityIntroCta));
    await tester.pumpAndSettle();

    // The type explains which sides are needed.
    await tester.tap(find.byKey(const ValueKey('idv-type-egyptian_national_id')));
    await tester.pumpAndSettle();
    expect(find.textContaining(ar.identityDocumentSidesFrontAndBack), findsOneWidget);
    expect(Directionality.of(tester.element(find.text(ar.identityDetailsTitle))), TextDirection.rtl);

    await _fillDetails(tester, ar, type: IdentityDocumentType.egyptianNationalId);
    await tester.tap(find.byKey(_shutterButton));
    await tester.pumpAndSettle();
    expect(find.text(ar.identityCaptureBackTitle), findsOneWidget);
    expect(find.byKey(const ValueKey('idv-skip-back')), findsNothing, reason: 'back is required');
    await tester.tap(find.byKey(_shutterButton));
    await tester.pumpAndSettle();
    expect(find.text(ar.identityReviewBothSides), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, ar.identityReviewContinueCta));
    await tester.pumpAndSettle();

    expect(find.text(ar.identityDocumentAcceptedTitle), findsOneWidget);
    final req = source.requests.single;
    expect(req.type, IdentityDocumentType.egyptianNationalId);
    expect(req.backImage, isNotNull);
    expect(req.claim!.dateOfBirth, isNull);
    expect(req.claim!.toFields()['document_number'], '29001150112357', reason: 'Western digits on the wire');

    await tester.tap(find.widgetWithText(FilledButton, ar.identityReviewContinueCta));
    await tester.pumpAndSettle();
    await _captureSelfie(tester);
    expect(find.text(ar.identityApprovedTitle), findsOneWidget);
    expect(camera.captures, <IdentityCaptureTarget>[
      IdentityCaptureTarget.document,
      IdentityCaptureTarget.document,
      IdentityCaptureTarget.selfie,
    ]);
  });

  testWidgets('Saudi Iqama: the back is optional and can be skipped', (tester) async {
    final en = await _l10n('en');
    final source = _RecordingSource();
    await _open(tester, reservationIdForScenario(DummyVerificationScenario.autoApprove), source: source);
    await tester.tap(find.widgetWithText(FilledButton, en.identityIntroCta));
    await tester.pumpAndSettle();
    await _fillDetails(tester, en, type: IdentityDocumentType.saudiIqama);

    await tester.tap(find.byKey(_shutterButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('idv-skip-back')));
    await tester.pumpAndSettle();
    expect(find.text(en.identityReviewDocumentBody), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, en.identityReviewContinueCta));
    await tester.pumpAndSettle();

    expect(source.requests.single.type, IdentityDocumentType.saudiIqama);
    expect(source.requests.single.backImage, isNull);
    expect(source.requests.single.claim!.dateOfBirth, isNotNull);
  });

  testWidgets('a passport goes straight from the front photo to review', (tester) async {
    final en = await _l10n('en');
    await _open(tester, reservationIdForScenario(DummyVerificationScenario.autoApprove));
    await _dismissIntro(tester, en);
    await tester.tap(find.byKey(_shutterButton));
    await tester.pumpAndSettle();

    expect(find.text(en.identityCaptureBackTitle), findsNothing);
    expect(find.text(en.identityReviewDocumentTitle), findsOneWidget);
  });

  testWidgets('number format is validated per document type', (tester) async {
    final en = await _l10n('en');
    await _open(tester, reservationIdForScenario(DummyVerificationScenario.autoApprove));
    await tester.tap(find.widgetWithText(FilledButton, en.identityIntroCta));
    await tester.pumpAndSettle();

    Future<void> tryNumber(String type, String number) async {
      await tester.tap(find.byKey(ValueKey('idv-type-$type')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.descendant(of: find.byKey(const ValueKey('idv-name')), matching: find.byType(TextField)), 'Test Name');
      await tester.enterText(
          find.descendant(of: find.byKey(const ValueKey('idv-number')), matching: find.byType(TextField)), number);
      await _continueDetails(tester);
    }

    await tryNumber('egyptian_national_id', '12345678901234'); // century 1
    expect(find.text(en.identityDocumentNumberInvalidForType), findsOneWidget);
    await tryNumber('saudi_national_id', '2098765432'); // Iqama prefix
    expect(find.text(en.identityDocumentNumberInvalidForType), findsOneWidget);
    expect(find.text(en.identityCaptureDocumentTitle), findsNothing);
  });

  testWidgets('a document sent to manual review says so before the selfie', (tester) async {
    final en = await _l10n('en');
    final source = DummyIdentityVerificationDataSource()
      ..nextDocumentCheck = DocumentCheckStatus.needsReview;
    await _open(tester, reservationIdForScenario(DummyVerificationScenario.manualReview), source: source);
    await _dismissIntro(tester, en);
    await tester.tap(find.byKey(_shutterButton));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, en.identityReviewContinueCta));
    await tester.pumpAndSettle();

    expect(find.text(en.identityDocumentReviewTitle), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, en.identityReviewContinueCta));
    await tester.pumpAndSettle();
    expect(find.text(en.identityCaptureSelfieTitle), findsOneWidget);
  });

  testWidgets('upload progress, then "reading your ID" while the server checks it', (tester) async {
    final en = await _l10n('en');
    final source = _GatedSource();
    await _open(tester, reservationIdForScenario(DummyVerificationScenario.autoApprove), source: source);
    await _dismissIntro(tester, en);
    await tester.tap(find.byKey(_shutterButton));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, en.identityReviewContinueCta));
    await tester.pump();

    expect(find.text(en.identityUploadingBannerTitle), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(find.byKey(const ValueKey('idv-upload-progress')));
    expect(bar.value, 0.4);

    source.sent.complete();
    await tester.pump();
    expect(find.text(en.identityReadingDocumentTitle), findsOneWidget);

    source.read.complete();
    await tester.pumpAndSettle();
    expect(find.text(en.identityDocumentAcceptedTitle), findsOneWidget);
  });

  for (final (String name, Object error, bool uploadScreen) in <(String, Object, bool)>[
    ('timeout', const RequestTimeoutException(), true),
    ('401', const UnauthorizedException(), false),
    ('403', const ForbiddenException(), false),
    ('422', const ValidationException(<String, List<String>>{'document_number': <String>['invalid']}), false),
    ('500', const ServerException(), false),
  ]) {
    testWidgets('a $name on upload shows an actionable failure, never a silent stall', (tester) async {
      final en = await _l10n('en');
      final source = DummyIdentityVerificationDataSource();
      await _open(tester, reservationIdForScenario(DummyVerificationScenario.autoApprove), source: source);
      await _dismissIntro(tester, en);
      await tester.tap(find.byKey(_shutterButton));
      await tester.pumpAndSettle();
      source.failWith = error;
      await tester.tap(find.widgetWithText(FilledButton, en.identityReviewContinueCta));
      await tester.pumpAndSettle();

      if (uploadScreen) {
        expect(find.text(en.identityFailedUploadBannerTitle), findsOneWidget);
        return;
      }
      expect(find.text(en.identitySubmitFailedTitle), findsOneWidget);
      if (error is ValidationException) {
        // 422 → back to the details form to fix them.
        source.failWith = null;
        await tester.tap(find.widgetWithText(FilledButton, en.identityEditDetailsCta));
        await tester.pumpAndSettle();
        expect(find.text(en.identityDetailsTitle), findsOneWidget);
      } else {
        expect(find.widgetWithText(FilledButton, en.actionRetry), findsOneWidget);
      }
    });
  }

  testWidgets('the mismatch screen links to reception', (tester) async {
    final en = await _l10n('en');
    final source = DummyIdentityVerificationDataSource()
      ..nextDocumentCheck = DocumentCheckStatus.mismatch;
    await _open(tester, reservationIdForScenario(DummyVerificationScenario.autoApprove),
        source: source, camera: FakeIdentityCamera());
    await _dismissIntro(tester, en);
    await _captureAndSubmitDocument(tester, en);

    await tester.tap(find.text(en.identityStuckContactReception));
    await tester.pumpAndSettle();
    expect(find.text(en.identityContactReceptionBannerTitle), findsOneWidget);
  });

  testWidgets('Egyptian ID with the live camera: card frame + tips, feed inside the frame, one session for both sides',
      (tester) async {
    final en = await _l10n('en');
    final camera = _FakeLiveCamera();
    await _open(tester, reservationIdForScenario(DummyVerificationScenario.autoApprove), camera: camera);
    await tester.tap(find.widgetWithText(FilledButton, en.identityIntroCta));
    await tester.pumpAndSettle();
    await _fillDetails(tester, en, type: IdentityDocumentType.egyptianNationalId);

    // Front: the feed is inside a landscape, card-shaped frame, with instructions.
    final Finder feed = find.byKey(const ValueKey('fake-live-document'));
    expect(feed, findsOneWidget);
    final Size frame = tester.getSize(feed);
    expect(frame.width / frame.height, closeTo(85.6 / 53.98, 0.02));
    for (final String tip in <String>[en.identityCaptureTipFrame, en.identityCaptureTipLight, en.identityCaptureTipSteady]) {
      expect(find.text(tip), findsOneWidget);
    }

    await tester.tap(find.byKey(_shutterButton));
    await tester.pumpAndSettle();
    // Back: same camera session (no re-open between the two sides).
    expect(find.text(en.identityCaptureBackTitle), findsOneWidget);
    expect(find.byKey(const ValueKey('fake-live-document')), findsOneWidget);
    expect(camera.opened, hasLength(1));
    await tester.tap(find.byKey(_shutterButton));
    await tester.pumpAndSettle();

    // Review: the camera is released.
    expect(find.text(en.identityReviewBothSides), findsOneWidget);
    expect(camera.opened.single.shots, 2);
    expect(camera.opened.single.disposed, isTrue);

    await tester.tap(find.widgetWithText(FilledButton, en.identityReviewContinueCta));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, en.identityReviewContinueCta));
    await tester.pumpAndSettle();

    // Selfie: its own (front-camera) session, with the face tips.
    expect(find.byKey(const ValueKey('fake-live-selfie')), findsOneWidget);
    expect(find.text(en.identitySelfieTipFrame), findsOneWidget);
    await _captureSelfie(tester);
    expect(find.text(en.identityApprovedTitle), findsOneWidget);
    expect(camera.opened.map((v) => v.target), <IdentityCaptureTarget>[
      IdentityCaptureTarget.document,
      IdentityCaptureTarget.selfie,
    ]);
    expect(camera.captures, isEmpty, reason: 'the system camera fallback was never needed');
  });

  testWidgets('when the live camera cannot open, the shutter falls back to the system camera', (tester) async {
    final en = await _l10n('en');
    final camera = _FakeLiveCamera(failWith: const IdentityCameraUnavailable(permissionDenied: false));
    await _open(tester, reservationIdForScenario(DummyVerificationScenario.autoApprove), camera: camera);
    await _dismissIntro(tester, en);

    expect(find.byKey(const ValueKey('fake-live-document')), findsNothing);
    expect(find.text(en.identityCaptureTipFrame), findsOneWidget, reason: 'instructions still shown');
    await tester.tap(find.byKey(_shutterButton));
    await tester.pumpAndSettle();
    expect(camera.captures, <IdentityCaptureTarget>[IdentityCaptureTarget.document]);
    expect(find.text(en.identityReviewDocumentTitle), findsOneWidget);
  });

  testWidgets('a denied live camera shows the open-settings screen', (tester) async {
    final en = await _l10n('en');
    final camera = _FakeLiveCamera(failWith: const IdentityCameraUnavailable(permissionDenied: true));
    await _open(tester, reservationIdForScenario(DummyVerificationScenario.autoApprove), camera: camera);
    await _dismissIntro(tester, en);

    expect(find.text(en.identityCameraDeniedTitle), findsOneWidget);
    expect(find.widgetWithText(FilledButton, en.identityOpenSettingsCta), findsOneWidget);
  });

  testWidgets('a shutter tap while the live camera is still opening never leaves for the system camera',
      (tester) async {
    final en = await _l10n('en');
    final camera = _FakeLiveCamera();
    await _open(tester, reservationIdForScenario(DummyVerificationScenario.autoApprove), camera: camera);
    await _dismissIntro(tester, en);
    camera.opened.single.reopenSilently();

    await tester.tap(find.byKey(_shutterButton));
    await tester.pump();
    expect(camera.captures, isEmpty);
    expect(camera.opened.single.shots, 0);
    expect(find.text(en.identityCaptureDocumentTitle), findsOneWidget);
  });

  testWidgets('the system camera leaves no resume marker once it returns', (tester) async {
    final en = await _l10n('en');
    final prefs = InMemoryAppPreferences(onboardingCompleted: true);
    final camera = FakeIdentityCamera();
    final c = await pumpApp(
      tester,
      bootSession: completeSession(),
      extraOverrides: <Override>[
        reservationRepositoryProvider.overrideWithValue(_StubReservationRepository()),
        identityCameraProvider.overrideWithValue(camera),
        appPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    c.read(appRouterProvider).go(
        '/reservation/${reservationIdForScenario(DummyVerificationScenario.autoApprove)}/identity');
    await tester.pumpAndSettle();
    await _dismissIntro(tester, en);
    await tester.tap(find.byKey(_shutterButton));
    await tester.pumpAndSettle();

    expect(camera.captures, hasLength(1));
    expect(prefs.pendingIdentityCapture, isNull);
  });

  testWidgets('a cold start after Android killed the app behind the system camera resumes the identity step with the photo',
      (tester) async {
    final en = await _l10n('en');
    final String id = reservationIdForScenario(DummyVerificationScenario.autoApprove);
    final prefs = InMemoryAppPreferences(onboardingCompleted: true);
    await PendingIdentityCapture(
      reservationId: id,
      target: IdentityCaptureTarget.document,
      back: false,
      documentType: IdentityDocumentType.passport,
    ).save(prefs);
    final camera = FakeIdentityCamera()..lost = const IdentityCaptured(CapturedImage.dummy);

    await pumpApp(
      tester,
      bootSession: completeSession(),
      extraOverrides: <Override>[
        reservationRepositoryProvider.overrideWithValue(_StubReservationRepository()),
        identityCameraProvider.overrideWithValue(camera),
        appPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    // Not the home screen: straight back to reviewing the recovered ID photo.
    expect(find.text(en.identityReviewDocumentTitle), findsOneWidget);
    expect(camera.captures, isEmpty, reason: 'no second shot needed');
    expect(prefs.pendingIdentityCapture, isNull, reason: 'used once');
  });

  testWidgets('a cold start without a recoverable photo reopens the capture step', (tester) async {
    final en = await _l10n('en');
    final String id = reservationIdForScenario(DummyVerificationScenario.autoApprove);
    final prefs = InMemoryAppPreferences(onboardingCompleted: true);
    await PendingIdentityCapture(
      reservationId: id,
      target: IdentityCaptureTarget.document,
      back: true,
      documentType: IdentityDocumentType.passport,
    ).save(prefs);

    await pumpApp(
      tester,
      bootSession: completeSession(),
      extraOverrides: <Override>[
        reservationRepositoryProvider.overrideWithValue(_StubReservationRepository()),
        identityCameraProvider.overrideWithValue(FakeIdentityCamera()),
        appPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    expect(find.text(en.identityCaptureDocumentTitle), findsOneWidget);
  });
}
