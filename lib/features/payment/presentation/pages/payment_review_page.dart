import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failure_l10n.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/back_fallback_scope.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/message_view.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../discovery/domain/entities/room_selection.dart';
import '../../../discovery/presentation/state/room_selection_controller.dart';
import '../../../reservation/domain/entities/reservation.dart';
import '../../../reservation/presentation/state/reservation_detail_provider.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/payment_request.dart';
import '../state/payment_controller.dart';
import '../state/payment_providers.dart';
import '../widgets/payment_summary_card.dart';
import '../../../../core/widgets/app_icons.dart';

/// `03 · Pay & Verify` — review the deposit hold before requesting it.
///
/// Shows the authoritative reservation reference / hotel / stay dates / amount
/// and the current payment status. The primary action requests the hold and
/// moves to the processing screen. Nothing is captured here, and the app never
/// changes the reservation status itself.
class PaymentReviewPage extends ConsumerWidget {
  const PaymentReviewPage({super.key, required this.reservationId});

  final String reservationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<Reservation> reservationAsync = ref.watch(
      reservationDetailProvider(reservationId),
    );
    final AsyncValue<Payment> paymentAsync = ref.watch(
      currentPaymentProvider(reservationId),
    );

    // Reached from the booking summary by replacement — after a mid-booking
    // sign-in it is the only page — so "back" falls back to the step where
    // the guest can change the room; outside a booking, to the reservation.
    final RoomSelection? selection = ref.watch(roomSelectionControllerProvider);
    final String back = selection != null
        ? AppRoutes.availableRooms.replaceFirst(':hotelId', selection.hotelId)
        : AppRoutes.reservationDetail.replaceFirst(
            ':reservationId',
            reservationId,
          );

    return BackFallbackScope(
      fallback: back,
      child: Scaffold(
        appBar: HotelAppBar(
          title: l10n.paymentReviewTitle,
          fallbackLocation: back,
        ),
        body: SafeArea(
          child: _merge(
            reservationAsync,
            paymentAsync,
            loading: () =>
                Center(child: LoadingView(label: l10n.stateLoadingTitle)),
            error: (Object error) {
              final failure = ErrorMapper.toFailure(error);
              return MessageView(
                icon: AppIcons.payment,
                title: l10n.paymentUnavailableTitle,
                message: failure.localizedMessage(l10n),
                actionLabel: l10n.actionRetry,
                onAction: () {
                  ref.invalidate(currentPaymentProvider(reservationId));
                  ref.invalidate(reservationDetailProvider(reservationId));
                },
              );
            },
            data: (Reservation reservation, Payment payment) =>
                _Body(reservation: reservation, payment: payment, back: back),
          ),
        ),
      ),
    );
  }

  static Widget _merge(
    AsyncValue<Reservation> a,
    AsyncValue<Payment> b, {
    required Widget Function() loading,
    required Widget Function(Object error) error,
    required Widget Function(Reservation, Payment) data,
  }) {
    if (a.hasError) return error(a.error!);
    if (b.hasError) return error(b.error!);
    if (a.hasValue && b.hasValue) return data(a.requireValue, b.requireValue);
    return loading();
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.reservation,
    required this.payment,
    required this.back,
  });

  final Reservation reservation;
  final Payment payment;
  final String back;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final PaymentHoldRequest request = PaymentHoldRequest.forReservation(
      reservation,
    );
    final PaymentActionState action = ref.watch(paymentControllerProvider);

    final bool secured = payment.status.isSecured;
    final bool submitting =
        action is PaymentActionSubmitting && action.request == request;

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.pageGutter),
            children: <Widget>[
              PaymentSummaryCard(reservation: reservation, payment: payment),
              const SizedBox(height: AppSpacing.md),
              if (secured)
                InfoBanner(
                  tone: InfoBannerTone.info,
                  title: l10n.paymentAlreadyHeldTitle,
                  message: l10n.paymentAlreadyHeldBody,
                )
              else
                Text(
                  l10n.paymentHoldExplainer,
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageGutter,
              AppSpacing.bottomBarTop,
              AppSpacing.pageGutter,
              AppSpacing.bottomBarBottom,
            ),
            child: secured
                ? PrimaryButton(
                    label: l10n.paymentBackToReservation,
                    onPressed: () => context.goNamed(
                      AppRoutes.reservationDetailName,
                      pathParameters: <String, String>{
                        'reservationId': reservation.id,
                      },
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      PrimaryButton(
                        label: l10n.paymentPayNowCta,
                        onPressed: () => context.pushNamed(
                          AppRoutes.paymentMethodName,
                          pathParameters: <String, String>{
                            'reservationId': reservation.id,
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      SecondaryButton(
                        label: l10n.commonBack,
                        onPressed: submitting
                            ? null
                            : () => popOr(context, back),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
