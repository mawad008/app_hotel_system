import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/create_reservation_request.dart';
import '../../domain/entities/reservation.dart';
import 'reservation_providers.dart';

/// The state of the one-shot "confirm reservation" action.
///
/// Modelled as an explicit state machine rather than a `UiState`
/// (`ui_state.dart` — "workflow features … model those states explicitly").
sealed class CreateReservationState {
  const CreateReservationState();

  bool get isSubmitting => this is CreateReservationSubmitting;
  bool get isCreated => this is CreateReservationDone;

  Reservation? get reservationOrNull =>
      this is CreateReservationDone
          ? (this as CreateReservationDone).reservation
          : null;

  Failure? get failureOrNull => this is CreateReservationFailed
      ? (this as CreateReservationFailed).failure
      : null;
}

/// Nothing submitted yet (or reset after a failure).
class CreateReservationIdle extends CreateReservationState {
  const CreateReservationIdle();
}

/// A create request is in flight. [request] is captured so a second tap can be
/// recognised as a duplicate of the same submission.
class CreateReservationSubmitting extends CreateReservationState {
  const CreateReservationSubmitting(this.request);
  final CreateReservationRequest request;
}

/// The reservation was created. Terminal — further [submit] calls are ignored so
/// the same booking can never be made twice from one screen.
class CreateReservationDone extends CreateReservationState {
  const CreateReservationDone(this.request, this.reservation);
  final CreateReservationRequest request;
  final Reservation reservation;
}

/// The create request failed. The guest can retry (which resets to idle first).
class CreateReservationFailed extends CreateReservationState {
  const CreateReservationFailed(this.request, this.failure);
  final CreateReservationRequest request;
  final Failure failure;
}

/// Owns the confirm-reservation action.
///
/// Guarantees:
/// * **duplicate-submit protection** — a call while [CreateReservationSubmitting]
///   or after [CreateReservationDone] is a no-op; the underlying dummy source is
///   idempotent per request too.
/// * **stale-selection protection** — the caller passes the request built from
///   the *current* selection; if the selection changed the caller passes a
///   different request and the in-flight/done state for the old one no longer
///   matches, so the UI re-enables submit for the new criteria.
class CreateReservationController extends Notifier<CreateReservationState> {
  @override
  CreateReservationState build() => const CreateReservationIdle();

  /// The current booking attempt: the criteria it was for and its token. A
  /// retry of the same criteria (even after [reset] / a failure) reuses the
  /// token, so a request that reached the server before the connection
  /// dropped replays instead of booking twice. A success or different
  /// criteria start a new attempt.
  String? _attemptFor;
  String? _attemptToken;

  CreateReservationRequest _tagged(CreateReservationRequest request) {
    if (_attemptFor != request.idempotencyKey || _attemptToken == null) {
      _attemptFor = request.idempotencyKey;
      _attemptToken = _newToken();
    }
    return request.withAttempt(_attemptToken!);
  }

  static String _newToken() {
    final Random random = Random.secure();
    return List<String>.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  /// Submits [request]. Ignored if an identical request is already in flight or
  /// already succeeded.
  Future<void> submit(CreateReservationRequest request) async {
    final CreateReservationState current = state;
    if (current is CreateReservationSubmitting && current.request == request) {
      return;
    }
    if (current is CreateReservationDone && current.request == request) return;

    state = CreateReservationSubmitting(request);
    try {
      final Reservation reservation =
          await ref.read(reservationRepositoryProvider).create(_tagged(request));
      // A newer submission (different request) supersedes this result.
      final CreateReservationState now = state;
      if (now is CreateReservationSubmitting && now.request != request) return;
      // Booked: booking the same criteria again later is a new booking.
      if (_attemptFor == request.idempotencyKey) _attemptToken = null;
      state = CreateReservationDone(request, reservation);
    } catch (error) {
      final CreateReservationState now = state;
      if (now is CreateReservationSubmitting && now.request != request) return;
      state = CreateReservationFailed(request, ErrorMapper.toFailure(error));
    }
  }

  /// Clears a failure so the guest can try again, and resets when leaving the
  /// flow so a stale success can't be re-used for a new selection.
  void reset() => state = const CreateReservationIdle();
}

final createReservationControllerProvider =
    NotifierProvider<CreateReservationController, CreateReservationState>(
  CreateReservationController.new,
);
