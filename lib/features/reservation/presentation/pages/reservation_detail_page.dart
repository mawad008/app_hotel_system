import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_l10n.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/localization/numerals.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/confirm_action_sheet.dart';
import '../../../../core/widgets/danger_button.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/message_view.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/live_refresh.dart';
import '../../../../core/widgets/pull_to_refresh.dart';
import '../../../bookings/presentation/widgets/booking_summary_card.dart';
import '../../../bookings/presentation/widgets/booking_timeline_card.dart';
import '../../../bookings/presentation/widgets/cancellation_policy_card.dart';
import '../../../checkout/presentation/state/checkout_providers.dart';
import '../../../payment/presentation/state/payment_providers.dart';
import '../../../reviews/domain/entities/review.dart';
import '../../../reviews/presentation/state/review_providers.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/entities/reservation_status.dart';
import '../state/reservation_detail_provider.dart';
import '../state/reservation_providers.dart';

/// `تفاصيل الحجز` — the six `BOOKING_Detail_*.png` states for one
/// reservation, reached from the Bookings tab (also still the landing screen
/// right after confirming a reservation). The timeline + actions are driven
/// entirely by the authoritative [Reservation.status] (plus, for three
/// states, one further authoritative read — payment, folio) — nothing here
/// is invented client-side.
class ReservationDetailPage extends ConsumerWidget {
  const ReservationDetailPage({super.key, required this.reservationId});

  final String reservationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<Reservation> async = ref.watch(
      reservationDetailProvider(reservationId),
    );

    return LiveRefresh(
      onRefresh: () => ref.invalidate(reservationDetailProvider(reservationId)),
      child: Scaffold(
        appBar: HotelAppBar(
          title: l10n.bookingDetailTitle,
          // Reached with `go` (payment / identity / check-in hand-offs) there
          // is nothing to pop: back leads to the bookings list. (Not the
          // diagnostics home — that route is debug-only, so in a release
          // build it hit the router's error page.)
          fallbackLocation: AppRoutes.bookings,
        ),
        body: SafeArea(
          child: PullToRefresh(
            onRefresh: () =>
                ref.refresh(reservationDetailProvider(reservationId).future),
            child: async.when(
              // A failed background refresh keeps the last good data on screen.
              skipError: true,
              loading: () =>
                  Center(child: LoadingView(label: l10n.stateLoadingTitle)),
              error: (Object error, StackTrace _) {
                final failure = ErrorMapper.toFailure(error);
                return MessageView(
                  icon: AppIcons.invoice,
                  title: l10n.bookingNotFoundTitle,
                  message: failure.localizedMessage(l10n),
                  actionLabel: l10n.actionRetry,
                  onAction: () =>
                      ref.invalidate(reservationDetailProvider(reservationId)),
                );
              },
              data: (Reservation reservation) =>
                  _Body(reservation: reservation),
            ),
          ),
        ),
        bottomNavigationBar: async.maybeWhen(
          skipError: true,
          data: (Reservation reservation) => SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageGutter,
                AppSpacing.bottomBarTop,
                AppSpacing.pageGutter,
                AppSpacing.bottomBarBottom,
              ),
              child: _Actions(reservation: reservation),
            ),
          ),
          orElse: () => null,
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.reservation});

  final Reservation reservation;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pageGutter),
      children: <Widget>[
        BookingSummaryCard(reservation: reservation),
        const SizedBox(height: AppSpacing.md),
        _Timeline(reservation: reservation),
        const SizedBox(height: AppSpacing.md),
        CancellationPolicyCard(cancellation: reservation.cancellation),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

/// Statuses share a timeline branch where the Figma content is identical
/// (`checked_in`/`in_stay` are both "currently staying"; `checked_out`/
/// `invoiced` are both "completed").
/// "١٤ سبتمبر" / "14 September" — the day-month the v2 timeline rows use.
String _dayMonth(BuildContext context, DateTime date) => context.localDigits(
  DateFormat.MMMMd(Localizations.localeOf(context).toString()).format(date),
);

class _Timeline extends ConsumerWidget {
  const _Timeline({required this.reservation});

  final Reservation reservation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;

    switch (reservation.status) {
      case ReservationStatus.pending:
        return BookingTimelineCard(
          rows: <BookingTimelineRow>[
            BookingTimelineRow(
              title: l10n.bookingPendingRowTitle,
              subtitle: l10n.bookingPendingRowSubtitle,
              filled: true,
            ),
            BookingTimelineRow(title: l10n.bookingAutoCancelRowTitle),
            BookingTimelineRow(
              title: l10n.bookingRoomHeldRowTitle,
              subtitle: l10n.bookingRoomHeldRowSubtitle,
            ),
          ],
        );

      case ReservationStatus.depositHeld:
        return BookingTimelineCard(
          rows: <BookingTimelineRow>[
            BookingTimelineRow(
              title: l10n.bookingDepositHeldRowTitle,
              subtitle: l10n.bookingDepositHeldRowSubtitle,
              filled: true,
            ),
            BookingTimelineRow(
              title: l10n.bookingDeductedAtCheckinRowTitle,
              subtitle: _dayMonth(context, reservation.stay.checkIn),
            ),
            BookingTimelineRow(
              title: l10n.bookingExtrasChargedOnceRowTitle,
              subtitle: l10n.bookingExtrasChargedOnceRowSubtitle,
            ),
          ],
        );

      case ReservationStatus.verified:
        final AsyncValue<num> depositAmount = ref
            .watch(currentPaymentProvider(reservation.id))
            .whenData((payment) => payment.amount.amount);
        return BookingTimelineCard(
          rows: <BookingTimelineRow>[
            BookingTimelineRow(
              title: l10n.bookingIdentityVerifiedRowTitle,
              subtitle: l10n.bookingIdentityVerifiedRowSubtitle,
              filled: true,
            ),
            BookingTimelineRow(
              title: l10n.bookingCheckInAvailableRowTitle,
              subtitle: reservation.hotelCheckInTime == null
                  ? null
                  : context.localDigits(
                      l10n.bookingCheckInFrom(reservation.hotelCheckInTime!),
                    ),
              filled: true,
            ),
            BookingTimelineRow(
              title: l10n.bookingDepositAmountHeldRowTitle,
              amount: depositAmount.valueOrNull,
              currency: reservation.priceSnapshot.currency,
            ),
          ],
        );

      case ReservationStatus.checkedIn:
      case ReservationStatus.inStay:
      case ReservationStatus.checkoutInProgress:
      case ReservationStatus.checkoutBlocked:
        final AsyncValue<num> outstanding = ref
            .watch(folioProvider(reservation.id))
            .whenData((folio) => folio.outstandingTotal.amount);
        return BookingTimelineCard(
          rows: <BookingTimelineRow>[
            BookingTimelineRow(
              title: l10n.bookingOngoingStayRowTitle,
              subtitle: reservation.roomNumber == null
                  ? null
                  : l10n.bookingRoomLabel(reservation.roomNumber!),
              filled: true,
            ),
            BookingTimelineRow(
              title: l10n.bookingDepartureRowTitle,
              subtitle: _dayMonth(context, reservation.stay.checkOut),
            ),
            BookingTimelineRow(
              title: l10n.bookingExtraChargesRowTitle,
              amount: outstanding.valueOrNull,
              currency: reservation.priceSnapshot.currency,
            ),
          ],
        );

      case ReservationStatus.cancelled:
        return BookingTimelineCard(
          rows: <BookingTimelineRow>[
            BookingTimelineRow(
              title: l10n.bookingCancelledRowTitle,
              subtitle: reservation.cancelledAt == null
                  ? null
                  : _dayMonth(context, reservation.cancelledAt!),
              filled: true,
            ),
            // A non-refundable rate is never refunded (approved launch rule) —
            // don't promise a refund or a zero fee the policy doesn't give.
            if (reservation.cancellation.refundable) ...<BookingTimelineRow>[
              BookingTimelineRow(
                title: l10n.bookingDepositRefundRowTitle,
                subtitle: l10n.bookingDepositRefundRowSubtitle,
              ),
              BookingTimelineRow(
                title: l10n.bookingCancellationFeeRowTitle,
                subtitle: l10n.bookingCancellationFeeNone,
              ),
            ] else
              BookingTimelineRow(
                title: l10n.bookingDepositRefundRowTitle,
                subtitle: l10n.bookingDepositNotRefunded,
              ),
          ],
        );

      case ReservationStatus.checkedOut:
      case ReservationStatus.invoiced:
        final AsyncValue<num> paid = ref
            .watch(folioProvider(reservation.id))
            .whenData((folio) => folio.paymentsTotal.amount);
        return BookingTimelineCard(
          rows: <BookingTimelineRow>[
            BookingTimelineRow(
              title: l10n.bookingStayEndedRowTitle,
              subtitle: _dayMonth(context, reservation.stay.checkOut),
              filled: true,
            ),
            BookingTimelineRow(
              title: l10n.bookingTotalPaidRowTitle,
              amount: paid.valueOrNull,
              currency: reservation.priceSnapshot.currency,
              filled: true,
            ),
            BookingTimelineRow(
              title: l10n.bookingInvoiceReadyRowTitle,
              subtitle: l10n.bookingInvoiceReadyRowSubtitle,
              filled: true,
            ),
          ],
        );
    }
  }
}

/// The bottom action bar, one or two buttons per status — no async data
/// needed, only the authoritative [Reservation.status].
class _Actions extends ConsumerWidget {
  const _Actions({required this.reservation});

  final Reservation reservation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;

    switch (reservation.status) {
      case ReservationStatus.pending:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            PrimaryButton(
              label: l10n.bookingCtaContinuePayment,
              icon: AppIcons.payment,
              onPressed: () => context.pushNamed(
                AppRoutes.paymentReviewName,
                pathParameters: <String, String>{
                  'reservationId': reservation.id,
                },
              ),
            ),
            if (reservation.cancellation.allowed) ...<Widget>[
              const SizedBox(height: AppSpacing.xs),
              DangerButton(
                label: l10n.bookingCtaCancelReservation,
                onPressed: () => _confirmCancel(context, ref, reservation),
              ),
            ],
          ],
        );

      case ReservationStatus.depositHeld:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            PrimaryButton(
              label: l10n.bookingCtaVerifyIdentity,
              icon: AppIcons.identity,
              onPressed: () => context.pushNamed(
                AppRoutes.identityVerificationName,
                pathParameters: <String, String>{
                  'reservationId': reservation.id,
                },
              ),
            ),
            if (reservation.cancellation.allowed) ...<Widget>[
              const SizedBox(height: AppSpacing.xs),
              DangerButton(
                label: l10n.bookingCtaCancelReservation,
                onPressed: () => _confirmCancel(context, ref, reservation),
              ),
            ],
          ],
        );

      case ReservationStatus.verified:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            PrimaryButton(
              label: l10n.bookingCtaDigitalCheckIn,
              icon: AppIcons.key,
              onPressed: () => context.pushNamed(
                AppRoutes.checkInName,
                pathParameters: <String, String>{
                  'reservationId': reservation.id,
                },
              ),
            ),
            if (reservation.cancellation.allowed) ...<Widget>[
              const SizedBox(height: AppSpacing.xs),
              DangerButton(
                label: l10n.bookingCtaCancelReservation,
                onPressed: () => _confirmCancel(context, ref, reservation),
              ),
            ],
          ],
        );

      case ReservationStatus.checkedIn:
      case ReservationStatus.inStay:
      case ReservationStatus.checkoutInProgress:
      case ReservationStatus.checkoutBlocked:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            PrimaryButton(
              label: l10n.bookingCtaMyCurrentStay,
              icon: AppIcons.navServices,
              onPressed: () => context.goNamed(AppRoutes.stayHomeName),
            ),
            const SizedBox(height: AppSpacing.xs),
            SecondaryButton(
              label: l10n.bookingCtaShowAccessCode,
              icon: AppIcons.key,
              onPressed: () => context.pushNamed(
                AppRoutes.digitalAccessName,
                pathParameters: <String, String>{
                  'reservationId': reservation.id,
                },
              ),
            ),
            // Checkout opens from `in_stay` (or resumes) — any day of the stay.
            if (reservation.status == ReservationStatus.inStay ||
                reservation.status ==
                    ReservationStatus.checkoutInProgress) ...<Widget>[
              const SizedBox(height: AppSpacing.xs),
              SecondaryButton(
                key: const ValueKey<String>('booking-checkout-button'),
                label: l10n.stayCheckoutCta,
                icon: AppIcons.checkout,
                onPressed: () => context.pushNamed(
                  AppRoutes.checkoutName,
                  pathParameters: <String, String>{
                    'reservationId': reservation.id,
                  },
                ),
              ),
            ],
          ],
        );

      case ReservationStatus.cancelled:
        return SecondaryButton(
          label: l10n.bookingCtaBookAgain,
          onPressed: () => context.pushNamed(
            AppRoutes.hotelDetailName,
            pathParameters: <String, String>{'hotelId': reservation.hotelId},
          ),
        );

      case ReservationStatus.checkedOut:
      case ReservationStatus.invoiced:
        final AsyncValue<Review?> review = ref.watch(
          reservationReviewProvider(reservation.id),
        );
        final bool hasReview = review.valueOrNull != null;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            PrimaryButton(
              label: l10n.bookingCtaViewInvoice,
              icon: AppIcons.invoice,
              onPressed: () => context.pushNamed(
                AppRoutes.invoiceName,
                pathParameters: <String, String>{
                  'reservationId': reservation.id,
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            SecondaryButton(
              label: l10n.bookingCtaBookAgain,
              onPressed: () => context.pushNamed(
                AppRoutes.hotelDetailName,
                pathParameters: <String, String>{
                  'hotelId': reservation.hotelId,
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            SecondaryButton(
              label: l10n.reservationLoyaltyCta,
              icon: AppIcons.loyalty,
              onPressed: () => context.pushNamed(
                AppRoutes.loyaltyName,
                pathParameters: <String, String>{
                  'reservationId': reservation.id,
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            SecondaryButton(
              label: hasReview
                  ? l10n.reservationViewReviewCta
                  : l10n.reservationReviewCta,
              icon: AppIcons.review,
              onPressed: () => context.pushNamed(
                AppRoutes.reviewFormName,
                pathParameters: <String, String>{
                  'reservationId': reservation.id,
                },
              ),
            ),
          ],
        );
    }
  }

  Future<void> _confirmCancel(
    BuildContext context,
    WidgetRef ref,
    Reservation reservation,
  ) async {
    final AppLocalizations l10n = context.l10n;
    // `BOOKING_Cancel_Confirm_Overlay`; the refund line is the server's
    // decision for this reservation.
    final bool confirmed = await showConfirmActionSheet(
      context,
      title: l10n.bookingCancelConfirmTitle,
      message: reservation.cancellation.fullRefund
          ? l10n.bookingCancelFullRefundBody
          : l10n.bookingCancelNoRefundBody,
      confirmLabel: l10n.bookingCancelConfirmCta,
      cancelLabel: l10n.bookingCancelKeepCta,
    );
    if (!confirmed) return;

    try {
      await ref.read(reservationRepositoryProvider).cancel(reservation.id);
      ref.invalidate(reservationDetailProvider(reservation.id));
    } catch (error) {
      if (!context.mounted) return;
      final failure = ErrorMapper.toFailure(error);
      // A 422 is the policy refusing (window closed / non-refundable) or the
      // deposit release failing; re-read the server's decision to say which.
      String message = failure.localizedMessage(l10n);
      if (failure.kind == FailureKind.validation) {
        ref.invalidate(reservationDetailProvider(reservation.id));
        final Reservation fresh = await ref.read(
          reservationDetailProvider(reservation.id).future,
        );
        message = fresh.cancellation.allowed
            ? l10n.cancelRefundFailedError
            : l10n.cancelNotAllowedError;
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
