import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/message_view.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/pull_to_refresh.dart';
import '../../domain/entities/favorite_room.dart';
import '../../domain/entities/hotel.dart';
import '../../domain/entities/hotel_summary.dart';
import '../state/favorite_hotels_controller.dart';
import '../state/favorite_rooms_controller.dart';
import '../state/hotel_detail_provider.dart';
import '../widgets/hotel_favorite_toggle.dart';
import '../widgets/hotel_thumbnail.dart';
import '../widgets/rating_badge.dart';

/// Settles once the guest's saved rooms and hotels have been fetched, so the
/// page shows a loader rather than a momentary "no favourites" state.
final _favoritesReadyProvider = FutureProvider.autoDispose<void>(
  (Ref ref) => Future.wait(<Future<void>>[
    ref.watch(favoriteRoomsProvider.notifier).loaded,
    ref.watch(favoriteHotelsProvider.notifier).loaded,
  ]),
);

/// "المفضلة": the rooms the guest saved with the Room Detail heart and the
/// hotels saved with the Hotel Detail heart, in two sections. Driven by
/// [favoriteRoomsProvider] / [favoriteHotelsProvider], so a heart toggled
/// anywhere (including undo from the snackbar) updates this list at once.
/// Every row opens its room / hotel or removes it from favourites.
class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final bool ready = ref.watch(_favoritesReadyProvider).hasValue;
    final List<FavoriteRoom> rooms = ref.watch(favoriteRoomsProvider);
    final List<String> hotelIds = ref.watch(favoriteHotelsProvider).toList();

    return Scaffold(
      appBar: HotelAppBar(
        title: l10n.favoritesTitle,
        fallbackLocation: AppRoutes.account,
      ),
      body: SafeArea(
        child: PullToRefresh(
          onRefresh: () {
            ref.invalidate(hotelDetailProvider);
            return refreshAll(<Future<Object?>>[
              ref.read(favoriteRoomsProvider.notifier).reload(),
              ref.read(favoriteHotelsProvider.notifier).reload(),
            ]);
          },
          child: !ready
              ? Center(child: LoadingView(label: l10n.stateLoadingTitle))
              : rooms.isEmpty && hotelIds.isEmpty
              ? MessageView(
                  icon: AppIcons.favorite,
                  title: l10n.favoritesEmptyTitle,
                  message: l10n.favoritesEmptyBody,
                  actionLabel: l10n.favoritesBrowse,
                  onAction: () => context.goNamed(AppRoutes.discoverName),
                )
              : ListView(
                  padding: const EdgeInsets.all(AppSpacing.pageGutter),
                  children: <Widget>[
                    InfoBanner(
                      tone: InfoBannerTone.info,
                      title: l10n.favoritesBannerTitle,
                      message: l10n.favoritesBannerBody,
                    ),
                    if (rooms.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.sm),
                      SectionHeader(title: l10n.favoritesRoomsSection),
                      for (final FavoriteRoom room in rooms) ...<Widget>[
                        _FavoriteRoomTile(
                          key: ValueKey<String>('room-${room.roomTypeId}'),
                          room: room,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ],
                    if (hotelIds.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.sm),
                      SectionHeader(title: l10n.favoritesHotelsSection),
                      for (final String id in hotelIds) ...<Widget>[
                        _FavoriteHotelTile(
                          key: ValueKey<String>('hotel-$id'),
                          hotelId: id,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _FavoriteRoomTile extends ConsumerWidget {
  const _FavoriteRoomTile({super.key, required this.room});

  final FavoriteRoom room;

  static const double _thumb = 76;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final AppColorTokens c = context.colors;
    final Locale locale = Localizations.localeOf(context);
    // The hotel line reuses the detail fetch (usually already cached).
    final HotelSummary? hotel = ref
        .watch(hotelDetailProvider(room.hotelId))
        .valueOrNull
        ?.summary;
    final bool useDummyData = ref.watch(appConfigProvider).useDummyData;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      // Room Detail prices the room for the guest's current dates (and asks
      // for dates when none are chosen yet).
      onTap: () => context.pushNamed(
        AppRoutes.roomDetailName,
        pathParameters: <String, String>{
          'hotelId': room.hotelId,
          'roomTypeId': room.roomTypeId,
        },
      ),
      child: Row(
        children: <Widget>[
          HotelThumbnail(
            imageUrl: room.coverUrl,
            seed: useDummyData ? room.roomTypeId : null,
            width: _thumb,
            height: _thumb,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  room.name.resolve(locale),
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (hotel != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Row(
                    children: <Widget>[
                      Icon(AppIcons.hotel, size: 13, color: c.textSecondary),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          hotel.name.resolve(locale),
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            key: ValueKey<String>('favorite-room-remove-${room.roomTypeId}'),
            icon: const Icon(
              AppIcons.favoriteActive,
              color: AppPrimitives.red600,
            ),
            tooltip: l10n.roomFavoriteRemove,
            onPressed: () =>
                toggleRoomFavorite(context, ref, room, offerViewAction: false),
          ),
        ],
      ),
    );
  }
}

class _FavoriteHotelTile extends ConsumerWidget {
  const _FavoriteHotelTile({super.key, required this.hotelId});

  final String hotelId;

  static const double _thumb = 76;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final AppColorTokens c = context.colors;
    final Locale locale = Localizations.localeOf(context);
    final AsyncValue<Hotel> hotel = ref.watch(hotelDetailProvider(hotelId));
    // Dummy hotels carry no photo; seed the placeholder like the Home tiles.
    final bool useDummyData = ref.watch(appConfigProvider).useDummyData;

    final Widget removeButton = IconButton(
      key: ValueKey<String>('favorite-remove-$hotelId'),
      icon: const Icon(AppIcons.favoriteActive, color: AppPrimitives.red600),
      tooltip: l10n.hotelFavoriteRemove,
      onPressed: () =>
          toggleHotelFavorite(context, ref, hotelId, offerViewAction: false),
    );

    final HotelSummary? summary = hotel.valueOrNull?.summary;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      onTap: summary == null
          ? null
          : () => context.pushNamed(
              AppRoutes.hotelDetailName,
              pathParameters: <String, String>{'hotelId': hotelId},
            ),
      child: Row(
        children: <Widget>[
          HotelThumbnail(
            imageUrl: summary?.coverUrl,
            seed: useDummyData ? hotelId : null,
            width: _thumb,
            height: _thumb,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: hotel.when(
              loading: () => const Align(
                alignment: AlignmentDirectional.centerStart,
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (_, _) => Text(
                l10n.favoritesHotelUnavailable,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: c.textSecondary,
                ),
              ),
              data: (Hotel h) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (h.summary.starRating != null) ...<Widget>[
                    RatingBadge(stars: h.summary.starRating!),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                  Text(
                    h.summary.name.resolve(locale),
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: <Widget>[
                      Icon(AppIcons.location, size: 13, color: c.textSecondary),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          h.summary.cityName.resolve(locale),
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          removeButton,
        ],
      ),
    );
  }
}
