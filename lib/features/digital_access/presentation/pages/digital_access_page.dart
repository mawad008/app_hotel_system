import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failure_l10n.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/localization/numerals.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/message_view.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/result_view.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/time/stay_date_format.dart';
import '../../../reservation/domain/entities/reservation.dart';
import '../../../reservation/presentation/state/reservation_detail_provider.dart';
import '../../domain/entities/access_grant.dart';
import '../../domain/entities/access_status.dart';
import '../../domain/entities/check_in.dart';
import '../state/check_in_controller.dart';
import '../state/digital_access_providers.dart';
import '../widgets/access_credential_card.dart';
import '../widgets/access_status_pill.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/pull_to_refresh.dart';

/// `04 · Check in & Stay` — the digital room-key screen.
///
/// Renders exactly what the repository resolved for the grant: an active
/// credential, a still-pending issuance, a safe failure with retry, or a
/// revoked / expired notice. It never claims a working key before the
/// repository confirms it, and never renders provider internals.
class DigitalAccessPage extends ConsumerWidget {
  const DigitalAccessPage({super.key, required this.reservationId});

  final String reservationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<AccessGrant> grantAsync = ref.watch(
      accessGrantProvider(reservationId),
    );
    final CheckInActionState action = ref.watch(checkInControllerProvider);

    // A just-completed check-in action can carry a fresher grant than a cached
    // fetch — prefer it when it targets this reservation.
    final AccessGrant? fromAction =
        action is CheckInDone && action.request.reservationId == reservationId
        ? action.result.grant
        : null;

    final bool active =
        (fromAction ?? grantAsync.valueOrNull)?.isActive ?? false;

    return Scaffold(
      // Figma: "تم تسجيل دخولك" in the app bar once the key is live.
      appBar: HotelAppBar(
        title: active ? l10n.accessCheckedInTitle : l10n.accessTitle,
      ),
      body: SafeArea(
        child: PullToRefresh(
          onRefresh: () => refreshAll(<Future<Object?>>[
            ref.refresh(accessGrantProvider(reservationId).future),
            ref.refresh(reservationDetailProvider(reservationId).future),
          ]),
          child: grantAsync.when(
            // A failed refresh keeps the last key on screen.
            skipError: true,
            loading: () => fromAction != null
                ? _Body(grant: fromAction, reservationId: reservationId)
                : Center(child: LoadingView(label: l10n.stateLoadingTitle)),
            error: (Object error, StackTrace _) {
              final failure = ErrorMapper.toFailure(error);
              return MessageView(
                icon: AppIcons.key,
                title: l10n.accessUnavailableTitle,
                message: failure.localizedMessage(l10n),
                actionLabel: l10n.actionRetry,
                onAction: () =>
                    ref.invalidate(accessGrantProvider(reservationId)),
              );
            },
            data: (AccessGrant grant) {
              final AccessGrant shown = (fromAction != null && !grant.isActive)
                  ? fromAction
                  : grant;
              return _Body(grant: shown, reservationId: reservationId);
            },
          ),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.grant, required this.reservationId});

  final AccessGrant grant;
  final String reservationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final Reservation? reservation = ref
        .watch(reservationDetailProvider(reservationId))
        .valueOrNull;
    final String? roomNumber = reservation?.roomNumber;
    final Locale locale = Localizations.localeOf(context);

    void backToReservation() => context.goNamed(
      AppRoutes.reservationDetailName,
      pathParameters: <String, String>{'reservationId': reservationId},
    );

    void toCheckIn() => context.pushReplacementNamed(
      AppRoutes.checkInName,
      pathParameters: <String, String>{'reservationId': reservationId},
    );

    void retryCheckIn() {
      ref
          .read(checkInControllerProvider.notifier)
          .submit(CheckInRequest(reservationId: reservationId));
      context.pushReplacementNamed(
        AppRoutes.checkInProcessingName,
        pathParameters: <String, String>{'reservationId': reservationId},
      );
    }

    if (grant.isActive) {
      // `CHECKIN_DigitalKey`: status pill at the start, the key card, the
      // stay card (→ the stay hub, Figma routing), "لم يعمل الرمز؟".
      return Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: <Widget>[
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: AccessStatusPill(status: grant.status),
                ),
                const SizedBox(height: 20),
                AccessCredentialCard(
                  grant: grant,
                  roomNumber: roomNumber,
                  stayEndsOn: reservation?.stay.checkOut,
                ),
                if (reservation != null) ...<Widget>[
                  const SizedBox(height: 20),
                  _StayCard(
                    title: reservation.hotelCity == null
                        ? reservation.hotelName.resolve(locale)
                        : '${reservation.hotelName.resolve(locale)} · ${reservation.hotelCity}',
                    subtitle:
                        '${context.localDigits(formatStayDateRange(locale, reservation.stay))} · ${l10n.stayNights(reservation.nights)}',
                    onTap: () => context.goNamed(AppRoutes.stayHomeName),
                  ),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: () => context.pushNamed(
                      AppRoutes.contactReceptionName,
                      pathParameters: <String, String>{
                        'reservationId': reservationId,
                      },
                    ),
                    child: Text(l10n.accessKeyNotWorking),
                  ),
                ),
              ],
            ),
          ),
          _BottomAction(
            label: l10n.bookingCtaMyCurrentStay,
            onPressed: () => context.goNamed(AppRoutes.stayHomeName),
          ),
        ],
      );
    }

    // Non-active states → a tinted result banner + the right recovery action.
    final (
      InfoBannerTone tone,
      String title,
      String body,
      Widget action,
    ) = switch (grant.status) {
      AccessStatus.failed => (
        InfoBannerTone.error,
        l10n.checkInFailedTitle,
        l10n.checkInFailedBody,
        _TwoActions(
          primaryLabel: l10n.checkInRetryCta,
          onPrimary: retryCheckIn,
          secondaryLabel: l10n.accessBackToReservation,
          onSecondary: backToReservation,
        ),
      ),
      AccessStatus.issueRequested || AccessStatus.revokeRequested => (
        InfoBannerTone.warning,
        l10n.checkInPendingTitle,
        l10n.checkInPendingBody,
        _TwoActions(
          primaryLabel: l10n.actionCheckAgain,
          onPrimary: () => ref.invalidate(accessGrantProvider(reservationId)),
          secondaryLabel: l10n.accessBackToReservation,
          onSecondary: backToReservation,
        ),
      ),
      AccessStatus.revoked => (
        InfoBannerTone.error,
        l10n.accessRevokedTitle,
        l10n.accessRevokedBody,
        _BottomAction(
          label: l10n.accessBackToReservation,
          onPressed: backToReservation,
        ),
      ),
      AccessStatus.expired => (
        InfoBannerTone.info,
        l10n.accessExpiredTitle,
        l10n.accessExpiredBody,
        _BottomAction(
          label: l10n.accessBackToReservation,
          onPressed: backToReservation,
        ),
      ),
      _ => (
        InfoBannerTone.info,
        l10n.accessNotIssuedTitle,
        l10n.accessNotIssuedBody,
        _BottomAction(label: l10n.reservationCheckInCta, onPressed: toCheckIn),
      ),
    };

    return Column(
      children: <Widget>[
        Expanded(
          child: ResultView(
            tone: tone,
            title: title,
            message: body,
            detail: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    l10n.reservationStatusFieldLabel,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                AccessStatusPill(status: grant.status),
              ],
            ),
          ),
        ),
        action,
      ],
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        AppSpacing.pageGutter,
        AppSpacing.xs,
        AppSpacing.pageGutter,
        AppSpacing.md,
      ),
      child: PrimaryButton(label: label, onPressed: onPressed),
    );
  }
}

class _TwoActions extends StatelessWidget {
  const _TwoActions({
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
  });

  final String primaryLabel;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        AppSpacing.pageGutter,
        AppSpacing.xs,
        AppSpacing.pageGutter,
        AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          PrimaryButton(label: primaryLabel, onPressed: onPrimary),
          const SizedBox(height: AppSpacing.xs),
          SecondaryButton(label: secondaryLabel, onPressed: onSecondary),
        ],
      ),
    );
  }
}

/// `CHECKIN_DigitalKey` stay card: white, 1px border, radius 20, 16px
/// padding — "hotel · city" (18 bold) over "dates · nights" (14 secondary).
class _StayCard extends StatelessWidget {
  const _StayCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColorTokens c = context.colors;
    final TextTheme text = Theme.of(context).textTheme;
    return Material(
      color: c.bgSurface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        side: BorderSide(color: c.borderDefault),
      ),
      child: InkWell(
        customBorder: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: text.titleMedium?.copyWith(
                  fontSize: 18,
                  height: 28 / 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: text.bodyMedium?.copyWith(
                  fontSize: 14,
                  height: 24 / 14,
                  color: c.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
