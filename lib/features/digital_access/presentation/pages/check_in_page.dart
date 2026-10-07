import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failure_l10n.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/message_view.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../reservation/domain/entities/reservation.dart';
import '../../../reservation/presentation/state/reservation_detail_provider.dart';
import '../../domain/entities/access_grant.dart';
import '../../domain/entities/check_in.dart';
import '../state/check_in_controller.dart';
import '../state/digital_access_providers.dart';
import '../../../../core/widgets/app_icons.dart';

/// `04 · Check in & Stay` — the check-in review / eligibility screen.
///
/// Shows whether the guest can check in (from the authoritative reservation
/// status only) and starts the check-in action. Once a grant exists it hands
/// off — exactly once — to the digital-access screen. The app never transitions
/// the reservation.
class CheckInPage extends ConsumerStatefulWidget {
  const CheckInPage({super.key, required this.reservationId});

  final String reservationId;

  @override
  ConsumerState<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends ConsumerState<CheckInPage> {
  bool _handedOff = false;

  void _handOff() {
    if (_handedOff || !mounted) return;
    _handedOff = true;
    context.pushReplacementNamed(
      AppRoutes.digitalAccessName,
      pathParameters: <String, String>{'reservationId': widget.reservationId},
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<Reservation> reservationAsync = ref.watch(
      reservationDetailProvider(widget.reservationId),
    );
    final AsyncValue<AccessGrant> grantAsync = ref.watch(
      accessGrantProvider(widget.reservationId),
    );

    return Scaffold(
      appBar: HotelAppBar(
        title: l10n.checkInTitle,
        // Reached with `go` from the identity result — nothing to pop.
        fallbackLocation: AppRoutes.reservationDetail
            .replaceFirst(':reservationId', widget.reservationId),
      ),
      body: SafeArea(
        child: _merge(
          reservationAsync,
          grantAsync,
          loading: () =>
              Center(child: LoadingView(label: l10n.stateLoadingTitle)),
          error: (Object error) {
            final failure = ErrorMapper.toFailure(error);
            return MessageView(
              icon: AppIcons.room,
              title: l10n.checkInUnavailableTitle,
              message: failure.localizedMessage(l10n),
              actionLabel: l10n.actionRetry,
              onAction: () {
                ref.invalidate(accessGrantProvider(widget.reservationId));
                ref.invalidate(reservationDetailProvider(widget.reservationId));
              },
            );
          },
          data: (Reservation reservation, AccessGrant grant) {
            // A grant already exists — the access screen owns it from here.
            if (grant.exists) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _handOff());
              return Center(child: LoadingView(label: l10n.stateLoadingTitle));
            }
            return _Body(reservation: reservation);
          },
        ),
      ),
    );
  }

  static Widget _merge(
    AsyncValue<Reservation> a,
    AsyncValue<AccessGrant> b, {
    required Widget Function() loading,
    required Widget Function(Object error) error,
    required Widget Function(Reservation, AccessGrant) data,
  }) {
    if (a.hasError) return error(a.error!);
    if (b.hasError) return error(b.error!);
    if (a.hasValue && b.hasValue) return data(a.requireValue, b.requireValue);
    return loading();
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.reservation});

  final Reservation reservation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final CheckInEligibility eligibility =
        CheckInEligibility.forReservation(reservation);
    final CheckInRequest request = CheckInRequest.forReservation(reservation);
    final CheckInActionState action = ref.watch(checkInControllerProvider);
    final bool submitting =
        action is CheckInSubmitting && action.request == request;

    final (IconData icon, String title, String body) = switch (eligibility) {
      CheckInEligibility.ready => (
        AppIcons.shieldCheck,
        l10n.checkInReadyTitle,
        l10n.checkInReadyBody,
      ),
      CheckInEligibility.notReady => (
        AppIcons.pending,
        l10n.checkInNotReadyTitle,
        l10n.checkInNotReadyBody,
      ),
      CheckInEligibility.alreadyCheckedIn => (
        AppIcons.shieldCheck,
        l10n.checkInAlreadyDoneTitle,
        l10n.checkInReadyBody,
      ),
      CheckInEligibility.unavailable => (
        AppIcons.close,
        l10n.checkInUnavailableTitle,
        l10n.checkInNotReadyBody,
      ),
      CheckInEligibility.blocked => (
        AppIcons.pending,
        l10n.checkInNotReadyTitle,
        switch (reservation.checkInAvailability.reason) {
          'room_not_assigned' => l10n.checkInRoomNotAssigned,
          'check_in_channel_not_allowed' => l10n.checkInAtReception,
          'identity_not_verified' => l10n.checkInIdentityPending,
          'payment_not_confirmed' => l10n.paymentHoldExplainer,
          _ => l10n.checkInNotReadyBody,
        },
      ),
    };

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.pageGutter),
            children: <Widget>[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(icon, color: theme.colorScheme.primary),
                    const SizedBox(height: AppSpacing.sm),
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(body, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
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
          // Not ready: the reservation screen shows the step still missing
          // (pay / verify identity) — never leave a dead, disabled button.
          child: eligibility == CheckInEligibility.notReady
              ? PrimaryButton(
                  label: l10n.identityBackToReservation,
                  onPressed: () => context.goNamed(
                    AppRoutes.reservationDetailName,
                    pathParameters: <String, String>{
                      'reservationId': reservation.id,
                    },
                  ),
                )
              : PrimaryButton(
            label: submitting ? l10n.checkInProcessingTitle : l10n.checkInCta,
            isLoading: submitting,
            onPressed: (!eligibility.canStart || submitting)
                ? null
                : () {
                    ref
                        .read(checkInControllerProvider.notifier)
                        .submit(request);
                    context.pushReplacementNamed(
                      AppRoutes.checkInProcessingName,
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
