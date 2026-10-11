import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failure.dart';
import '../../../bookings/presentation/state/bookings_providers.dart';
import '../../domain/entities/payment_request.dart';
import '../../domain/entities/payment_result.dart';
import 'payment_providers.dart';

/// The state of the one-shot "request a deposit hold" action.
///
/// Modelled as an explicit state machine rather than a `UiState`
/// (`ui_state.dart` — "workflow features … model those states explicitly").
/// The payment *lifecycle* status lives on [PaymentResult.status]; this type is
/// only the action's own idle / loading / success / failure.
sealed class PaymentActionState {
  const PaymentActionState();

  bool get isSubmitting => this is PaymentActionSubmitting;
  bool get isDone => this is PaymentActionDone;

  PaymentHoldRequest? get requestOrNull => switch (this) {
        PaymentActionSubmitting(:final PaymentHoldRequest request) => request,
        PaymentActionDone(:final PaymentHoldRequest request) => request,
        PaymentActionFailed(:final PaymentHoldRequest request) => request,
        _ => null,
      };

  PaymentResult? get resultOrNull =>
      this is PaymentActionDone ? (this as PaymentActionDone).result : null;

  Failure? get failureOrNull =>
      this is PaymentActionFailed ? (this as PaymentActionFailed).failure : null;
}

/// Nothing submitted yet (or reset after leaving the flow).
class PaymentActionIdle extends PaymentActionState {
  const PaymentActionIdle();
}

/// A hold request is in flight. [request] is captured so a second tap is
/// recognised as a duplicate of the same submission.
class PaymentActionSubmitting extends PaymentActionState {
  const PaymentActionSubmitting(this.request);
  final PaymentHoldRequest request;
}

/// The backend resolved the hold. Terminal for a *successful* outcome — further
/// [submit] calls for the same request are ignored. A non-success outcome
/// (failed / cancelled / expired) is still shown from here and may be retried.
class PaymentActionDone extends PaymentActionState {
  const PaymentActionDone(this.request, this.result);
  final PaymentHoldRequest request;
  final PaymentResult result;
}

/// The hold request could not be completed (an infrastructure `Failure`, not a
/// business decline). The guest can retry.
class PaymentActionFailed extends PaymentActionState {
  const PaymentActionFailed(this.request, this.failure);
  final PaymentHoldRequest request;
  final Failure failure;
}

/// Owns the request-hold action.
///
/// Guarantees:
/// * **duplicate-submit protection** — a call while [PaymentActionSubmitting],
///   or after a *successful* [PaymentActionDone], for the same request is a
///   no-op; the dummy source is idempotent per request too, so a resolved hold
///   is never placed twice.
/// * **retry** — allowed from [PaymentActionFailed], and from a
///   [PaymentActionDone] whose outcome is retryable (failed / cancelled /
///   expired).
/// * **supersession / race protection** — an async result is dropped if a
///   newer request (different [PaymentHoldRequest]) started while it was in
///   flight, so an old result can never overwrite a newer payment's state.
class PaymentController extends Notifier<PaymentActionState> {
  @override
  PaymentActionState build() => const PaymentActionIdle();

  /// Submits [request]. Ignored if an identical request is already in flight or
  /// has already succeeded.
  Future<void> submit(PaymentHoldRequest request) async {
    final PaymentActionState current = state;
    if (current is PaymentActionSubmitting && current.request == request) {
      return;
    }
    if (current is PaymentActionDone &&
        current.request == request &&
        current.result.outcome.isSuccess) {
      return;
    }

    state = PaymentActionSubmitting(request);
    try {
      final PaymentResult result =
          await ref.read(paymentRepositoryProvider).requestHold(request);
      if (_superseded(request)) return;
      state = PaymentActionDone(request, result);
      // A resolved hold can move the Reservation server-side — HOLD_ACTIVE
      // to DEPOSIT_HELD, or a terminal failure/cancellation/expiry back to
      // CANCELLED (`PaymentWorkflowService`) — so the cached reservation
      // (Reservation Detail's CTA, the Bookings tab) must be refetched
      // rather than kept showing the pre-payment PENDING state. Same
      // invalidate-after-mutation convention as check-in/checkout/extend.
      refreshGuestReservations(ref.invalidate, reservationId: request.reservationId);
    } catch (error) {
      if (_superseded(request)) return;
      state = PaymentActionFailed(request, ErrorMapper.toFailure(error));
    }
  }

  /// True when a newer submission replaced the one for [request] while it was
  /// awaiting the repository.
  bool _superseded(PaymentHoldRequest request) {
    final PaymentActionState now = state;
    return now is PaymentActionSubmitting && now.request != request;
  }

  /// Clears state when leaving the flow so a stale result can't be re-used.
  void reset() => state = const PaymentActionIdle();
}

final paymentControllerProvider =
    NotifierProvider<PaymentController, PaymentActionState>(
  PaymentController.new,
);
