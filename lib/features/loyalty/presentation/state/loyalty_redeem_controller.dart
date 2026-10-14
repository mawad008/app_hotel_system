import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bookings/presentation/state/bookings_providers.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/loyalty_operations.dart';
import 'loyalty_providers.dart';

/// The state of the one-shot "redeem points" action.
sealed class RedeemActionState {
  const RedeemActionState();

  bool get isSubmitting => this is RedeemSubmitting;

  RedeemPointsRequest? get requestOrNull => switch (this) {
        RedeemSubmitting(:final RedeemPointsRequest request) => request,
        RedeemDone(:final RedeemPointsRequest request) => request,
        RedeemFailed(:final RedeemPointsRequest request) => request,
        _ => null,
      };

  RedeemPointsResult? get resultOrNull =>
      this is RedeemDone ? (this as RedeemDone).result : null;

  Failure? get failureOrNull =>
      this is RedeemFailed ? (this as RedeemFailed).failure : null;
}

class RedeemIdle extends RedeemActionState {
  const RedeemIdle();
}

class RedeemSubmitting extends RedeemActionState {
  const RedeemSubmitting(this.request);
  final RedeemPointsRequest request;
}

/// The backend resolved the redemption. Terminal for a *successful* outcome —
/// a further submit for the same request is ignored. A blocked outcome
/// (insufficient points, not eligible, …) is shown from here.
class RedeemDone extends RedeemActionState {
  const RedeemDone(this.request, this.result);
  final RedeemPointsRequest request;
  final RedeemPointsResult result;
}

class RedeemFailed extends RedeemActionState {
  const RedeemFailed(this.request, this.failure);
  final RedeemPointsRequest request;
  final Failure failure;
}

/// Owns the redeem-points action.
///
/// Same guarantees as [LoyaltyEarnController]: duplicate-submit protection,
/// stale-result protection, no local balance mutation (the account + ledger
/// are re-read on success). A changed points amount is a *different* request,
/// so the guard does not block a genuine re-attempt with a new amount.
class LoyaltyRedeemController extends Notifier<RedeemActionState> {
  @override
  RedeemActionState build() => const RedeemIdle();

  Future<void> submit(String reservationId, int points) async {
    final RedeemPointsRequest request =
        RedeemPointsRequest(reservationId: reservationId, points: points);
    final RedeemActionState current = state;
    if (current is RedeemSubmitting && current.request == request) return;
    if (current is RedeemDone &&
        current.request == request &&
        current.result.outcome.isSuccess) {
      return;
    }

    state = RedeemSubmitting(request);
    try {
      final LoyaltyContext ctx =
          await ref.read(loyaltyContextProvider(reservationId).future);
      final RedeemPointsResult result =
          await ref.read(loyaltyRepositoryProvider).redeem(request, ctx);
      if (_superseded(request)) return;
      state = RedeemDone(request, result);
      if (result.outcome.isSuccess) {
        ref.invalidate(loyaltyAccountProvider(reservationId));
        ref.invalidate(loyaltyTransactionsProvider(reservationId));
        // Redeeming applies a discount to this booking's amounts.
        refreshGuestReservations(ref.invalidate, reservationId: reservationId);
      }
    } catch (error) {
      if (_superseded(request)) return;
      state = RedeemFailed(request, ErrorMapper.toFailure(error));
    }
  }

  bool _superseded(RedeemPointsRequest request) {
    final RedeemActionState now = state;
    return now is RedeemSubmitting && now.request != request;
  }

  void reset() => state = const RedeemIdle();
}

final loyaltyRedeemControllerProvider =
    NotifierProvider<LoyaltyRedeemController, RedeemActionState>(
  LoyaltyRedeemController.new,
);
