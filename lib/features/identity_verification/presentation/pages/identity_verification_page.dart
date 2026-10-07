import 'package:app_settings/app_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_l10n.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/localization/numerals.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/message_view.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/bottom_action_bar.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../authentication/presentation/state/auth_controller.dart';
import '../../../authentication/presentation/state/auth_state.dart';
import '../../../reservation/domain/entities/reservation.dart';
import '../../../reservation/presentation/state/reservation_detail_provider.dart';
import '../../domain/entities/identity_document.dart';
import '../../domain/entities/identity_document_check.dart';
import '../../domain/entities/identity_verification_eligibility.dart';
import '../../domain/entities/identity_verification_session.dart';
import '../../domain/entities/identity_verification_status.dart';
import '../../data/device/identity_camera.dart';
import '../../data/device/live_identity_camera.dart';
import '../state/identity_verification_controller.dart';
import '../state/identity_verification_providers.dart';
import '../widgets/identity_capture_frame.dart';
import '../widgets/identity_details_form.dart';
import '../widgets/identity_info_screen.dart';
import '../../../../core/widgets/app_icons.dart';

/// `10 · Identity verification` — the guest verification flow before check-in.
///
/// A UX pre-check ([IdentityVerificationEligibility]) gates the flow on the
/// authoritative reservation status (deposit must be held first) — the same
/// pattern `CheckInPage`/`CheckoutPage` use — then walks the approved backend
/// state machine: Intro → ID details → capture document → review → upload +
/// OCR document check → capture selfie → upload → matching → Result.
///
/// The OCR check runs on the backend when the document is uploaded; a
/// rejected document (details mismatch, unreadable, expired, unsupported)
/// gets an actionable screen before the selfie step can open. The app never claims approval before the
/// repository confirms it, and never transitions the session or the
/// reservation itself.
class IdentityVerificationPage extends ConsumerStatefulWidget {
  const IdentityVerificationPage({super.key, required this.reservationId});

  final String reservationId;

  @override
  ConsumerState<IdentityVerificationPage> createState() =>
      _IdentityVerificationPageState();
}

enum _LocalStep { details, captureDocument, captureBack, reviewDocument, captureSelfie }

class _IdentityVerificationPageState
    extends ConsumerState<IdentityVerificationPage> {
  bool _handedOff = false;
  bool _introSeen = false;
  bool _showContactReception = false;
  _LocalStep _step = _LocalStep.details;

  /// The guest's ID details — form memory only, never persisted or logged.
  IdentityDocumentClaim? _claim;

  /// Counts document uploads started on this screen; the document-check
  /// rejection screen is shown until the guest acts on it for that upload.
  int _uploadSeq = 0;
  int? _rejectionHandledAt;

  /// The upload whose accepted / needs-review outcome the guest has seen.
  int? _outcomeAckAt;

  /// The back of the card, when the selected type needs / allows it.
  CapturedImage? _backImage;

  /// Selectable document types from the server catalog (defaults until loaded).
  List<IdentityDocumentOption> _options = IdentityDocumentOption.defaults;

  /// The server runs in document-only mode: a photo of the ID is all it asks.
  bool get _documentOnly => _options.every((o) => !o.detailsRequired);

  BackImagePolicy get _backPolicy => _options
      .firstWhere((o) => o.type == _documentType,
          orElse: () => IdentityDocumentOption(type: _documentType, back: _documentType.defaultBack))
      .back;

  /// The real ID photo taken on the capture step, previewed on review and
  /// uploaded on "continue". Cleared on retake.
  CapturedImage? _documentImage;

  /// The last selfie taken — kept so a failed upload can be retried without
  /// re-shooting ("صورك محفوظة على جهازك").
  CapturedImage? _selfieImage;

  /// Set when the camera can't be opened (`IDENTITY_CameraDenied`).
  IdentityCameraUnavailable? _cameraProblem;

  /// The live viewfinder per target (front + back of the card share one
  /// session, so the camera stays open between them).
  final Map<IdentityCaptureTarget, GlobalKey<IdentityLiveViewfinderState>> _liveKeys =
      <IdentityCaptureTarget, GlobalKey<IdentityLiveViewfinderState>>{
    IdentityCaptureTarget.document: GlobalKey<IdentityLiveViewfinderState>(),
    IdentityCaptureTarget.selfie: GlobalKey<IdentityLiveViewfinderState>(),
  };

  /// The live camera failed to open (not a denial) — use the one-shot
  /// system camera instead for the rest of this flow.
  bool _liveFailed = false;

  /// `session.attempts` at the moment the guest tapped "try again" from a
  /// retryable failure screen — while it still matches the live session, the
  /// guest is mid-retry (capturing a new document/selfie) and the failure
  /// screen for the *previous* attempt must not reappear. A new failure only
  /// bumps `attempts` once a fresh selfie is submitted, which is exactly when
  /// this stops matching and the (new) failure screen is shown again.
  int? _retryBaselineAttempts;

  IdentityDocumentType _documentType = IdentityDocumentType.passport;

  void _maybeHandOff(IdentityVerificationState state) {
    if (_handedOff || !mounted) return;
    final IdentityVerificationSession? session = state.session;
    if (session == null || state.isBusy) return;
    if (session.isApproved || session.isManualReview) {
      _handedOff = true;
      context.pushReplacementNamed(
        AppRoutes.identityVerificationResultName,
        pathParameters: <String, String>{'reservationId': widget.reservationId},
      );
    }
  }

  void _toReservation() {
    context.goNamed(
      AppRoutes.reservationDetailName,
      pathParameters: <String, String>{'reservationId': widget.reservationId},
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<Reservation> reservationAsync = ref.watch(
      reservationDetailProvider(widget.reservationId),
    );
    final IdentityVerificationState state = ref.watch(
      identityVerificationControllerProvider(widget.reservationId),
    );

    _options = ref.watch(identityDocumentOptionsProvider).valueOrNull ??
        IdentityDocumentOption.defaults;

    ref.listen<IdentityVerificationState>(
      identityVerificationControllerProvider(widget.reservationId),
      (_, next) => _maybeHandOff(next),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeHandOff(state));

    return reservationAsync.when(
      loading: () => Scaffold(
        appBar: HotelAppBar(title: l10n.identityVerificationTitle),
        body: Center(child: LoadingView(label: l10n.stateLoadingTitle)),
      ),
      error: (Object error, _) => Scaffold(
        appBar: HotelAppBar(title: l10n.identityVerificationTitle),
        body: MessageView(
          icon: AppIcons.identity,
          title: l10n.identityUnavailableTitle,
          message: l10n.identityUnavailableTitle,
          actionLabel: l10n.actionRetry,
          onAction: () =>
              ref.invalidate(reservationDetailProvider(widget.reservationId)),
        ),
      ),
      data: (Reservation reservation) {
        final IdentityVerificationEligibility eligibility =
            IdentityVerificationEligibility.fromReservation(reservation.status);

        if (eligibility != IdentityVerificationEligibility.ready) {
          return _ineligibleScaffold(context, l10n, eligibility);
        }

        return _body(context, state);
      },
    );
  }

  Widget _ineligibleScaffold(
    BuildContext context,
    AppLocalizations l10n,
    IdentityVerificationEligibility eligibility,
  ) {
    final (String title, String message) = switch (eligibility) {
      IdentityVerificationEligibility.notReady => (
        l10n.checkInNotReadyTitle,
        l10n.paymentHoldExplainer,
      ),
      IdentityVerificationEligibility.alreadyVerified => (
        l10n.identityApprovedTitle,
        l10n.identityApprovedBody,
      ),
      _ => (l10n.identityUnavailableTitle, l10n.identityUnavailableTitle),
    };

    return IdentityInfoScreen(
      onClose: _toReservation,
      title: l10n.identityVerificationTitle,
      tone: eligibility == IdentityVerificationEligibility.alreadyVerified
          ? InfoBannerTone.success
          : InfoBannerTone.info,
      bannerTitle: title,
      bannerMessage: message,
      primaryLabel:
          eligibility == IdentityVerificationEligibility.alreadyVerified
          ? l10n.identityGoToCheckInCta
          : l10n.identityBackToReservation,
      onPrimary: eligibility == IdentityVerificationEligibility.alreadyVerified
          ? () => context.goNamed(
              AppRoutes.checkInName,
              pathParameters: <String, String>{
                'reservationId': widget.reservationId,
              },
            )
          : _toReservation,
      secondaryLabel:
          eligibility == IdentityVerificationEligibility.alreadyVerified
          ? l10n.identityBackToReservation
          : null,
      onSecondary:
          eligibility == IdentityVerificationEligibility.alreadyVerified
          ? _toReservation
          : null,
    );
  }

  /// A plain (non-full-screen) body under the standard app bar.
  Widget _plain(AppLocalizations l10n, Widget child) => Scaffold(
    appBar: HotelAppBar(title: l10n.identityVerificationTitle),
    body: SafeArea(child: child),
  );

  /// Every step is a full screen — the info screens and the dark camera
  /// screens bring their own app bar / chrome, so nothing is double-wrapped.
  Widget _body(BuildContext context, IdentityVerificationState state) {
    final AppLocalizations l10n = context.l10n;
    final IdentityVerificationSession? session = state.session;

    if (session == null) {
      if (state.hasFailure) {
        return _plain(
          l10n,
          MessageView(
            icon: AppIcons.identity,
            title: l10n.identityUnavailableTitle,
            message: state.failure!.localizedMessage(l10n),
            actionLabel: l10n.actionRetry,
            onAction: () => ref
                .read(
                  identityVerificationControllerProvider(widget.reservationId)
                      .notifier,
                )
                .refresh(),
          ),
        );
      }
      return _plain(
        l10n,
        Center(child: LoadingView(label: l10n.stateLoadingTitle)),
      );
    }

    final IdentityCameraUnavailable? cameraProblem = _cameraProblem;
    if (cameraProblem != null) {
      return _cameraUnavailable(l10n, cameraProblem);
    }

    if (_showContactReception) {
      return _contactReception(l10n);
    }

    // A submit just failed — a network/timeout failure gets the dedicated
    // "couldn't upload" screen; anything else falls back to a plain retry.
    if (state.hasFailure && !state.isBusy) {
      final Failure failure = state.failure!;
      if (failure.kind == FailureKind.network ||
          failure.kind == FailureKind.timeout) {
        return _failedUpload(l10n, session);
      }
      // 401 / 403 / 422 / 5xx / anything else: say so, never fail silently.
      return _submitFailed(l10n, failure);
    }

    // Resolved states hand off to the result screen; render a spinner while
    // the post-frame navigation runs.
    if (session.isApproved || session.isManualReview) {
      return _plain(
        l10n,
        Center(child: LoadingView(label: l10n.stateLoadingTitle)),
      );
    }

    if (state.isSubmittingDocument || state.isSubmittingSelfie) {
      return _uploading(l10n, state);
    }

    if (session.isProcessing) {
      return _processing(l10n);
    }

    final bool freshFailure = _retryBaselineAttempts != session.attempts;

    if (session.status == IdentityVerificationStatus.retryAllowed &&
        freshFailure) {
      return _retryFailure(l10n, session);
    }

    if (session.status == IdentityVerificationStatus.staffRejected &&
        freshFailure) {
      return _rejected(l10n, session);
    }

    if (session.documentRejected && _rejectionHandledAt != _uploadSeq) {
      return _documentRejected(l10n, session.documentCheck!);
    }

    final DocumentCheck? check = session.documentCheck;
    if (check != null &&
        session.needsSelfie &&
        _uploadSeq > 0 &&
        _outcomeAckAt != _uploadSeq) {
      return _documentOutcome(l10n, check);
    }

    if (session.needsSelfie) {
      return _captureSelfie(l10n);
    }

    // needsDocument: notStarted / retryAllowed / staffRejected land here only
    // via their own retry action (which resets `_step`), so this covers the
    // very first visit.
    if (session.status == IdentityVerificationStatus.notStarted &&
        !_introSeen) {
      return _intro(l10n);
    }

    return switch (_step) {
      _LocalStep.details => _details(l10n, session),
      _LocalStep.captureDocument => _captureDocument(l10n),
      _LocalStep.captureBack => _captureBack(l10n),
      _LocalStep.reviewDocument => _reviewDocument(l10n),
      _LocalStep.captureSelfie => _captureSelfie(l10n),
    };
  }

  IdentityVerificationController get _controller => ref.read(
    identityVerificationControllerProvider(widget.reservationId).notifier,
  );

  Widget _intro(AppLocalizations l10n) => IdentityInfoScreen(
    onClose: _toReservation,
    title: l10n.identityVerificationTitle,
    tone: InfoBannerTone.info,
    bannerTitle: l10n.identityIntroBannerTitle,
    bannerMessage: _documentOnly
        ? l10n.identityIntroBannerBodyDocumentOnly
        : l10n.identityIntroBannerBody,
    primaryLabel: l10n.identityIntroCta,
    onPrimary: () => setState(() {
      _introSeen = true;
      _step = _LocalStep.details;
    }),
  );

  Widget _details(AppLocalizations l10n, IdentityVerificationSession session) {
    final AuthState auth = ref.read(authControllerProvider);
    return IdentityDetailsForm(
      key: ValueKey<int>(_uploadSeq),
      options: _options,
      initialType: _documentType,
      initialClaim: _claim,
      profileName: auth is Authenticated ? auth.session.profile.fullName : null,
      highlightedFields: session.documentCheck?.mismatchedFields ?? const <String>[],
      onBack: () => setState(() => _introSeen = false),
      onSubmit: (IdentityDocumentType type, IdentityDocumentClaim? claim) => setState(() {
        _documentType = type;
        _claim = claim;
        // A kept photo (details were the problem) goes straight back to review.
        _step = _documentImage != null ? _LocalStep.reviewDocument : _LocalStep.captureDocument;
      }),
    );
  }

  void _uploadDocument(CapturedImage image) {
    _uploadSeq++;
    _controller.submitDocument(
      _documentType,
      image: image,
      backImage: _backPolicy == BackImagePolicy.none ? null : _backImage,
      claim: _claim,
    );
  }

  /// The document check passed (`verified`) or was accepted for staff review
  /// (`needs_review`): say which, then continue to the selfie.
  Widget _documentOutcome(AppLocalizations l10n, DocumentCheck check) {
    final bool verified = check.status == DocumentCheckStatus.verified;
    return IdentityInfoScreen(
      onClose: _toReservation,
      title: l10n.identityVerificationTitle,
      tone: verified ? InfoBannerTone.success : InfoBannerTone.info,
      bannerTitle: verified ? l10n.identityDocumentAcceptedTitle : l10n.identityDocumentReviewTitle,
      bannerMessage: verified ? l10n.identityDocumentAcceptedBody : l10n.identityDocumentReviewBody,
      primaryLabel: l10n.identityReviewContinueCta,
      onPrimary: () => setState(() => _outcomeAckAt = _uploadSeq),
    );
  }

  /// A submit failed with a non-network error (401 / 403 / 422 / 5xx).
  Widget _submitFailed(AppLocalizations l10n, Failure failure) => IdentityInfoScreen(
        onClose: _toReservation,
        title: l10n.identityVerificationTitle,
        tone: InfoBannerTone.error,
        bannerTitle: l10n.identitySubmitFailedTitle,
        bannerMessage: failure.localizedMessage(l10n),
        primaryLabel: failure.kind == FailureKind.validation ? l10n.identityEditDetailsCta : l10n.actionRetry,
        onPrimary: () {
          setState(() {
            _introSeen = true;
            if (failure.kind == FailureKind.validation) _step = _LocalStep.details;
          });
          _controller.refresh();
        },
        secondaryLabel: l10n.identityBackToReservation,
        onSecondary: _toReservation,
      );

  /// `document_check` rejected the upload — say why and offer the fix.
  Widget _documentRejected(AppLocalizations l10n, DocumentCheck check) {
    void editDetails({required bool keepPhoto}) => setState(() {
          _rejectionHandledAt = _uploadSeq;
          if (!keepPhoto) _documentImage = null;
          _backImage = null;
          _introSeen = true;
          _step = _LocalStep.details;
        });
    void retake() => setState(() {
          _rejectionHandledAt = _uploadSeq;
          _documentImage = null;
          _backImage = null;
          _introSeen = true;
          _step = _LocalStep.captureDocument;
        });
    void contact() => setState(() => _showContactReception = true);

    switch (check.status) {
      case DocumentCheckStatus.mismatch:
        final List<String> labels = <String>[
          for (final String f in check.mismatchedFields)
            switch (f) {
              'name' => l10n.identityFieldName,
              'number' => l10n.identityFieldDocumentNumber,
              _ => l10n.identityFieldDateOfBirth,
            },
        ];
        return IdentityInfoScreen(
          onClose: _toReservation,
          title: l10n.identityVerificationTitle,
          tone: InfoBannerTone.warning,
          bannerTitle: l10n.identityMismatchTitle,
          bannerMessage: labels.isEmpty
              ? l10n.identityMismatchBody
              : l10n.identityMismatchFieldsBody(labels.join(l10n.localeName.startsWith('ar') ? '، ' : ', ')),
          primaryLabel: l10n.identityEditDetailsCta,
          onPrimary: () => editDetails(keepPhoto: true),
          secondaryLabel: l10n.identityReviewRetakeCta,
          onSecondary: retake,
          // Never a dead end: reception can finish the check by hand.
          linkLabel: l10n.identityStuckContactReception,
          onLink: contact,
        );
      case DocumentCheckStatus.documentExpired:
        return IdentityInfoScreen(
          onClose: _toReservation,
          title: l10n.identityVerificationTitle,
          tone: InfoBannerTone.error,
          bannerTitle: l10n.identityExpiredTitle,
          bannerMessage: l10n.identityExpiredBody,
          primaryLabel: l10n.identityUseAnotherDocumentCta,
          onPrimary: () => editDetails(keepPhoto: false),
          secondaryLabel: l10n.identityContactReceptionCta,
          onSecondary: contact,
        );
      case DocumentCheckStatus.documentUnsupported:
        return IdentityInfoScreen(
          onClose: _toReservation,
          title: l10n.identityVerificationTitle,
          tone: InfoBannerTone.warning,
          bannerTitle: l10n.identityUnsupportedTitle,
          bannerMessage: l10n.identityUnsupportedBody,
          primaryLabel: l10n.identityUseAnotherDocumentCta,
          onPrimary: () => editDetails(keepPhoto: false),
          secondaryLabel: l10n.identityContactReceptionCta,
          onSecondary: contact,
        );
      default:
        // ocr_failed (and any unknown rejection): `V7 Document unclear`.
        return IdentityInfoScreen(
          onClose: _toReservation,
          title: l10n.identityVerificationTitle,
          tone: InfoBannerTone.warning,
          bannerTitle: l10n.identityDocumentUnclearBannerTitle,
          bannerMessage: l10n.identityDocumentUnclearBannerBody,
          primaryLabel: l10n.identityReviewRetakeCta,
          onPrimary: retake,
          secondaryLabel: l10n.identityContactReceptionCta,
          onSecondary: contact,
        );
    }
  }

  Future<void> _takePhoto(IdentityCaptureTarget target, {bool back = false}) async {
    final IdentityLiveViewfinderState? live = _liveKeys[target]!.currentState;
    final IdentityCaptureResult result = live != null && live.isReady
        ? await live.takePicture()
        : await ref.read(identityCameraProvider).capture(target);
    if (!mounted) return;
    switch (result) {
      case IdentityCaptured(:final CapturedImage image):
        if (target == IdentityCaptureTarget.document) {
          setState(() {
            if (back) {
              _backImage = image;
              _step = _LocalStep.reviewDocument;
            } else {
              _documentImage = image;
              _step = _backPolicy == BackImagePolicy.none
                  ? _LocalStep.reviewDocument
                  : _LocalStep.captureBack;
            }
          });
        } else {
          _selfieImage = image;
          await _controller.submitSelfie(image: image);
        }
      case IdentityCaptureCancelled():
        break;
      case IdentityCameraUnavailable():
        setState(() => _cameraProblem = result);
    }
  }

  /// "Camera only" is true on iOS/Android; the web picks an image file
  /// (`ImagePickerIdentityCamera`), so it asks for a clear photo instead.
  String _documentHint(AppLocalizations l10n) =>
      kIsWeb ? l10n.identityCaptureFootnoteWeb : l10n.identityCaptureFootnote;

  String _selfieHint(AppLocalizations l10n) =>
      kIsWeb ? l10n.identitySelfieFootnoteWeb : l10n.identityCaptureFootnote;

  /// The camera feed inside the frame (iOS/Android), or null to keep the
  /// one-shot capture (web, tests, or after the live camera failed).
  Widget? _live(IdentityCaptureTarget target) {
    final IdentityCamera camera = ref.read(identityCameraProvider);
    if (_liveFailed || camera is! LiveIdentityCamera || !camera.supportsLiveViewfinder) {
      return null;
    }
    return IdentityLiveViewfinder(
      key: _liveKeys[target],
      camera: camera,
      target: target,
      onUnavailable: (IdentityCameraUnavailable problem) {
        if (!mounted) return;
        setState(() {
          if (problem.permissionDenied) {
            _cameraProblem = problem;
          } else {
            _liveFailed = true;
          }
        });
      },
    );
  }

  List<String> _documentTips(AppLocalizations l10n) => <String>[
        l10n.identityCaptureTipFrame,
        l10n.identityCaptureTipLight,
        l10n.identityCaptureTipSteady,
      ];

  Widget _captureDocument(AppLocalizations l10n) => IdentityCaptureScreen(
    title: l10n.identityCaptureDocumentTitle,
    subtitle: l10n.identityCaptureDocumentHint,
    hint: _documentHint(l10n),
    footnote: l10n.identityCaptureFootnoteSecurity,
    backTooltip: l10n.commonBack,
    onBack: () => setState(() => _step = _LocalStep.details),
    shutterLabel: l10n.identityShutterLabel,
    onShutter: () => _takePhoto(IdentityCaptureTarget.document),
    shape: IdentityFrameShape.card,
    live: _live(IdentityCaptureTarget.document),
    tips: _documentTips(l10n),
  );

  /// Back of the card — required (Egypt) or optional (Saudi, with skip).
  Widget _captureBack(AppLocalizations l10n) => IdentityCaptureScreen(
    title: l10n.identityCaptureBackTitle,
    subtitle: l10n.identityCaptureBackHint,
    hint: _documentHint(l10n),
    footnote: l10n.identityCaptureFootnoteSecurity,
    backTooltip: l10n.commonBack,
    onBack: _retakeDocument,
    shutterLabel: l10n.identityShutterLabel,
    onShutter: () => _takePhoto(IdentityCaptureTarget.document, back: true),
    shape: IdentityFrameShape.card,
    live: _live(IdentityCaptureTarget.document),
    tips: _documentTips(l10n),
    footer: _backPolicy == BackImagePolicy.optional
        ? BottomActionBar(
            floating: false,
            children: <Widget>[
              SecondaryButton(
                key: const ValueKey<String>('idv-skip-back'),
                label: l10n.identitySkipBackCta,
                onPressed: () => setState(() {
                  _backImage = null;
                  _step = _LocalStep.reviewDocument;
                }),
              ),
            ],
          )
        : null,
  );

  Widget _reviewDocument(AppLocalizations l10n) {
    final CapturedImage? image = _documentImage;
    return IdentityCaptureScreen(
      title: l10n.identityReviewDocumentTitle,
      subtitle: _backImage != null ? l10n.identityReviewBothSides : l10n.identityReviewDocumentBody,
      hint: l10n.identityReviewRetakeHint,
      footnote: l10n.identityCaptureFootnoteSecurity,
      backTooltip: l10n.commonBack,
      onBack: _retakeDocument,
      preview: image,
      shape: IdentityFrameShape.card,
      footer: IdentityCaptureFooter(
        primary: PrimaryButton(
          label: l10n.identityReviewContinueCta,
          onPressed: image == null
              ? null
              : () => _uploadDocument(image),
        ),
        secondary: SecondaryButton(
          label: l10n.identityReviewRetakeCta,
          onPressed: _retakeDocument,
        ),
      ),
    );
  }

  void _retakeDocument() => setState(() {
    _documentImage = null;
          _backImage = null;
    _step = _LocalStep.captureDocument;
  });

  Widget _captureSelfie(AppLocalizations l10n) => IdentityCaptureScreen(
    title: l10n.identityCaptureSelfieTitle,
    subtitle: kIsWeb ? l10n.identityCaptureSelfieHintWeb : l10n.identityCaptureSelfieHint,
    hint: _selfieHint(l10n),
    footnote: l10n.identityCaptureFootnoteSecurity,
    backTooltip: l10n.commonBack,
    onBack: _toReservation,
    shutterLabel: l10n.identityShutterLabel,
    onShutter: () => _takePhoto(IdentityCaptureTarget.selfie),
    live: _live(IdentityCaptureTarget.selfie),
    tips: <String>[l10n.identitySelfieTipFrame, l10n.identitySelfieTipClear],
  );

  Widget _cameraUnavailable(
    AppLocalizations l10n,
    IdentityCameraUnavailable problem,
  ) => IdentityInfoScreen(
    onClose: _toReservation,
    title: l10n.identityVerificationTitle,
    tone: InfoBannerTone.error,
    bannerTitle: l10n.identityCameraDeniedTitle,
    bannerMessage: problem.permissionDenied
        ? l10n.identityCameraDeniedBody
        : l10n.identityCameraUnavailableBody,
    primaryLabel: problem.permissionDenied
        ? l10n.identityOpenSettingsCta
        : l10n.identityContactReceptionCta,
    onPrimary: problem.permissionDenied
        ? () {
            // Back on the capture screen when the guest returns.
            setState(() => _cameraProblem = null);
            AppSettings.openAppSettings();
          }
        : () => setState(() {
            _cameraProblem = null;
            _showContactReception = true;
          }),
    secondaryLabel: l10n.commonBack,
    onSecondary: () => setState(() => _cameraProblem = null),
  );

  Widget _uploading(AppLocalizations l10n, IdentityVerificationState state) {
    // All bytes sent: the backend is now reading the document (OCR) or
    // matching the selfie — show "processing" instead of a stuck 100 %.
    if (state.isServerProcessing) {
      return state.isSubmittingDocument
          ? IdentityInfoScreen(
              onClose: _toReservation,
              title: l10n.identityVerificationTitle,
              tone: InfoBannerTone.info,
              bannerTitle: l10n.identityReadingDocumentTitle,
              bannerMessage: l10n.identityReadingDocumentBody,
            )
          : _processing(l10n);
    }
    final double progress = state.uploadProgress ?? 0;
    return Stack(
      children: <Widget>[
        IdentityInfoScreen(
          onClose: _toReservation,
          title: l10n.identityVerificationTitle,
          tone: InfoBannerTone.info,
          bannerTitle: l10n.identityUploadingBannerTitle,
          bannerMessage:
              '${l10n.identityUploadingBannerBody}\n${l10n.identityUploadProgress(context.localDigits('${(progress * 100).round()}'))}',
          primaryLabel: l10n.identityUploadingCancelCta,
          onPrimary: _toReservation,
        ),
        Positioned(
          left: 0,
          right: 0,
          top: MediaQuery.paddingOf(context).top + kToolbarHeight,
          child: LinearProgressIndicator(
            key: const ValueKey<String>('idv-upload-progress'),
            value: progress == 0 ? null : progress,
            semanticsLabel: l10n.identityUploadingBannerTitle,
          ),
        ),
      ],
    );
  }

  Widget _processing(AppLocalizations l10n) => IdentityInfoScreen(
    onClose: _toReservation,
    title: l10n.identityVerificationTitle,
    tone: InfoBannerTone.info,
    bannerTitle: l10n.identityProcessingTitle,
    bannerMessage: l10n.identityProcessingBody,
    primaryLabel: l10n.identityProcessingContinueCta,
    onPrimary: _toReservation,
  );

  Widget _retryFailure(
    AppLocalizations l10n,
    IdentityVerificationSession session,
  ) {
    final bool documentUnclear =
        session.latestOutcome == IdentityMatchOutcome.documentUnclear;
    return IdentityInfoScreen(
      onClose: _toReservation,
      title: l10n.identityVerificationTitle,
      tone: InfoBannerTone.warning,
      bannerTitle: documentUnclear
          ? l10n.identityDocumentUnclearBannerTitle
          : l10n.identityFaceNotMatchedBannerTitle,
      bannerMessage: documentUnclear
          ? l10n.identityDocumentUnclearBannerBody
          : l10n.identityFaceNotMatchedBannerBody,
      primaryLabel: l10n.identityRetryCta,
      onPrimary: () => setState(() {
        _introSeen = true;
        _documentImage = null;
          _backImage = null;
        _step = _LocalStep.details;
        _retryBaselineAttempts = session.attempts;
      }),
      secondaryLabel: documentUnclear
          ? l10n.identityContactReceptionCta
          : l10n.identityRequestManualReviewCta,
      onSecondary: () => setState(() => _showContactReception = true),
    );
  }

  Widget _rejected(AppLocalizations l10n, IdentityVerificationSession session) {
    if (session.canRetry) {
      return IdentityInfoScreen(
        onClose: _toReservation,
        title: l10n.identityVerificationTitle,
        tone: InfoBannerTone.error,
        bannerTitle: l10n.identityRejectedTitle,
        bannerMessage: l10n.identityRejectedRetryBody,
        primaryLabel: l10n.identityRetryCta,
        onPrimary: () => setState(() {
          _introSeen = true;
          _documentImage = null;
          _backImage = null;
          _step = _LocalStep.details;
          _retryBaselineAttempts = session.attempts;
        }),
        secondaryLabel: l10n.identityContactReceptionCta,
        onSecondary: () => setState(() => _showContactReception = true),
      );
    }
    return IdentityInfoScreen(
      onClose: _toReservation,
      title: l10n.identityVerificationTitle,
      tone: InfoBannerTone.error,
      bannerTitle: l10n.identityRejectedTitle,
      bannerMessage: l10n.identityRejectedNoRetryBannerBody,
      primaryLabel: l10n.identityContactReceptionCta,
      onPrimary: () => setState(() => _showContactReception = true),
      secondaryLabel: l10n.identityBackToReservation,
      onSecondary: _toReservation,
    );
  }

  Widget _failedUpload(
    AppLocalizations l10n,
    IdentityVerificationSession session,
  ) {
    final CapturedImage? retryImage = session.needsSelfie
        ? _selfieImage
        : _documentImage;
    return IdentityInfoScreen(
      onClose: _toReservation,
      title: l10n.identityVerificationTitle,
      tone: InfoBannerTone.error,
      bannerTitle: l10n.identityFailedUploadBannerTitle,
      bannerMessage: l10n.identityFailedUploadBannerBody,
      primaryLabel: l10n.identityRetryUploadCta,
      onPrimary: () {
        if (retryImage == null) {
          // Nothing kept on device (e.g. the app was restarted) — shoot again.
          setState(
            () => _step = session.needsSelfie
                ? _LocalStep.captureSelfie
                : (_claim == null ? _LocalStep.details : _LocalStep.captureDocument),
          );
          ref
              .read(
                identityVerificationControllerProvider(widget.reservationId)
                    .notifier,
              )
              .refresh();
        } else if (session.needsSelfie) {
          _controller.submitSelfie(image: retryImage);
        } else {
          _uploadDocument(retryImage);
        }
      },
      secondaryLabel: l10n.identityContinueLaterCta,
      onSecondary: _toReservation,
    );
  }

  Widget _contactReception(AppLocalizations l10n) => IdentityInfoScreen(
    onClose: _toReservation,
    title: l10n.identityContactReceptionCta,
    tone: InfoBannerTone.info,
    bannerTitle: l10n.identityContactReceptionBannerTitle,
    bannerMessage: l10n.identityContactReceptionBannerBody,
    primaryLabel: l10n.identityBackToReservation,
    onPrimary: _toReservation,
    secondaryLabel: l10n.identityViewVerificationStatusCta,
    onSecondary: () => setState(() => _showContactReception = false),
  );
}
