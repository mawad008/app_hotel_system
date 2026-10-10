import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failure_l10n.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/message_view.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../reservation/domain/entities/reservation.dart';
import '../../../reservation/domain/entities/reservation_status.dart';
import '../../../reservation/presentation/state/reservation_detail_provider.dart';
import '../../domain/entities/folio.dart';
import '../state/checkout_controller.dart';
import '../state/checkout_providers.dart';
import '../widgets/folio_summary_card.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/pull_to_refresh.dart';

/// `05 · Depart & Invoice` screen 1 — review the outstanding amount before
/// checkout. Shows the authoritative folio; the primary action settles it in
/// one payment and issues the invoice. The app computes nothing and never
/// transitions the reservation.
class CheckoutPage extends ConsumerWidget {
  const CheckoutPage({super.key, required this.reservationId});

  final String reservationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<Reservation> reservationAsync = ref.watch(
      reservationDetailProvider(reservationId),
    );
    final AsyncValue<Folio> folioAsync = ref.watch(
      folioProvider(reservationId),
    );

    return Scaffold(
      appBar: HotelAppBar(title: l10n.checkoutTitle),
      body: SafeArea(
        child: PullToRefresh(
          onRefresh: () => refreshAll(<Future<Object?>>[
            ref.refresh(reservationDetailProvider(reservationId).future),
            ref.refresh(folioProvider(reservationId).future),
          ]),
          child: _merge(
            reservationAsync,
            folioAsync,
            loading: () =>
                Center(child: LoadingView(label: l10n.stateLoadingTitle)),
            error: (Object e) => MessageView(
              icon: AppIcons.checkout,
              title: l10n.checkoutUnavailableTitle,
              message: ErrorMapper.toFailure(e).localizedMessage(l10n),
              actionLabel: l10n.actionRetry,
              onAction: () {
                ref.invalidate(folioProvider(reservationId));
                ref.invalidate(reservationDetailProvider(reservationId));
              },
            ),
            data: (Reservation reservation, Folio folio) =>
                _Body(reservation: reservation, folio: folio),
          ),
        ),
      ),
    );
  }

  static Widget _merge(
    AsyncValue<Reservation> a,
    AsyncValue<Folio> b, {
    required Widget Function() loading,
    required Widget Function(Object) error,
    required Widget Function(Reservation, Folio) data,
  }) {
    // A failed refresh keeps the last good data on screen.
    if (a.hasValue && b.hasValue) return data(a.requireValue, b.requireValue);
    if (a.hasError) return error(a.error!);
    if (b.hasError) return error(b.error!);
    return loading();
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.reservation, required this.folio});

  final Reservation reservation;
  final Folio folio;

  // Mirrors CheckoutService::CHECKOUTABLE_STATUSES (+ the terminal replay
  // states). `checkedIn` is excluded: the backend only starts a checkout once
  // the stay has begun (`in_stay`, set by reception).
  static const Set<ReservationStatus> _canCheckout = <ReservationStatus>{
    ReservationStatus.inStay,
    ReservationStatus.checkoutInProgress,
    ReservationStatus.invoiced,
    ReservationStatus.checkedOut,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final CheckoutActionState action = ref.watch(checkoutControllerProvider);
    final bool submitting =
        action is CheckoutSubmitting &&
        action.request.reservationId == reservation.id;
    final bool eligible = _canCheckout.contains(reservation.status);
    // Leaving before the booked check-out day: the backend bills only the
    // nights stayed (CheckoutService::recordDeparture) — say so up front.
    final DateTime today = DateUtils.dateOnly(DateTime.now());
    final bool leavingEarly =
        reservation.status == ReservationStatus.inStay &&
        today.isBefore(DateUtils.dateOnly(reservation.stay.checkOut));

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.pageGutter),
            children: <Widget>[
              InfoBanner(
                tone: eligible ? InfoBannerTone.info : InfoBannerTone.warning,
                title: eligible
                    ? l10n.checkoutReadyTitle
                    : l10n.checkoutNotReadyTitle,
                message: eligible
                    ? l10n.checkoutReadyBody
                    : l10n.checkoutNotReadyBody,
              ),
              if (leavingEarly) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                InfoBanner(
                  key: const ValueKey<String>('checkout-early-departure-note'),
                  tone: InfoBannerTone.info,
                  title: l10n.stayCheckoutCta,
                  message: l10n.checkoutEarlyDepartureNote(
                    MaterialLocalizations.of(context)
                        .formatShortMonthDay(reservation.stay.checkOut),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              FolioSummaryCard(folio: folio),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.checkoutSettleNote, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.fromLTRB(
            AppSpacing.pageGutter,
            AppSpacing.xs,
            AppSpacing.pageGutter,
            AppSpacing.md,
          ),
          child: PrimaryButton(
            label: submitting
                ? l10n.checkoutProcessingTitle
                : l10n.checkoutCompleteCta,
            isLoading: submitting,
            onPressed: (!eligible || submitting)
                ? null
                : () {
                    ref
                        .read(checkoutControllerProvider.notifier)
                        .submit(reservation.id);
                    context.pushReplacementNamed(
                      AppRoutes.checkoutProcessingName,
                      pathParameters: <String, String>{
                        'reservationId': reservation.id,
                      },
                    );
                  },
          ),
        ),
      ],
    );
  }
}
