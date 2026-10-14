import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bookings/presentation/state/bookings_providers.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/checkout.dart';
import 'checkout_providers.dart';

/// The state of the one-shot checkout / final-settlement action.
///
/// The checkout *lifecycle* status lives on [CheckoutResult.checkout.status]
/// and the settlement status on [CheckoutResult.settlementStatus]; neither is
/// collapsed to a boolean. This type is only the action's idle / loading /
/// success / failure.
sealed class CheckoutActionState {
  const CheckoutActionState();

  bool get isSubmitting => this is CheckoutSubmitting;

  CheckoutRequest? get requestOrNull => switch (this) {
        CheckoutSubmitting(:final CheckoutRequest request) => request,
        CheckoutDone(:final CheckoutRequest request) => request,
        CheckoutFailed(:final CheckoutRequest request) => request,
        _ => null,
      };

  CheckoutResult? get resultOrNull =>
      this is CheckoutDone ? (this as CheckoutDone).result : null;

  Failure? get failureOrNull =>
      this is CheckoutFailed ? (this as CheckoutFailed).failure : null;
}

class CheckoutIdle extends CheckoutActionState {
  const CheckoutIdle();
}

class CheckoutSubmitting extends CheckoutActionState {
  const CheckoutSubmitting(this.request);
  final CheckoutRequest request;
}

/// The backend resolved the checkout. Terminal for a *completed* checkout —
/// further [submit] calls for the same request are ignored. A settlement
/// failed / pending outcome may still be acted on.
class CheckoutDone extends CheckoutActionState {
  const CheckoutDone(this.request, this.result);
  final CheckoutRequest request;
  final CheckoutResult result;
}

class CheckoutFailed extends CheckoutActionState {
  const CheckoutFailed(this.request, this.failure);
  final CheckoutRequest request;
  final Failure failure;
}

/// Owns the checkout action.
///
/// Guarantees mirror [PaymentController]:
/// * duplicate-submit is a no-op while submitting or after a *completed* done;
/// * retry is allowed from failed and from a done whose outcome is retryable
///   (settlement failed);
/// * the idempotency key ([CheckoutRequest.idempotencyKey]) is stable across
///   rebuilds — a genuine retry re-attempts, a duplicate replays;
/// * a stale async result is dropped when a newer [CheckoutRequest] superseded
///   it, so an old reservation's result never overwrites a newer one;
/// * the reservation status is never transitioned locally, and no money is
///   computed here.
class CheckoutController extends Notifier<CheckoutActionState> {
  @override
  CheckoutActionState build() => const CheckoutIdle();

  Future<void> submit(String reservationId) async {
    final CheckoutRequest request = CheckoutRequest(reservationId: reservationId);
    final CheckoutActionState current = state;
    if (current is CheckoutSubmitting && current.request == request) return;
    if (current is CheckoutDone &&
        current.request == request &&
        current.result.outcome.isSuccess) {
      return;
    }

    state = CheckoutSubmitting(request);
    try {
      final ctx =
          await ref.read(folioContextProvider(reservationId).future);
      final CheckoutResult result =
          await ref.read(checkoutRepositoryProvider).checkout(request, ctx);
      if (_superseded(request)) return;
      state = CheckoutDone(request, result);
      if (result.outcome.isSuccess) {
        ref.invalidate(invoiceProvider(reservationId));
        ref.invalidate(folioProvider(reservationId));
        refreshGuestReservations(ref.invalidate, reservationId: reservationId);
      }
    } catch (error) {
      if (_superseded(request)) return;
      state = CheckoutFailed(request, ErrorMapper.toFailure(error));
    }
  }

  bool _superseded(CheckoutRequest request) {
    final CheckoutActionState now = state;
    return now is CheckoutSubmitting && now.request != request;
  }

  void reset() => state = const CheckoutIdle();
}

final checkoutControllerProvider =
    NotifierProvider<CheckoutController, CheckoutActionState>(
  CheckoutController.new,
);
