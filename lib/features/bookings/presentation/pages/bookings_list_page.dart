import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/router/bottom_nav_navigation.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failure_l10n.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/localization/numerals.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/message_view.dart';
import '../../../../core/widgets/live_refresh.dart';
import '../../../../core/widgets/pull_to_refresh.dart';
import '../../../authentication/presentation/state/auth_controller.dart';
import '../../../authentication/presentation/state/auth_state.dart';
import '../../../authentication/presentation/widgets/sign_in_required_view.dart';
import '../../../reservation/domain/entities/reservation.dart';
import '../../domain/bookings_filter.dart';
import '../state/bookings_providers.dart';
import '../widgets/booking_card.dart';

/// `BOOKINGS_List_Current.png` / `BOOKINGS_List_Past.png` — the "حجوزاتي"
/// bottom-nav root. One page, three pills (`docs/design-system.md`): الحالية
/// shows the ongoing stay (if any) plus upcoming bookings; القادمة narrows to
/// upcoming only; السابقة swaps the header to a drill-in look and lists
/// completed/cancelled bookings grouped by year.
class BookingsListPage extends ConsumerWidget {
  const BookingsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    // A signed-out guest gets a sign-in prompt; the list is never fetched.
    if (ref.watch(authControllerProvider) is! Authenticated) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: Text(l10n.navBookings),
        ),
        body: SafeArea(
          child: SignInRequiredView(
            icon: AppIcons.navBookingsOutline,
            message: l10n.guestSignInBookingsBody,
          ),
        ),
        bottomNavigationBar: AppBottomNav(
          current: AppNavTab.bookings,
          onSelected: (AppNavTab tab) => goToNavTab(context, tab),
        ),
      );
    }
    final BookingsFilter filter = ref.watch(bookingsFilterProvider);
    final AsyncValue<List<Reservation>> async = ref.watch(bookingsListProvider);
    final bool isPast = filter == BookingsFilter.past;

    return LiveRefresh(
      onRefresh: () => ref.invalidate(bookingsListProvider),
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          automaticallyImplyLeading: false,
          leading: isPast
              ? IconButton(
                  icon: Icon(AppIcons.backFor(Directionality.of(context))),
                  onPressed: () =>
                      ref.read(bookingsFilterProvider.notifier).state =
                          BookingsFilter.current,
                )
              : null,
          title: Text(isPast ? l10n.bookingsPastTitle : l10n.navBookings),
        ),
        body: SafeArea(
          child: PullToRefresh(
            onRefresh: () => ref.refresh(bookingsListProvider.future),
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
                  onAction: () => ref.invalidate(bookingsListProvider),
                );
              },
              data: (List<Reservation> reservations) =>
                  _Body(reservations: reservations, filter: filter),
            ),
          ),
        ),
        bottomNavigationBar: AppBottomNav(
          current: AppNavTab.bookings,
          onSelected: (AppNavTab tab) => goToNavTab(context, tab),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.reservations, required this.filter});

  final List<Reservation> reservations;
  final BookingsFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;

    if (filter == BookingsFilter.past) {
      final List<Reservation> past =
          reservations.where((Reservation r) => r.isPastBooking).toList()
            ..sort((a, b) => b.stay.checkOut.compareTo(a.stay.checkOut));
      if (past.isEmpty) {
        return EmptyView(
          icon: AppIcons.navBookingsOutline,
          title: l10n.bookingsEmptyTitle,
          message: l10n.bookingsEmptyBody,
        );
      }
      return _GroupedByYear(reservations: past);
    }

    final List<Reservation> ongoing = reservations
        .where((Reservation r) => r.isOngoingStay)
        .toList();
    final List<Reservation> upcoming =
        reservations.where((Reservation r) => r.isUpcomingBooking).toList()
          ..sort((a, b) => a.stay.checkIn.compareTo(b.stay.checkIn));

    final bool showOngoing =
        filter == BookingsFilter.current && ongoing.isNotEmpty;
    if (!showOngoing && upcoming.isEmpty) {
      return EmptyView(
        icon: AppIcons.navBookingsOutline,
        title: l10n.bookingsEmptyTitle,
        message: l10n.bookingsEmptyBody,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pageGutter),
      children: <Widget>[
        _PillSelector(current: filter),
        const SizedBox(height: AppSpacing.md),
        if (showOngoing) ...<Widget>[
          Text(
            l10n.bookingsSectionOngoingStay,
            // Figma: 14px `text/secondary` section label.
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontSize: 14, color: context.colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final Reservation r in ongoing) ...<Widget>[
            BookingCard(reservation: r, onTap: () => _openDetail(context, r)),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.md),
        ],
        if (upcoming.isNotEmpty) ...<Widget>[
          Text(
            l10n.bookingsSectionUpcoming,
            // Figma: 14px `text/secondary` section label.
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontSize: 14, color: context.colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final Reservation r in upcoming) ...<Widget>[
            BookingCard(reservation: r, onTap: () => _openDetail(context, r)),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ],
    );
  }

  void _openDetail(BuildContext context, Reservation reservation) {
    context.pushNamed(
      AppRoutes.reservationDetailName,
      pathParameters: <String, String>{'reservationId': reservation.id},
    );
  }
}

class _PillSelector extends ConsumerWidget {
  const _PillSelector({required this.current});

  final BookingsFilter current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    return Row(
      children: <Widget>[
        _Pill(
          label: l10n.bookingsPillPast,
          selected: false,
          onTap: () => ref.read(bookingsFilterProvider.notifier).state =
              BookingsFilter.past,
        ),
        const SizedBox(width: AppSpacing.sm),
        _Pill(
          label: l10n.bookingsPillUpcoming,
          selected: current == BookingsFilter.upcoming,
          onTap: () => ref.read(bookingsFilterProvider.notifier).state =
              BookingsFilter.upcoming,
        ),
        const SizedBox(width: AppSpacing.sm),
        _Pill(
          label: l10n.bookingsPillCurrent,
          selected: current == BookingsFilter.current,
          onTap: () => ref.read(bookingsFilterProvider.notifier).state =
              BookingsFilter.current,
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      labelStyle: theme.textTheme.labelLarge?.copyWith(
        color: selected
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurface,
      ),
    );
  }
}

class _GroupedByYear extends StatelessWidget {
  const _GroupedByYear({required this.reservations});

  final List<Reservation> reservations;

  @override
  Widget build(BuildContext context) {
    final Map<int, List<Reservation>> byYear = <int, List<Reservation>>{};
    for (final Reservation r in reservations) {
      byYear.putIfAbsent(r.stay.checkOut.year, () => <Reservation>[]).add(r);
    }
    final List<int> years = byYear.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pageGutter),
      children: <Widget>[
        for (final int year in years) ...<Widget>[
          Text(
            context.localDigits('$year'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final Reservation r in byYear[year]!) ...<Widget>[
            BookingCard(
              reservation: r,
              onTap: () => context.pushNamed(
                AppRoutes.reservationDetailName,
                pathParameters: <String, String>{'reservationId': r.id},
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}
