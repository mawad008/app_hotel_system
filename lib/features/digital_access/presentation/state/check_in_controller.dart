import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bookings/presentation/state/bookings_providers.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/check_in.dart';
import 'digital_access_providers.dart';

/// The state of the one-shot check-in action.
///
/// Modelled as an explicit state machine (`ui_state.dart` — workflow features
/// model their states explicitly). The access-grant *status* lives on
/// [CheckInResult.grant.status]; this type is only the action's own idle /
/// loading / success / failure.
sealed class CheckInActionState {
  const CheckInActionState();

  bool get isSubmitting => this is CheckInSubmitting;
  bool get isDone => this is CheckInDone;

  CheckInRequest? get requestOrNull => switch (this) {
        CheckInSubmitting(:final CheckInRequest request) => request,
        CheckInDone(:final CheckInRequest request) => request,
        CheckInFailed(:final CheckInRequest request) => request,
        _ => null,
      };

  CheckInResult? get resultOrNull =>
      this is CheckInDone ? (this as CheckInDone).result : null;

  Failure? get failureOrNull =>
      this is CheckInFailed ? (this as CheckInFailed).failure : null;
}

class CheckInIdle extends CheckInActionState {
  const CheckInIdle();
}

class CheckInSubmitting extends CheckInActionState {
  const CheckInSubmitting(this.request);
  final CheckInRequest request;
}

/// The backend resolved the grant. Terminal for a *successful* check-in —
/// further [submit] calls for the same request are ignored. A non-success
/// outcome (issue failed) may be retried.
class CheckInDone extends CheckInActionState {
  const CheckInDone(this.request, this.result);
  final CheckInRequest request;
  final CheckInResult result;
}

/// The check-in request could not be completed (an infrastructure `Failure`,
/// not a business decline).
class CheckInFailed extends CheckInActionState {
  const CheckInFailed(this.request, this.failure);
  final CheckInRequest request;
  final Failure failure;
}

/// Owns the check-in action.
///
/// Guarantees mirror [PaymentController]:
/// * duplicate-submit is a no-op while submitting or after a successful done;
/// * retry is allowed from failed and from a retryable done (issue failed);
/// * an async result is dropped if a newer [CheckInRequest] superseded it, so
///   an old reservation's result never overwrites a newer one;
/// * the reservation status is never transitioned locally.
class CheckInController extends Notifier<CheckInActionState> {
  @override
  CheckInActionState build() => const CheckInIdle();

  Future<void> submit(CheckInRequest request) async {
    final CheckInActionState current = state;
    if (current is CheckInSubmitting && current.request == request) return;
    if (current is CheckInDone &&
        current.request == request &&
        current.result.outcome.isSuccess) {
      return;
    }

    state = CheckInSubmitting(request);
    try {
      final CheckInResult result =
          await ref.read(digitalAccessRepositoryProvider).checkIn(request);
      if (_superseded(request)) return;
      state = CheckInDone(request, result);
      // Checking in moves the reservation to CHECKED_IN — the Bookings tab,
      // STAY_Home and the detail screen must not keep the pre-check-in state.
      if (result.outcome.isSuccess) {
        refreshGuestReservations(ref.invalidate, reservationId: request.reservationId);
      }
    } catch (error) {
      if (_superseded(request)) return;
      state = CheckInFailed(request, ErrorMapper.toFailure(error));
    }
  }

  bool _superseded(CheckInRequest request) {
    final CheckInActionState now = state;
    return now is CheckInSubmitting && now.request != request;
  }

  void reset() => state = const CheckInIdle();
}

final checkInControllerProvider =
    NotifierProvider<CheckInController, CheckInActionState>(
  CheckInController.new,
);
