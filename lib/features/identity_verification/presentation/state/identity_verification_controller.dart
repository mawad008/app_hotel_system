import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/identity_document.dart';
import '../../domain/entities/identity_verification_request.dart';
import '../../domain/entities/identity_verification_session.dart';
import '../../../reservation/presentation/state/reservation_detail_provider.dart';
import 'identity_verification_providers.dart';

/// What the verification flow is doing right now, on top of the authoritative
/// [IdentityVerificationSession] status (`ui_state.dart` — workflow features
/// model their states explicitly).
enum IdentityFlowPhase {
  /// Fetching the initial session status.
  loading,

  /// Idle — showing whatever step the session status calls for.
  ready,

  /// An ID-document upload is in flight.
  submittingDocument,

  /// A selfie upload + match is in flight.
  submittingSelfie,

  /// The last action failed with an infrastructure error (not a business
  /// decline). [IdentityVerificationState.failure] carries the safe message.
  failed,
}

@immutable
class IdentityVerificationState {
  const IdentityVerificationState({
    required this.phase,
    this.session,
    this.failure,
    this.uploadProgress,
  });

  const IdentityVerificationState.loading()
      : phase = IdentityFlowPhase.loading,
        session = null,
        failure = null,
        uploadProgress = null;

  final IdentityFlowPhase phase;
  final IdentityVerificationSession? session;
  final Failure? failure;

  /// Fraction of the current upload sent (0..1) while submitting; 1.0 means
  /// the server has the file and is reading it (OCR / face match).
  final double? uploadProgress;

  /// Bytes are all sent and the server is now processing.
  bool get isServerProcessing =>
      (isSubmittingDocument || isSubmittingSelfie) && (uploadProgress ?? 0) >= 1;

  bool get isBusy =>
      phase == IdentityFlowPhase.loading ||
      phase == IdentityFlowPhase.submittingDocument ||
      phase == IdentityFlowPhase.submittingSelfie;

  bool get isSubmittingDocument =>
      phase == IdentityFlowPhase.submittingDocument;
  bool get isSubmittingSelfie => phase == IdentityFlowPhase.submittingSelfie;
  bool get hasFailure => phase == IdentityFlowPhase.failed && failure != null;

  IdentityVerificationState copyWith({
    IdentityFlowPhase? phase,
    IdentityVerificationSession? session,
    Failure? failure,
    bool clearFailure = false,
    double? uploadProgress,
    bool clearProgress = false,
  }) {
    return IdentityVerificationState(
      phase: phase ?? this.phase,
      session: session ?? this.session,
      failure: clearFailure ? null : (failure ?? this.failure),
      uploadProgress:
          clearProgress ? null : (uploadProgress ?? this.uploadProgress),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is IdentityVerificationState &&
      other.phase == phase &&
      other.session == session &&
      other.failure == failure &&
      other.uploadProgress == uploadProgress;

  @override
  int get hashCode => Object.hash(phase, session, failure, uploadProgress);
}

/// Owns the identity-verification flow for one reservation.
///
/// A `.family` per reservation id, so a session for reservation A can never be
/// overwritten by a late async result addressed to reservation B — that
/// isolation is structural. Within one reservation, a monotonic [_token] guards
/// against a stale result from a superseded action, and [IdentityVerificationState.isBusy]
/// blocks duplicate submits while one is in flight.
///
/// The controller never transitions the session itself: it only reflects what
/// the repository returns, and never claims approval before that.
class IdentityVerificationController
    extends FamilyNotifier<IdentityVerificationState, String> {
  late String _reservationId;
  int _token = 0;

  @override
  IdentityVerificationState build(String arg) {
    _reservationId = arg;
    _token += 1;
    _load(_token);
    return const IdentityVerificationState.loading();
  }

  Future<void> _load(int token) async {
    try {
      final IdentityVerificationSession session = await ref
          .read(identityVerificationRepositoryProvider)
          .statusFor(_reservationId);
      if (_stale(token)) return;
      state = IdentityVerificationState(
        phase: IdentityFlowPhase.ready,
        session: session,
      );
      _refreshReservationIfApproved(session);
    } catch (error) {
      if (_stale(token)) return;
      state = IdentityVerificationState(
        phase: IdentityFlowPhase.failed,
        session: state.session,
        failure: ErrorMapper.toFailure(error),
      );
    }
  }

  /// Re-fetches the session status (e.g. while awaiting a manual review, or to
  /// recover from a load failure).
  Future<void> refresh() async {
    if (state.isBusy) return;
    final int token = ++_token;
    state = state.copyWith(phase: IdentityFlowPhase.loading, clearFailure: true);
    await _load(token);
  }

  /// Submits an ID document together with what the guest says is on it; the
  /// backend runs the OCR check and returns its outcome on the session. Also
  /// serves as the "try again" step from a retryable state (`RETRY_ALLOWED` /
  /// `STAFF_REJECTED`) or after a rejected document check — that is the
  /// approved state-machine edge, not a separate call.
  Future<void> submitDocument(
    IdentityDocumentType type, {
    required CapturedImage image,
    CapturedImage? backImage,
    IdentityDocumentClaim? claim,
  }) async {
    if (state.isBusy) return;
    final int token = ++_token;
    state = state.copyWith(
      phase: IdentityFlowPhase.submittingDocument,
      clearFailure: true,
      uploadProgress: 0,
    );
    await _run(
      token,
      () => ref.read(identityVerificationRepositoryProvider).submitDocument(
            SubmitIdentityDocumentRequest(
              reservationId: _reservationId,
              type: type,
              image: image,
              backImage: backImage,
              claim: claim,
            ),
            onProgress: (double f) => _progress(token, f),
          ),
    );
  }

  /// Submits the selfie and lets the backend resolve the match.
  Future<void> submitSelfie({required CapturedImage image}) async {
    if (state.isBusy) return;
    final IdentityVerificationSession? session = state.session;
    if (session == null || !session.needsSelfie) return;

    final int token = ++_token;
    state = state.copyWith(
      phase: IdentityFlowPhase.submittingSelfie,
      clearFailure: true,
      uploadProgress: 0,
    );
    await _run(
      token,
      () => ref.read(identityVerificationRepositoryProvider).submitSelfie(
            SubmitSelfieRequest(reservationId: _reservationId, image: image),
            onProgress: (double f) => _progress(token, f),
          ),
    );
  }

  /// Coalesces progress to whole percents so a fast upload doesn't rebuild the
  /// screen hundreds of times.
  void _progress(int token, double fraction) {
    if (_stale(token) || !state.isBusy) return;
    final double rounded = (fraction * 100).floorToDouble() / 100;
    if (rounded == state.uploadProgress) return;
    state = state.copyWith(uploadProgress: rounded);
  }

  Future<void> _run(
    int token,
    Future<IdentityVerificationSession> Function() action,
  ) async {
    try {
      final IdentityVerificationSession session = await action();
      if (_stale(token)) return;
      state = IdentityVerificationState(
        phase: IdentityFlowPhase.ready,
        session: session,
      );
      _refreshReservationIfApproved(session);
    } catch (error) {
      if (_stale(token)) return;
      state = IdentityVerificationState(
        phase: IdentityFlowPhase.failed,
        session: state.session,
        failure: ErrorMapper.toFailure(error),
      );
    }
  }

  /// An approval moves the Reservation DEPOSIT_HELD -> VERIFIED server-side,
  /// so the cached reservation (Reservation Detail's CTA, the check-in gate)
  /// must be refetched rather than keep showing DEPOSIT_HELD — same
  /// invalidate-after-mutation convention as payment/check-in/checkout.
  void _refreshReservationIfApproved(IdentityVerificationSession session) {
    if (session.isApproved) {
      ref.invalidate(reservationDetailProvider(_reservationId));
    }
  }

  bool _stale(int token) => token != _token;
}

final identityVerificationControllerProvider = NotifierProvider.family<
    IdentityVerificationController, IdentityVerificationState, String>(
  IdentityVerificationController.new,
);
