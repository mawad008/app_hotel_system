import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_l10n.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/localization/numerals.dart';
import '../../../../core/time/stay_date_format.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/bottom_action_bar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/message_view.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../authentication/presentation/state/auth_controller.dart';
import '../../../authentication/presentation/state/auth_state.dart';
import '../../../authentication/presentation/state/login_flow_controller.dart';
import '../../../authentication/presentation/state/post_auth_redirect_controller.dart';
import '../../../loyalty/domain/entities/loyalty_operations.dart';
import '../../../loyalty/domain/entities/loyalty_program.dart';
import '../../../loyalty/presentation/state/loyalty_providers.dart';
import '../../../loyalty/presentation/widgets/loyalty_redemption_field.dart';
import '../../../reservation/domain/entities/create_reservation_request.dart';
import '../../../reservation/domain/entities/reservation.dart';
import '../state/hotel_detail_provider.dart';
import '../../../reservation/presentation/state/create_reservation_controller.dart';
import '../../domain/entities/guest_party.dart';
import '../../domain/entities/hotel_guest_details.dart';
import '../../domain/entities/money.dart';
import '../../domain/entities/room_selection.dart';
import '../state/booking_price.dart';
import '../state/guest_party_controller.dart';
import '../state/room_selection_controller.dart';
import '../widgets/guest_stepper.dart';
import '../widgets/hotel_thumbnail.dart';
import '../widgets/price_breakdown_card.dart';

/// `BOOKING_Summary` — the "تفاصيل الحجز" screen: the chosen room, editable stay
/// dates + guest party, and the price breakdown. Confirming (signed in) creates
/// a `PENDING` reservation and moves straight to payment; a guest is sent to
/// sign-in first and returned here (deferred auth,
/// `docs/mobile-deferred-auth.md`).
class RoomSelectionReviewPage extends ConsumerWidget {
  const RoomSelectionReviewPage({super.key, required this.hotelId});

  final String hotelId;

  String? _guestReference(AuthState auth) => auth.map(
        unknown: () => null,
        unauthenticated: () => null,
        awaitingProfile: (session) => session.profile.phone.e164,
        authenticated: (session) => session.profile.phone.e164,
        sessionExpired: () => null,
      );

  void _signInToConfirm(BuildContext context, WidgetRef ref) {
    ref
        .read(postAuthRedirectProvider.notifier)
        .remember(GoRouterState.of(context).uri.toString());
    ref.read(loginFlowControllerProvider.notifier).reset();
    context.goNamed(AppRoutes.signInName);
  }

  /// Redeems the applied points against the new reservation (the backend
  /// posts the capped credit), then continues to payment. A refused
  /// redemption never blocks the booking — the guest is told nothing was
  /// deducted.
  Future<void> _redeemThenPay(
    BuildContext context,
    WidgetRef ref,
    Reservation reservation,
    int points,
  ) async {
    if (points > 0) {
      final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
      final String failedText = context.l10n.bookingLoyaltyRedeemFailed;
      bool ok = false;
      try {
        final RedeemPointsResult result =
            await ref.read(loyaltyRepositoryProvider).redeem(
                  RedeemPointsRequest(
                    reservationId: reservation.id,
                    points: points,
                  ),
                  LoyaltyContext.forReservation(reservation),
                );
        ok = result.outcome.isSuccess;
      } catch (_) {
        ok = false;
      }
      ref.read(bookingRedeemPointsProvider.notifier).clear(hotelId);
      ref.invalidate(loyaltyProgramProvider(hotelId));
      if (!ok) messenger.showSnackBar(SnackBar(content: Text(failedText)));
    }
    if (!context.mounted) return;
    context.pushReplacementNamed(
      AppRoutes.paymentReviewName,
      pathParameters: <String, String>{'reservationId': reservation.id},
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final RoomSelection? selection = ref.watch(roomSelectionControllerProvider);
    final String? guestReference = _guestReference(
      ref.watch(authControllerProvider),
    );

    if (selection == null || selection.hotelId != hotelId) {
      return Scaffold(
        appBar: HotelAppBar(title: l10n.bookingDetailsTitle),
        body: MessageView(
          icon: AppIcons.room,
          title: l10n.reviewNoSelectionTitle,
          message: l10n.reviewNoSelectionBody,
          actionLabel: l10n.reviewBackToRooms,
          onAction: () => context.pop(),
        ),
      );
    }

    final GuestParty party = ref.watch(guestPartyControllerProvider);
    final bool signedIn = guestReference != null;
    final int redeemPoints = signedIn
        ? ref.watch(bookingRedeemPointsProvider)[hotelId] ?? 0
        : 0;
    final LoyaltyProgram? program = signedIn
        ? ref.watch(loyaltyProgramProvider(hotelId)).valueOrNull
        : null;
    final HotelGuestDetails? hotelDetails =
        ref.watch(hotelDetailProvider(hotelId)).valueOrNull?.details;
    // The hotel's own service fee and tax (dashboard-managed); none when off.
    final Money? serviceFee =
        hotelDetails?.serviceFee?.feeFor(selection.stayTotal);
    final BookingPriceBreakdown breakdown = BookingPriceBreakdown.of(
      selection,
      serviceFee: serviceFee,
      tax: hotelDetails?.taxFor(selection.stayTotal, serviceFee: serviceFee),
      taxRate: hotelDetails?.taxRate,
      loyaltyDiscount: program == null || redeemPoints == 0
          ? 0
          : program.discountFor(
              redeemPoints,
              stayTotal: selection.stayTotal.amount,
            ),
    );

    final CreateReservationRequest? request = signedIn
        ? CreateReservationRequest.fromSelection(
            selection,
            guestReference: guestReference,
          )
        : null;
    final CreateReservationState reservationState =
        ref.watch(createReservationControllerProvider);

    // Once this exact request succeeds, go straight to payment.
    ref.listen<CreateReservationState>(createReservationControllerProvider, (
      CreateReservationState? _,
      CreateReservationState next,
    ) {
      if (next is CreateReservationDone && next.request == request) {
        _redeemThenPay(context, ref, next.reservation, redeemPoints);
      }
    });

    final bool submitting = reservationState is CreateReservationSubmitting &&
        reservationState.request == request;
    final Failure? failure = reservationState is CreateReservationFailed &&
            reservationState.request == request
        ? reservationState.failure
        : null;

    return Scaffold(
      appBar: HotelAppBar(title: l10n.bookingDetailsTitle),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.pageGutter),
          children: <Widget>[
            _RoomCard(selection: selection),
            const SizedBox(height: AppSpacing.md),
            _DatesCard(
              selection: selection,
              onEdit: () => context.pushNamed(
                AppRoutes.stayDatesName,
                pathParameters: <String, String>{'hotelId': hotelId},
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _PartyCard(
              party: party,
              selection: selection,
              onAdults: (int v) => ref
                  .read(guestPartyControllerProvider.notifier)
                  .setAdults(v),
              onChildren: (int v) => ref
                  .read(guestPartyControllerProvider.notifier)
                  .setChildren(v),
            ),
            if (signedIn) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              LoyaltyRedemptionField(
                hotelId: hotelId,
                stayTotal: selection.stayTotal.amount,
                currency: selection.stayTotal.currency,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            PriceBreakdownCard(breakdown: breakdown),
            if (failure != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              InfoBanner(
                tone: InfoBannerTone.error,
                title: l10n.reservationCreateFailedTitle,
                message: failure.localizedMessage(l10n),
              ),
            ],
            if (!signedIn) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.reviewSignInHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar.actions(
        primary: signedIn
            ? PrimaryButton(
                label: submitting
                    ? l10n.reservationConfirming
                    : l10n.bookingProceedToPayment,
                isLoading: submitting,
                onPressed: submitting
                    ? null
                    : () => ref
                        .read(createReservationControllerProvider.notifier)
                        .submit(request!),
              )
            : PrimaryButton(
                label: l10n.reviewSignInToConfirm,
                onPressed: () => _signInToConfirm(context, ref),
              ),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.selection});

  final RoomSelection selection;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final Locale locale = Localizations.localeOf(context);
    final AppColorTokens c = context.colors;

    // v2 `room` data card: the 64px cover leads, 14px gap, 16px padding.
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          HotelThumbnail(
            imageUrl: selection.roomType.coverUrl,
            width: 64,
            height: 64,
            icon: AppIcons.bed,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  selection.roomType.name.resolve(locale),
                  style: theme.textTheme.titleSmall?.copyWith(fontSize: 15.5),
                ),
                const SizedBox(height: 2),
                Row(
                  children: <Widget>[
                    Icon(AppIcons.location, size: 13, color: c.textSecondary),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        selection.hotelName.resolve(locale),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: <Widget>[
                    MoneyText(
                      selection.nightlyRate.amount, currency: selection.nightlyRate.currency,
                      suffix: l10n.priceNightSuffix,
                      markSize: 13,
                    ),
                    const Spacer(),
                    StatusPill(
                      label: l10n.bookingRoomAvailable,
                      foreground: c.successFg,
                      background: c.successBg,
                      icon: AppIcons.shieldCheck,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DatesCard extends StatelessWidget {
  const _DatesCard({required this.selection, required this.onEdit});

  final RoomSelection selection;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final Locale locale = Localizations.localeOf(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  l10n.bookingDatesLabel,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: context.colors.textSecondary),
                ),
              ),
              InkWell(
                onTap: onEdit,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Text(
                    l10n.commonEdit,
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: theme.colorScheme.primary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            // v2: the compact "٦ — ٨ سبتمبر · ليلتان" line, 18 bold.
            '${context.localDigits(formatStayDateRange(locale, selection.stay))}  ·  ${l10n.stayNights(selection.nights)}',
            style: theme.textTheme.titleLarge,
          ),
        ],
      ),
    );
  }
}

class _PartyCard extends StatelessWidget {
  const _PartyCard({
    required this.party,
    required this.selection,
    required this.onAdults,
    required this.onChildren,
  });

  final GuestParty party;
  final RoomSelection selection;
  final ValueChanged<int> onAdults;
  final ValueChanged<int> onChildren;

  void _showLimit(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    // The steppers stop at the chosen room's capacity — a party that outgrows
    // the room would otherwise drop the selection (RoomSelectionController).
    final int maxAdults = selection.maxAdultsWith(party.children);
    final int maxChildren = selection.maxChildrenWith(party.adults);
    final String adultsLimit =
        context.localDigits(l10n.roomMaxAdultsReached(maxAdults));
    final String occupancyLimit = context.localDigits(
      l10n.roomMaxGuestsReached(selection.roomType.maxOccupancy),
    );
    final bool atCapacity = party.total >= selection.roomType.maxOccupancy;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          GuestStepper(
            label: l10n.guestsAdults,
            value: party.adults,
            min: GuestParty.minAdults,
            max: maxAdults,
            onChanged: onAdults,
            onLimitReached: () => _showLimit(context, adultsLimit),
          ),
          const SizedBox(height: AppSpacing.sm),
          GuestStepper(
            label: l10n.guestsChildren,
            value: party.children,
            min: GuestParty.minChildren,
            max: maxChildren,
            onChanged: onChildren,
            onLimitReached: () => _showLimit(context, occupancyLimit),
          ),
          if (atCapacity) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              party.children == 0 ? adultsLimit : occupancyLimit,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: context.colors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
