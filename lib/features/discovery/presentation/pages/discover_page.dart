import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/router/bottom_nav_navigation.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/presentation/ui_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/ui_state_view.dart';
import '../../../../core/widgets/pull_to_refresh.dart';
import '../../../authentication/presentation/state/auth_controller.dart';
import '../../../authentication/presentation/state/auth_state.dart';
import '../../../authentication/presentation/state/login_flow_controller.dart';
import '../../../authentication/presentation/state/post_auth_redirect_controller.dart';
import '../../../notifications/presentation/state/notifications_providers.dart';
import '../../domain/entities/hotel_summary.dart';
import '../state/discover_controller.dart';
import '../widgets/home_hotel_card.dart';
import '../widgets/hotel_search_field.dart';
import '../widgets/room_summary_card.dart';
import '../widgets/section_header.dart';
import '../widgets/upcoming_stay_card.dart';

/// Home — v2 Figma `HOME_Default` (a hotel group) and `HOME_if One hotel`
/// (a single-hotel group), above the persistent 4-tab bar.
///
/// `HOME_Default`: a white header (`أهلاً بك` 20 Bold at the start; search +
/// notifications circle buttons at the end), then — for a signed-in guest with
/// a booking — the `إقامتك القادمة` card, then `اكتشف فنادق المجموعة` (tapping
/// it opens search) over a vertical list of full-bleed [HomeHotelCard]s.
///
/// `HOME_if One hotel`: a larger greeting (24 Bold) + `اكتشف {hotel}`, the
/// read-only search field, the next-stay card, then `استكشف الغرف` over a
/// horizontal rail of room cards.
///
/// Guests browse freely (deferred auth); there is no sign-in entry on Home —
/// guests sign in when they confirm a booking (`mobile-deferred-auth.md`).
class DiscoverPage extends ConsumerWidget {
  const DiscoverPage({super.key});

  void _openHotel(BuildContext context, String hotelId) {
    context.pushNamed(
      AppRoutes.hotelDetailName,
      pathParameters: <String, String>{'hotelId': hotelId},
    );
  }

  void _openSearch(BuildContext context) =>
      context.pushNamed(AppRoutes.hotelSearchName);

  /// The bell. A signed-out guest signs in first and lands on the feed
  /// afterwards (the deferred-auth post-sign-in redirect).
  void _openNotifications(BuildContext context, WidgetRef ref) {
    if (ref.read(authControllerProvider) is! Authenticated) {
      ref.read(postAuthRedirectProvider.notifier).remember(AppRoutes.notifications);
      ref.read(loginFlowControllerProvider.notifier).reset();
      context.goNamed(AppRoutes.signInName);
      return;
    }
    context.pushNamed(AppRoutes.notificationsName);
  }

  void _openReservation(BuildContext context, String reservationId) {
    context.pushNamed(
      AppRoutes.reservationDetailName,
      pathParameters: <String, String>{'reservationId': reservationId},
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<DiscoverView> discover = ref.watch(
      discoverControllerProvider,
    );
    final DiscoverView? view = discover.valueOrNull;
    final bool singleHotel = view?.isSingleHotel ?? false;

    final String greeting = view?.greetingName == null
        ? l10n.discoverGreeting
        : l10n.discoverGreetingNamed(view!.greetingName!);

    // Figma gutters: 24 on `HOME_Default`, 16 on `HOME_if One hotel`.
    final double gutter = singleHotel ? AppSpacing.space4 : AppSpacing.space6;

    final Widget? nextStay = view?.upcomingStay == null
        ? null
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SectionHeader(
                title: l10n.discoverUpcomingStay,
                compact: !singleHotel,
                onSeeAll: () => context.goNamed(AppRoutes.bookingsName),
              ),
              const SizedBox(height: AppSpacing.space2),
              UpcomingStayCard(
                stay: view!.upcomingStay!,
                onTap: () =>
                    _openReservation(context, view.upcomingStay!.reservationId),
              ),
            ],
          );

    return Scaffold(
      body: Column(
        children: <Widget>[
          _HomeHeader(
            gutter: gutter,
            greeting: greeting,
            subtitle: singleHotel
                ? l10n.discoverSubtitleHotel(
                    view!.soleHotel!.name.resolve(
                      Localizations.localeOf(context),
                    ),
                  )
                : null,
            // v2 `HOME_Default` swaps the search field for a header button;
            // the single-hotel frame keeps its field, so no button there.
            onSearch: singleHotel ? null : () => _openSearch(context),
            unreadNotifications: ref.watch(unreadNotificationsCountProvider),
            onNotifications: () => _openNotifications(context, ref),
          ),
          Expanded(
            child: PullToRefresh(
              onRefresh: () =>
                  ref.read(discoverControllerProvider.notifier).refresh(),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  singleHotel ? 0 : AppSpacing.space2,
                  gutter,
                  AppSpacing.space6,
                ),
                children: <Widget>[
                  if (singleHotel) ...<Widget>[
                    HotelSearchField(
                      readOnly: true,
                      onTap: () => _openSearch(context),
                      trailingIcon: AppIcons.filter,
                    ),
                    const SizedBox(height: AppSpacing.space5),
                  ],
                  if (nextStay != null) ...<Widget>[
                    nextStay,
                    SizedBox(
                      height: singleHotel
                          ? AppSpacing.space5
                          : AppSpacing.space4,
                    ),
                  ],
                  _Listings(
                    state: discoverUiState(discover),
                    onRetry: () =>
                        ref.read(discoverControllerProvider.notifier).refresh(),
                    onOpenHotel: (String id) => _openHotel(context, id),
                    onOpenSearch: () => _openSearch(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        current: AppNavTab.home,
        onSelected: (AppNavTab tab) => goToNavTab(context, tab),
      ),
    );
  }
}

/// The Home header: status-bar safe area, then (8px below it) the greeting row
/// — greeting at the start, circle buttons at the end — with 16px beneath.
class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.gutter,
    required this.greeting,
    required this.subtitle,
    required this.onSearch,
    required this.unreadNotifications,
    required this.onNotifications,
  });

  final double gutter;
  final String greeting;

  /// Server unread count (`meta.unread_count`) — the bell badge.
  final int unreadNotifications;
  final VoidCallback onNotifications;

  /// `HOME_if One hotel` only: the sole hotel line under a larger greeting.
  final String? subtitle;

  /// `HOME_Default` only: the search circle button.
  final VoidCallback? onSearch;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme text = Theme.of(context).textTheme;
    final AppColorTokens c = context.colors;

    final Widget title = subtitle == null
        // `HOME_Default`: 20 Bold / 32.
        ? Text(
            greeting,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.headlineSmall,
          )
        // `HOME_if One hotel`: 24 Bold / 36 + 14 Regular subtitle, 2px apart.
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                greeting,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.headlineMedium,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall?.copyWith(color: c.textSecondary),
              ),
            ],
          );

    return ColoredBox(
      color: c.bgCanvas,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            gutter,
            AppSpacing.space2,
            gutter,
            subtitle == null ? AppSpacing.space4 : AppSpacing.space5,
          ),
          child: Row(
            children: <Widget>[
              Expanded(child: title),
              const SizedBox(width: AppSpacing.space3),
              if (onSearch != null) ...<Widget>[
                _CircleButton(
                  icon: AppIcons.search,
                  tooltip: l10n.searchTitle,
                  onPressed: onSearch,
                ),
                const SizedBox(width: AppSpacing.space2),
              ],
              Badge(
                isLabelVisible: unreadNotifications > 0,
                label: Text(unreadNotifications > 9 ? '9+' : '$unreadNotifications'),
                backgroundColor: c.bgPrimary,
                textColor: c.textOnPrimary,
                offset: const Offset(-2, 2),
                child: _CircleButton(
                  icon: AppIcons.homeNotifications,
                  tooltip: l10n.discoverNotificationsTooltip,
                  onPressed: onNotifications,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// v2 Figma `Icon Button / Style=Surface`: a 44px white circle, 0.5px
/// `border/default` hairline, 20px `text/primary` glyph.
class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final AppColorTokens c = context.colors;
    return SizedBox.square(
      dimension: 44,
      child: Material(
        color: c.bgSurface,
        shape: CircleBorder(
          side: BorderSide(color: c.borderDefault, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: IconButton(
          icon: Icon(icon, size: 20, color: c.textPrimary),
          tooltip: tooltip,
          onPressed: onPressed,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _Listings extends StatelessWidget {
  const _Listings({
    required this.state,
    required this.onRetry,
    required this.onOpenHotel,
    required this.onOpenSearch,
  });

  final UiState<DiscoverView> state;
  final VoidCallback onRetry;
  final ValueChanged<String> onOpenHotel;
  final VoidCallback onOpenSearch;

  /// Figma room-card width on the 393 frame.
  static const double _railCardMinWidth = 345;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return UiStateView<DiscoverView>(
      state: state,
      onRetry: onRetry,
      emptyTitle: l10n.discoverEmptyTitle,
      emptyMessage: l10n.discoverEmptyBody,
      skeleton: const _HotelCardsSkeleton(),
      onSuccess: (DiscoverView view) {
        if (view.isSingleHotel) {
          final String hotelId = view.soleHotel!.id;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SectionHeader(
                title: l10n.discoverExploreRooms,
                onSeeAll: () => onOpenHotel(hotelId),
              ),
              const SizedBox(height: AppSpacing.space5),
              // `HOME_if One hotel`: a horizontal rail of room cards, 12px
              // apart, scrolling from the reading-start edge. Cards are 345
              // wide on a 393 phone (the Figma) and grow with the screen (90%
              // of the content width) so larger text never overflows them.
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double cardWidth = math.max(
                    _railCardMinWidth,
                    constraints.maxWidth * 0.9,
                  );
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        for (
                          int i = 0;
                          i < view.soleHotelRooms.length;
                          i++
                        ) ...<Widget>[
                          if (i > 0) const SizedBox(width: AppSpacing.space3),
                          SizedBox(
                            width: cardWidth,
                            child: RoomSummaryCard(
                              room: view.soleHotelRooms[i],
                              nights: 1,
                              selected: false,
                              showStayTotal: false,
                              onViewDetails: () => onOpenHotel(hotelId),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SectionHeader(
              title: l10n.discoverExploreHotels,
              compact: true,
              onTap: onOpenSearch,
            ),
            const SizedBox(height: AppSpacing.space2),
            _HotelCardList(hotels: view.featuredHotels, onOpen: onOpenHotel),
          ],
        );
      },
    );
  }
}

/// `HOME_Default` rail: full-width hotel cards 16px apart. On wide layouts
/// (tablet / landscape) the cards pair up two per row, keeping the Figma card
/// aspect ratio instead of stretching one card across the screen.
class _HotelCardList extends StatelessWidget {
  const _HotelCardList({required this.hotels, required this.onOpen});

  final List<HotelSummary> hotels;
  final ValueChanged<String> onOpen;

  /// Above this content width a single card becomes too wide to read well.
  static const double _twoColumnBreakpoint = 640;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = constraints.maxWidth >= _twoColumnBreakpoint
            ? 2
            : 1;
        const double gap = AppSpacing.space4;
        final double width =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: <Widget>[
            for (final HotelSummary hotel in hotels)
              SizedBox(
                width: width,
                child: HomeHotelCard(
                  hotel: hotel,
                  onTap: () => onOpen(hotel.id),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Loading placeholder shaped like the v2 hotel cards (not a spinner).
class _HotelCardsSkeleton extends StatelessWidget {
  const _HotelCardsSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget card() => const AspectRatio(
      aspectRatio: HomeHotelCard.aspectRatio,
      child: SkeletonImage(
        width: double.infinity,
        height: double.infinity,
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    );
    return Skeleton(
      child: Column(
        children: <Widget>[
          card(),
          const SizedBox(height: AppSpacing.space4),
          card(),
        ],
      ),
    );
  }
}
