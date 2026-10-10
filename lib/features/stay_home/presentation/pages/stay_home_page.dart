import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/router/bottom_nav_navigation.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failure_l10n.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/message_view.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/live_refresh.dart';
import '../../../../core/widgets/pull_to_refresh.dart';
import '../../../authentication/presentation/state/auth_controller.dart';
import '../../../authentication/presentation/state/auth_state.dart';
import '../../../authentication/presentation/widgets/sign_in_required_view.dart';
import '../../../checkout/presentation/state/checkout_providers.dart';
import '../../../reservation/domain/entities/reservation.dart';
import '../../../stay_services/domain/entities/hotel_service.dart';
import '../../../stay_services/presentation/state/stay_services_providers.dart';
import '../state/stay_home_providers.dart';

/// `STAY_Home.png` — the "الخدمات" bottom-nav root: the guest's real
/// current-stay hub, not a placeholder. Room/hotel card, quick-action tiles
/// resolved against the hotel's real service catalogue, and the live folio
/// outstanding total.
class StayHomePage extends ConsumerWidget {
  const StayHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    // A signed-out guest gets a sign-in prompt; the stay is never fetched.
    if (ref.watch(authControllerProvider) is! Authenticated) {
      return Scaffold(
        appBar: AppBar(centerTitle: true, title: Text(l10n.stayHomeTitle)),
        body: SafeArea(
          child: SignInRequiredView(
            icon: AppIcons.navServicesOutline,
            message: l10n.guestSignInServicesBody,
          ),
        ),
        bottomNavigationBar: AppBottomNav(
          current: AppNavTab.services,
          onSelected: (AppNavTab tab) => goToNavTab(context, tab),
        ),
      );
    }
    final AsyncValue<Reservation?> async = ref.watch(currentStayProvider);

    return LiveRefresh(
      onRefresh: () => ref.invalidate(currentStayProvider),
      child: Scaffold(
        appBar: AppBar(centerTitle: true, title: Text(l10n.stayHomeTitle)),
        body: SafeArea(
          child: PullToRefresh(
            onRefresh: () {
              // The stay plus the cards it feeds (services, charges).
              ref
                ..invalidate(serviceCatalogueProvider)
                ..invalidate(folioProvider);
              return ref.refresh(currentStayProvider.future);
            },
            child: async.when(
              // A failed background refresh keeps the last good data on screen.
              skipError: true,
              loading: () =>
                  Center(child: LoadingView(label: l10n.stateLoadingTitle)),
              error: (Object error, StackTrace _) {
                final failure = ErrorMapper.toFailure(error);
                return MessageView(
                  icon: AppIcons.warning,
                  title: l10n.stateErrorTitle,
                  message: failure.localizedMessage(l10n),
                  actionLabel: l10n.actionRetry,
                  onAction: () => ref.invalidate(currentStayProvider),
                );
              },
              data: (Reservation? stay) => stay == null
                  ? MessageView(
                      icon: AppIcons.navServicesOutline,
                      title: l10n.stayHomeNoActiveStayTitle,
                      message: l10n.stayHomeNoActiveStayBody,
                    )
                  : _Body(reservation: stay),
            ),
          ),
        ),
        bottomNavigationBar: AppBottomNav(
          current: AppNavTab.services,
          onSelected: (AppNavTab tab) => goToNavTab(context, tab),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.reservation});

  final Reservation reservation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final Locale locale = Localizations.localeOf(context);
    final AppColorTokens c = context.colors;
    final AsyncValue<ServiceCatalogue> catalogue = ref.watch(
      serviceCatalogueProvider(reservation.hotelId),
    );
    final AsyncValue<num> outstanding = ref
        .watch(folioProvider(reservation.id))
        .whenData((folio) => folio.outstandingTotal.amount);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pageGutter),
      children: <Widget>[
        // `STAY_Home` room card: "غرفتك" + "hotel · حتى {check-out}" at the
        // start, the room number large at the end.
        AppCard(
          style: AppCardStyle.inverse,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.stayHomeRoomLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: c.textOnInverse.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      l10n.stayHomeHotelUntil(
                        reservation.hotelName.resolve(locale),
                        MaterialLocalizations.of(context)
                            .formatShortMonthDay(reservation.stay.checkOut),
                      ),
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: c.textOnInverse),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                reservation.roomNumber ?? '—',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: c.textOnInverse,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                l10n.stayHomeServicesHeading,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton(
              onPressed: () => context.pushNamed(
                AppRoutes.stayServicesName,
                pathParameters: <String, String>{
                  'reservationId': reservation.id,
                },
              ),
              child: Text(l10n.commonSeeAll),
            ),
          ],
        ),
        catalogue.when(
          loading: () => const SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (Object e, _) => MessageView(
            icon: AppIcons.roomService,
            title: l10n.stateErrorTitle,
            message: ErrorMapper.toFailure(e).localizedMessage(l10n),
            actionLabel: l10n.actionRetry,
            onAction: () =>
                ref.invalidate(serviceCatalogueProvider(reservation.hotelId)),
          ),
          data: (ServiceCatalogue value) =>
              _QuickActionsGrid(reservation: reservation, catalogue: value),
        ),
        const SizedBox(height: AppSpacing.md),
        // Routing map: "charges card → 10 Checkout & invoice".
        InkWell(
          key: const ValueKey<String>('stay-charges-card'),
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          onTap: () => context.pushNamed(
            AppRoutes.checkoutName,
            pathParameters: <String, String>{'reservationId': reservation.id},
          ),
          child: AppCard(
            style: AppCardStyle.outlined,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l10n.stayHomeExtraCharges,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        l10n.stayHomeExtraChargesNote,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                MoneyText(
                  outstanding.valueOrNull ?? 0,
                  currency: reservation.priceSnapshot.currency,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // An explicit way out — the charges card alone wasn't discoverable.
        // The guest may leave any time during the stay, not only on the
        // booked check-out day (billed for the nights actually stayed).
        SecondaryButton(
          key: const ValueKey<String>('stay-checkout-button'),
          label: l10n.stayCheckoutCta,
          icon: AppIcons.checkout,
          onPressed: () => context.pushNamed(
            AppRoutes.checkoutName,
            pathParameters: <String, String>{'reservationId': reservation.id},
          ),
        ),
      ],
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({required this.reservation, required this.catalogue});

  final Reservation reservation;
  final ServiceCatalogue catalogue;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final HotelService? cleaning = findServiceByKeywords(
      catalogue,
      const <String>['cleaning', 'housekeeping', 'تنظيف'],
    );

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.45,
      children: <Widget>[
        _ActionTile(
          icon: AppIcons.cleaning,
          label: l10n.stayHomeRoomCleaning,
          // The hotel's cleaning service when it has one, else the catalogue.
          onTap: cleaning == null
              ? () => context.pushNamed(
                  AppRoutes.stayServicesName,
                  pathParameters: <String, String>{
                    'reservationId': reservation.id,
                  },
                )
              : () => context.pushNamed(
                  AppRoutes.serviceDetailName,
                  pathParameters: <String, String>{
                    'reservationId': reservation.id,
                    'serviceId': cleaning.id,
                  },
                ),
        ),
        _ActionTile(
          icon: AppIcons.roomService,
          label: l10n.stayHomeRoomService,
          onTap: () => context.pushNamed(
            AppRoutes.stayServicesName,
            pathParameters: <String, String>{'reservationId': reservation.id},
          ),
        ),
        _ActionTile(
          icon: AppIcons.report,
          label: l10n.stayHomeReportProblem,
          onTap: () => context.pushNamed(
            AppRoutes.reportProblemName,
            pathParameters: <String, String>{'reservationId': reservation.id},
          ),
        ),
        _ActionTile(
          icon: AppIcons.extendStay,
          label: l10n.stayHomeExtendStay,
          onTap: () => context.pushNamed(
            AppRoutes.extendStayName,
            pathParameters: <String, String>{'reservationId': reservation.id},
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      style: AppCardStyle.outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.colors.bgSubtle,
              borderRadius: AppRadius.allMd,
            ),
            child: Icon(icon, size: 20, color: context.colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(fontSize: 15, color: context.colors.textPrimary),
          ),
        ],
      ),
    );
  }
}
