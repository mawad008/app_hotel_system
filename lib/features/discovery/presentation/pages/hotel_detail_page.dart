import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../../app/router/app_routes.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failure_l10n.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/time/hotel_time.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/button_spinner.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/message_view.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/guest_party.dart';
import '../../domain/entities/hotel.dart';
import '../../domain/entities/hotel_facility.dart';
import '../../domain/entities/hotel_guest_details.dart';
import '../../domain/entities/hotel_review_summary.dart';
import '../../domain/entities/room_type_summary.dart';
import '../state/favorite_hotels_controller.dart';
import '../state/guest_party_controller.dart';
import '../state/hotel_detail_provider.dart';
import '../state/room_availability_controller.dart';
import '../state/room_selection_controller.dart';
import '../state/stay_dates_controller.dart';
import '../widgets/detail_premium.dart';
import '../widgets/hotel_location_map.dart';
import '../widgets/hotel_favorite_toggle.dart';
import '../widgets/hotel_share.dart';
import '../widgets/hotel_thumbnail.dart';
import '../../../reservation/presentation/state/create_reservation_controller.dart';

/// `HOTEL_Detail_Premium` (v2 Figma, `02 · Discover & Book`).
///
/// A scrolling column of cards 24px apart on white, 16px gutters:
///
/// 1. the rounded photo **hero** (swipe / tap for full screen / back) with the
///    name, location, review count + rating and a `1/N` counter on it;
/// 2. the **quick-info** card — check-in, check-out, number of rooms and
///    "suitable for" (operator-managed, [HotelGuestDetails]); a hotel with
///    none of those on file falls back to its other real facts (room types,
///    the search's guest party, country, star classification);
/// 3. **why choose** — the hotel's description and its highlight cards;
/// 4. **services & facilities** — the hotel's real, open-catalog facilities;
/// 5. **rooms** — the entry room type as a card (photo, from-price, specs);
/// 6. **reviews** — the overall rating and the per-category bars
///    (the hotel's **dynamic** review categories from `review_summary`);
/// 7. **location** — the location note, the mini-map (only when the hotel has
///    coordinates) and nearby places with travel times;
///
/// then a sticky "from … / night" + `احجز الآن` bar.
///
/// Every row / section is hidden when its data is not on file — nothing is
/// invented. The hero carries the Figma share + favourite buttons (share
/// opens the platform share sheet, copying to the clipboard where there is
/// none; favourites are session-only — no backend wishlist yet). Still
/// pending: "open in Maps" (`mobile-discover-book.md` → Pending).
class HotelDetailPage extends ConsumerWidget {
  const HotelDetailPage({super.key, required this.hotelId});

  final String hotelId;

  void _startBooking(BuildContext context, WidgetRef ref) {
    ref.read(createReservationControllerProvider.notifier).reset();
    ref.read(roomSelectionControllerProvider.notifier).clear();
    ref.read(stayDatesControllerProvider.notifier).clear();
    ref.read(guestPartyControllerProvider.notifier).reset();
    ref.read(roomAvailabilityControllerProvider.notifier).reset();
    context.pushNamed(
      AppRoutes.stayDatesName,
      pathParameters: <String, String>{'hotelId': hotelId},
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<Hotel> hotel = ref.watch(hotelDetailProvider(hotelId));

    return hotel.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: Center(child: LoadingView(label: l10n.stateLoadingTitle)),
      ),
      error: (Object error, StackTrace _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: ErrorView(
            title: l10n.stateErrorTitle,
            message: ErrorMapper.toFailure(error).localizedMessage(l10n),
            actionLabel: l10n.commonBack,
            onAction: () => context.pop(),
          ),
        ),
      ),
      data: (Hotel data) {
        final VoidCallback? book = data.summary.isAvailable
            ? () => _startBooking(context, ref)
            : null;
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: _Body(hotel: data, onBook: book),
          ),
          bottomNavigationBar: _StickyBookingBar(hotel: data, onBook: book),
        );
      },
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.hotel, required this.onBook});

  final Hotel hotel;
  final VoidCallback? onBook;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Locale locale = Localizations.localeOf(context);
    final s = hotel.summary;

    // The hero's photos: `galleryUrls`, falling back to the cover when the
    // hotel has no gallery on file.
    final List<String> photos = hotel.galleryUrls.isNotEmpty
        ? hotel.galleryUrls
        : (hotel.coverUrl != null ? <String>[hotel.coverUrl!] : <String>[]);

    final String location = <String>[
      s.cityName.resolve(locale),
      if (hotel.country != null) hotel.country!.resolve(locale),
    ].where((String p) => p.isNotEmpty).join('، ');

    final String description = hotel.description.resolve(locale);
    // Figma `why-section` subtitle is the hotel's one-line tagline; the long
    // description is the fallback when no tagline is on file.
    final String tagline = s.tagline.resolve(locale);
    final String whySubtitle = tagline.isNotEmpty ? tagline : description;

    const SizedBox gap = SizedBox(height: AppSpacing.space6);

    // A short, bounded column of cards — built eagerly (not a lazy list) so
    // every section is in the tree for screen readers and tests.
    return RefreshIndicator(
      color: context.colors.bgPrimary,
      backgroundColor: context.colors.bgSurface,
      onRefresh: () async {
        try {
          ref.invalidate(hotelDetailProvider(hotel.id));
          await ref.read(hotelDetailProvider(hotel.id).future);
        } on Object {
          // The watched provider renders its normal error state.
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.space4,
          AppSpacing.space2,
          AppSpacing.space4,
          AppSpacing.space6,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            DetailHeroCard(
              entityId: hotel.id,
              photos: photos,
              aspectRatio: 361 / 371,
              // Figma `right-actions`: share nearest the middle, favourite at
              // the outer edge.
              actions: <Widget>[
                DetailHeroButton(
                  icon: AppIcons.share,
                  tooltip: context.l10n.hotelShare,
                  onPressed: () => shareHotel(
                    context,
                    name: s.name.resolve(locale),
                    location: location,
                    latitude: hotel.details.location?.latitude,
                    longitude: hotel.details.location?.longitude,
                  ),
                ),
                _FavoriteButton(hotelId: hotel.id),
              ],
              copy: HotelHeroCopy(
                name: s.name.resolve(locale),
                location: location,
                rating: s.rating,
                reviewCount: s.reviewCount,
              ),
            ),
            gap,
            _QuickInfoCard(hotel: hotel),
            if (whySubtitle.isNotEmpty ||
                hotel.details.highlights.isNotEmpty) ...<Widget>[
              gap,
              _WhyChooseSection(
                description: whySubtitle,
                highlights: hotel.details.highlights,
              ),
            ],
            if (hotel.facilities.isNotEmpty) ...<Widget>[
              gap,
              _FacilitiesSection(facilities: hotel.facilities),
            ],
            if (hotel.entryRoom != null) ...<Widget>[
              gap,
              _RoomsSection(room: hotel.entryRoom!, onBook: onBook),
            ],
            if (hotel.reviewSummary?.hasContent ?? false) ...<Widget>[
              gap,
              _HotelReviewsSection(summary: hotel.reviewSummary!),
            ],
            if (hotel.details.location?.hasContent ?? false) ...<Widget>[
              gap,
              _LocationSection(location: hotel.details.location!),
            ],
          ],
        ),
      ),
    );
  }
}

/// Figma hero `favorite-button`: Hicon `Outline / Heart 3` in `red/600`,
/// filled when the hotel is hearted. Saved on the backend for the signed-in
/// guest ([FavoriteHotelsController]); a signed-out guest signs in first and
/// comes back to this hotel.
class _FavoriteButton extends ConsumerWidget {
  const _FavoriteButton({required this.hotelId});

  final String hotelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final bool favorite = ref.watch(
      favoriteHotelsProvider.select((Set<String> ids) => ids.contains(hotelId)),
    );
    return DetailHeroButton(
      key: const ValueKey<String>('hotel-favorite'),
      icon: favorite ? AppIcons.favoriteActive : AppIcons.favorite,
      iconColor: AppPrimitives.red600,
      selected: favorite,
      tooltip: favorite ? l10n.hotelFavoriteRemove : l10n.hotelFavoriteAdd,
      onPressed: () => toggleHotelFavorite(context, ref, hotelId),
    );
  }
}

/// Figma `quick-info-card` — check-in, check-out, number of rooms, suitable
/// for. Every row is real data; a row whose value the hotel doesn't have on
/// file is omitted. When none of the Figma rows has data, the card shows the
/// hotel's other real facts instead so it is never empty.
class _QuickInfoCard extends ConsumerWidget {
  const _QuickInfoCard({required this.hotel});

  final Hotel hotel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final Locale locale = Localizations.localeOf(context);
    // The guest party of the *current search* (shared search state) — never
    // the hotel's review count or a room's capacity.
    final GuestParty party = ref.watch(guestPartyControllerProvider);
    final HotelGuestDetails d = hotel.details;
    final String? checkIn = formatHotelTime(d.checkInTime, l10n);
    final String? checkOut = formatHotelTime(d.checkOutTime, l10n);

    final List<Widget> figmaRows = <Widget>[
      if (checkIn != null)
        DetailInfoRow(
          icon: AppIcons.checkInOut,
          label: l10n.hotelInfoCheckInLabel,
          value: checkIn,
        ),
      if (checkOut != null)
        DetailInfoRow(
          icon: AppIcons.checkInOut,
          label: l10n.hotelInfoCheckOutLabel,
          value: checkOut,
        ),
      if ((d.roomsCount ?? 0) > 0)
        DetailInfoRow(
          icon: AppIcons.detailRooms,
          label: l10n.hotelInfoRoomsLabel,
          value: l10n.hotelRoomCount(d.roomsCount!),
        ),
      if (d.suitableFor != null)
        DetailInfoRow(
          icon: AppIcons.suitableFor,
          label: l10n.hotelInfoSuitableForLabel,
          value: d.suitableFor!,
        ),
    ];

    final List<Widget> rows = figmaRows.isNotEmpty
        ? figmaRows
        : <Widget>[
            if (hotel.roomTypeCount > 0)
              DetailInfoRow(
                icon: AppIcons.detailRooms,
                label: l10n.hotelInfoRoomTypesLabel,
                value: l10n.hotelRoomTypeCount(hotel.roomTypeCount),
              ),
            DetailInfoRow(
              icon: AppIcons.guests,
              label: l10n.hotelInfoGuestsLabel,
              value: l10n.hotelGuestCount(party.adults + party.children),
            ),
            if (hotel.country != null)
              DetailInfoRow(
                icon: AppIcons.location,
                label: l10n.hotelInfoCountryLabel,
                value: hotel.country!.resolve(locale),
              ),
            // The hotel's own 1-5 star classification (`star_rating`) — a
            // different concept from the guest-review rating in the hero.
            if (hotel.summary.starRating != null)
              DetailInfoRow(
                icon: AppIcons.rating,
                label: l10n.hotelInfoClassificationLabel,
                value: l10n.hotelDetailStarRating(hotel.summary.starRating!),
              ),
          ];

    return DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int i = 0; i < rows.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: AppSpacing.space3),
            rows[i],
          ],
        ],
      ),
    );
  }
}

/// Figma `why-section`: the heading, the hotel's own description, then a
/// horizontal row of highlight cards (152×136, `gold/25` + warm hairline,
/// radius 20, a white 40px icon tile, title 14 Medium, subtitle 12). Both
/// parts are real data and each is omitted when empty.
class _WhyChooseSection extends StatelessWidget {
  const _WhyChooseSection({
    required this.description,
    required this.highlights,
  });

  final String description;
  final List<HotelHighlight> highlights;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DetailSectionHeading(
          title: l10n.hotelWhyChooseHeading,
          subtitle: description.isEmpty ? null : description,
        ),
        if (highlights.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.space4),
          SizedBox(
            height: 136,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: highlights.length,
              separatorBuilder: (BuildContext _, int _) =>
                  const SizedBox(width: AppSpacing.space3),
              itemBuilder: (BuildContext context, int i) =>
                  _HighlightCard(highlight: highlights[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({required this.highlight});

  final HotelHighlight highlight;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppColorTokens c = context.colors;
    return Container(
      width: 152,
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: c.accentWarmBg,
        border: Border.all(color: AppPrimitives.goldHairline),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppPrimitives.white,
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            // Figma: 20px Lucide glyph in `gold/400`.
            child: Icon(
              AppIcons.forDetailKey(highlight.icon),
              size: 20,
              color: c.accentWarm,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          Text(
            highlight.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall?.copyWith(
              fontWeight: AppTypography.medium,
              color: AppPrimitives.stone950,
              height: 18 / 14,
            ),
          ),
          if (highlight.subtitle != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              highlight.subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.labelSmall?.copyWith(
                color: AppPrimitives.stone700,
                height: 20 / 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Figma `location-section`: heading + the operator's location note, then a
/// card with the mini-map (only when the hotel has coordinates — a live
/// OpenStreetMap view of the dashboard-set coordinates with the Figma's white
/// pin; tap opens it full screen) and the nearby places (`mist` 42px rows,
/// 14 SemiBold, radius 16).
class _LocationSection extends StatelessWidget {
  const _LocationSection({required this.location});

  final HotelLocation location;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme text = Theme.of(context).textTheme;
    final bool hasCard =
        location.hasCoordinates || location.nearbyPlaces.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DetailSectionHeading(
          title: l10n.hotelLocationHeading,
          subtitle: location.note,
        ),
        if (hasCard) ...<Widget>[
          const SizedBox(height: AppSpacing.space4),
          DetailCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (location.hasCoordinates)
                  Semantics(
                    image: true,
                    button: true,
                    label: l10n.hotelLocationMapSemantics,
                    hint: l10n.hotelLocationMapOpenHint,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                      child: AspectRatio(
                        aspectRatio: 329 / 180,
                        child: Stack(
                          fit: StackFit.expand,
                          children: <Widget>[
                            HotelLocationMap(
                              latitude: location.latitude!,
                              longitude: location.longitude!,
                            ),
                            // The preview is non-interactive; a tap opens the
                            // pannable/zoomable map.
                            Material(
                              type: MaterialType.transparency,
                              child: InkWell(
                                key: const ValueKey<String>('hotel-location-map'),
                                onTap: () => Navigator.of(context).push<void>(
                                  HotelMapPage.route(
                                    latitude: location.latitude!,
                                    longitude: location.longitude!,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                for (
                  int i = 0;
                  i < location.nearbyPlaces.length;
                  i++
                ) ...<Widget>[
                  if (i > 0 || location.hasCoordinates)
                    SizedBox(height: i == 0 ? AppSpacing.space4 : 10),
                  _NearbyPlaceRow(place: location.nearbyPlaces[i], text: text),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _NearbyPlaceRow extends StatelessWidget {
  const _NearbyPlaceRow({required this.place, required this.text});

  final NearbyPlace place;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AppColorTokens c = context.colors;
    // Travel time (the Figma's format) wins; otherwise the distance.
    final String? distance = place.distance == null
        ? null
        : NumberFormat(
            '#,##0.#',
            Localizations.localeOf(context).toLanguageTag(),
          ).format(place.distance);
    final String label = switch (place) {
      NearbyPlace(travelMinutes: final int minutes) => l10n.hotelNearbyPlace(
        place.name,
        minutes,
      ),
      NearbyPlace(distanceUnit: DistanceUnit.kilometers) when distance != null =>
        l10n.hotelNearbyPlaceKm(place.name, distance),
      NearbyPlace(distanceUnit: DistanceUnit.meters) when distance != null =>
        l10n.hotelNearbyPlaceMeters(place.name, distance),
      _ => place.name,
    };
    return Container(
      constraints: const BoxConstraints(minHeight: 42),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: AppPrimitives.mist,
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            AppIcons.forDetailKey(
              place.icon,
              fallback: AppIcons.forNearbyCategory(place.category),
            ),
            size: 18,
            color: c.accentWarm,
          ),
          const SizedBox(width: 10),
          // Figma renders these rows at 12 Regular (derived glyphs), not the
          // stale 14 SemiBold on the text node.
          Expanded(
            child: Text(
              label,
              style: text.labelSmall?.copyWith(
                fontWeight: AppTypography.regular,
                color: c.textPrimary,
                height: 15 / 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Figma `facilities-section` — rendered from the backend's own label for
/// each facility (the catalog is open/admin-managed, so a hardcoded
/// key->label map would silently drop a newly-added facility), two per row.
class _FacilitiesSection extends StatelessWidget {
  const _FacilitiesSection({required this.facilities});

  final List<HotelFacility> facilities;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final Locale locale = Localizations.localeOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DetailSectionHeading(
          title: l10n.hotelDetailAmenities,
          subtitle: l10n.hotelDetailAmenitiesSubtitle,
        ),
        const SizedBox(height: AppSpacing.space4),
        DetailCard(
          child: DetailTileGrid(
            gap: AppSpacing.space3,
            children: <Widget>[
              // The operator's dashboard icon key selects the glyph; unknown
              // keys get a neutral marker. The Figma tile size and gold tint
              // stay in DetailFacilityPill regardless of the selected glyph.
              for (final HotelFacility facility in facilities)
                DetailFacilityPill(
                  icon: AppIcons.forFacility(facility.icon, facility.key),
                  label: facility.label.resolve(locale),
                  description: facility.description?.resolve(locale),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Figma `rooms-section` — the entry (cheapest bookable) room type as a card:
/// photo, name, "from" price, spec chips and `عرض الغرف المتاحة` (which
/// starts the booking flow at the stay dates, like the sticky CTA).
class _RoomsSection extends ConsumerWidget {
  const _RoomsSection({required this.room, required this.onBook});

  final RoomTypeSummary room;
  final VoidCallback? onBook;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final Locale locale = Localizations.localeOf(context);
    final TextTheme text = Theme.of(context).textTheme;
    final AppColorTokens c = context.colors;
    final bool useDummyData = ref.watch(appConfigProvider).useDummyData;

    final List<String> chips = <String>[
      room.bedType.resolve(locale),
      if (room.view != null) room.view!.resolve(locale),
      if (room.areaSqm != null) l10n.roomAreaSqm(room.areaSqm!),
      l10n.hotelGuestCount(room.maxOccupancy),
    ].where((String t) => t.isNotEmpty).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DetailSectionHeading(
          title: l10n.hotelRoomsHeading,
          subtitle: l10n.hotelRoomsSubtitle,
        ),
        const SizedBox(height: AppSpacing.space4),
        DetailCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AspectRatio(
                aspectRatio: 329 / 220,
                child: HotelThumbnail(
                  imageUrl: room.coverUrl,
                  // Dummy data has no per-room photo; the Figma seed keeps
                  // the demo real. Real-API rooms never get a faked photo.
                  seed: useDummyData ? room.id : null,
                  width: double.infinity,
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      room.name.resolve(locale),
                      style: text.bodySmall?.copyWith(
                        color: c.textPrimary,
                        height: 18 / 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        l10n.hotelPriceFromLabel,
                        style: text.labelSmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w300,
                          color: c.textLabel,
                          height: 14 / 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Figma `Price / Size=Medium`: 17 Bold (21 line), 15px
                      // riyal mark.
                      MoneyText(
                        room.nightlyRate.amount, currency: room.nightlyRate.currency,
                        semanticsLabel: l10n.priceFrom(MoneyText.digits(context, room.nightlyRate.amount)),
                        style: AppTypography.numMd(c.textPrimary).copyWith(
                          fontWeight: AppTypography.bold,
                          height: 21 / 17,
                        ),
                        markSize: 15,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space2),
              Wrap(
                spacing: AppSpacing.space2,
                runSpacing: AppSpacing.space2,
                children: <Widget>[
                  for (final String chip in chips) _SpecChip(label: chip),
                ],
              ),
              const SizedBox(height: AppSpacing.space4),
              PrimaryButton(
                label: l10n.hotelRoomsCta,
                size: AppButtonSize.small,
                onPressed: onBook,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Figma room-card chip: `gold/25` pill, 10/6 padding, 12 Regular `stone/600`.
class _SpecChip extends StatelessWidget {
  const _SpecChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.accentWarmBg,
        borderRadius: const BorderRadius.all(Radius.circular(999)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: AppPrimitives.stone600, height: 15 / 12),
      ),
    );
  }
}

/// Figma `reviews-section` — built entirely from the hotel's live
/// `review_summary`: the published overall average + review count, then one
/// `Rating Row` per **rated** category, in the order the backend sent. The
/// categories are dashboard-managed per hotel, so their number and names are
/// whatever the API returns (2, 4, 8, …); nothing is hardcoded or
/// fabricated. The section is hidden while the hotel has no ratings.
class _HotelReviewsSection extends StatelessWidget {
  const _HotelReviewsSection({required this.summary});

  final HotelReviewSummary summary;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme text = Theme.of(context).textTheme;
    final AppColorTokens c = context.colors;
    final List<ReviewCategoryScore> rows = summary.ratedCategories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DetailSectionHeading(
          title: l10n.hotelDetailReviewsHeading,
          subtitle: l10n.hotelReviewsSubtitle,
        ),
        const SizedBox(height: AppSpacing.space4),
        DetailCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    l10n.hotelOverallRating,
                    style: text.labelSmall?.copyWith(color: c.textLabel),
                  ),
                  if (summary.average != null) ...<Widget>[
                    const SizedBox(width: 6),
                    _OverallBadge(rating: summary.average!),
                  ],
                  const Spacer(),
                  Text(
                    l10n.hotelReviewCount(summary.count),
                    style: text.labelMedium?.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
              // Figma: 16 under the header row, 12 between rating rows.
              for (int i = 0; i < rows.length; i++) ...<Widget>[
                SizedBox(
                  height: i == 0 ? AppSpacing.space4 : AppSpacing.space3,
                ),
                DetailRatingRow(
                  label: rows[i].label,
                  value: rows[i].average,
                  icon: rows[i].icon == null
                      ? null
                      : AppIcons.forDetailKey(rows[i].icon),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Figma `Rating Badge / Compact` in the reviews card: `gold/25` pill, gold
/// score + star.
class _OverallBadge extends StatelessWidget {
  const _OverallBadge({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    final AppColorTokens c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.accentWarmBg,
        borderRadius: const BorderRadius.all(Radius.circular(999)),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              context.l10n.hotelRatingValue(rating),
              style: AppTypography.numXs(c.accentWarm),
            ),
            const SizedBox(width: 6),
            // Figma `Rating Badge / Compact`: gold score, dark 15px star.
            Icon(AppIcons.homeRatingStar, size: 15, color: c.textPrimary),
          ],
        ),
      ),
    );
  }
}

/// Figma `sticky-booking-bar`: "ابتداءً من" (13 Medium) over the nightly
/// from-price (18 Bold) at the start, and a 48px `احجز الآن` at the end.
class _StickyBookingBar extends StatelessWidget {
  const _StickyBookingBar({required this.hotel, required this.onBook});

  final Hotel hotel;
  final VoidCallback? onBook;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme text = Theme.of(context).textTheme;
    final AppColorTokens c = context.colors;
    final num from = hotel.summary.nightlyRateFrom.amount;

    return DetailBottomBar(
      child: Row(
        children: <Widget>[
          // Figma: price block 132 / CTA 217 of the 361 row.
          Expanded(
            flex: 132,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  l10n.hotelPriceFromLabel,
                  style: text.labelMedium?.copyWith(
                    color: c.textLabel,
                    height: 16 / 13,
                  ),
                ),
                const SizedBox(height: 2),
                MoneyText(
                  from,
                  currency: hotel.summary.nightlyRateFrom.currency,
                  suffix: l10n.priceNightSuffix,
                  semanticsLabel: l10n.priceFrom(MoneyText.digits(context, from)),
                  // Figma: 18 Bold on a 23 line.
                  style: AppTypography.numMd(c.textPrimary, size: 18).copyWith(
                    fontWeight: AppTypography.bold,
                    height: 23 / 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            flex: 217,
            child: PrimaryButton(label: l10n.hotelBookNow, onPressed: onBook),
          ),
        ],
      ),
    );
  }
}
