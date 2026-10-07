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
import '../../domain/entities/hotel.dart';
import '../../domain/entities/hotel_summary.dart';
import '../state/favorite_hotels_controller.dart';
import '../state/hotel_detail_provider.dart';
import '../widgets/hotel_favorite_toggle.dart';
import '../widgets/hotel_thumbnail.dart';
import '../widgets/rating_badge.dart';

/// Settles once the guest's saved ids have been fetched, so the page shows a
/// loader rather than a momentary "no favourites" state.
final _favoritesReadyProvider = FutureProvider.autoDispose<void>(
  (Ref ref) => ref.watch(favoriteHotelsProvider.notifier).loaded,
);

/// "المفضلة": the hotels the guest saved with the heart on Hotel / Room
/// Detail. Driven by [favoriteHotelsProvider], so a heart toggled anywhere
/// (including undo from the snackbar) updates this list immediately. Each
/// row loads its hotel through [hotelDetailProvider] — the same fetch the
/// detail screen uses — and can open it or remove it from favourites.
class FavoriteHotelsPage extends ConsumerWidget {
  const FavoriteHotelsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final bool ready = ref.watch(_favoritesReadyProvider).hasValue;
    final List<String> ids = ref.watch(favoriteHotelsProvider).toList();

    return Scaffold(
      appBar: HotelAppBar(
        title: l10n.favoritesTitle,
        fallbackLocation: AppRoutes.account,
      ),
      body: SafeArea(
        child: !ready
            ? Center(child: LoadingView(label: l10n.stateLoadingTitle))
            : ids.isEmpty
            ? MessageView(
                icon: AppIcons.favorite,
                title: l10n.favoritesEmptyTitle,
                message: l10n.favoritesEmptyBody,
                actionLabel: l10n.favoritesBrowse,
                onAction: () => context.goNamed(AppRoutes.discoverName),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.pageGutter),
                itemCount: ids.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (BuildContext context, int index) {
                  if (index == 0) {
                    return InfoBanner(
                      tone: InfoBannerTone.info,
                      title: l10n.favoritesBannerTitle,
                      message: l10n.favoritesBannerBody,
                    );
                  }
                  final String id = ids[index - 1];
                  return _FavoriteHotelTile(key: ValueKey<String>(id), hotelId: id);
                },
              ),
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
      onPressed: () => toggleHotelFavorite(context, ref, hotelId, offerViewAction: false),
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
                style: theme.textTheme.bodyMedium?.copyWith(color: c.textSecondary),
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
