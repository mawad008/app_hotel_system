import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/localization/numerals.dart';
import '../../../../core/time/hotel_time.dart';
import '../../../../core/time/stay_date_format.dart';
import '../../domain/entities/favorite_room.dart';
import '../../domain/entities/hotel_facility.dart';
import '../../domain/entities/hotel_guest_details.dart';
import '../../domain/entities/localized_text.dart';
import '../../domain/entities/money.dart';
import '../../../app_content/presentation/state/app_content_providers.dart';
import '../../../../core/presentation/ui_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/time/clock.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/message_view.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../domain/entities/availability_request.dart';
import '../../domain/entities/availability_result.dart';
import '../../domain/entities/available_room.dart';
import '../../domain/entities/guest_party.dart';
import '../../domain/entities/hotel.dart';
import '../../domain/entities/room_selection.dart';
import '../../domain/entities/room_type_summary.dart';
import '../../domain/entities/stay_range.dart';
import '../discovery_l10n.dart';
import '../state/guest_party_controller.dart';
import '../state/hotel_detail_provider.dart';
import '../state/room_availability_controller.dart';
import '../state/room_selection_controller.dart';
import '../state/stay_dates_controller.dart';
import '../state/favorite_rooms_controller.dart';
import '../widgets/detail_premium.dart';
import '../widgets/hotel_favorite_toggle.dart';
import '../widgets/hotel_share.dart';
import '../widgets/price_breakdown_card.dart' show formatTaxRate;
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/pull_to_refresh.dart';

/// `ROOM_Detail_Premium` (v2 Figma, `08 · Room selection & stay actions`) —
/// one room type in full, as a column of cards 24px apart:
///
/// 1. the rounded photo **hero** (swipe / tap for full screen / back, `1/N`);
/// 2. the **room info** card — name (18 Bold) + nightly rate, and 2-up spec
///    tiles (size, guests, bed, and the view when the room has one);
/// 3. **your booking details** — nights / dates / guests tiles, the nightly
///    rate row and the stay total;
/// 4. **the price includes** — breakfast / free cancellation / Wi-Fi, when the
///    room has them;
/// 5. **room facilities** — the room's amenities as icon tiles;
/// 6. **about the room** — the description, collapsible;
/// 7. **policies** — the cancellation policy;
///
/// over a bottom bar with the stay total and the unchanged select / deselect
/// CTA. Selecting sets the [RoomSelection] and returns to the list; nothing
/// is booked.
///
/// Everything is dashboard-managed: the room badge (`tag`), the "price
/// includes" items (`inclusions` + breakfast / free-cancellation flags), the
/// facility grid (the room's catalog `facilities`, label + icon), the hotel's
/// "prices include taxes / service fee" flags (the "شاملة" rows and the
/// final-price note appear only when the hotel sets them) and its check-in /
/// check-out times. A section with no data is hidden, never invented. The
/// hero shares the hotel and uses its server-backed favourite.
class RoomDetailPage extends ConsumerWidget {
  const RoomDetailPage({
    super.key,
    required this.hotelId,
    required this.roomTypeId,
  });

  final String hotelId;
  final String roomTypeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final DateTime today = ref.today();
    final StayRange? stay = ref
        .watch(stayDatesControllerProvider)
        .rangeAgainst(today);
    final party = ref.watch(guestPartyControllerProvider);
    final RoomAvailabilityState availability = ref.watch(
      roomAvailabilityControllerProvider,
    );
    final AsyncValue<Hotel> hotelAsync = ref.watch(
      hotelDetailProvider(hotelId),
    );
    final RoomSelection? selection = ref.watch(roomSelectionControllerProvider);

    final AvailableRoom? room = switch (availability.result) {
      UiSuccess<AvailabilityResult>(:final AvailabilityResult data) =>
        data.rooms
            .where((AvailableRoom r) => r.roomType.id == roomTypeId)
            .firstOrNull,
      _ => null,
    };

    // Opened straight from a saved room (Favourites) or a deep link: fetch
    // availability for the guest's current dates instead of relying on the
    // rooms list having loaded it, and wait for it rather than flash "no
    // room". Without dates there is nothing to price, so ask for them.
    if (stay == null) {
      return Scaffold(
        appBar: HotelAppBar(title: l10n.roomDetailsTitle),
        body: MessageView(
          icon: AppIcons.calendar,
          title: l10n.roomDetailNeedsDatesTitle,
          message: l10n.roomDetailNeedsDatesBody,
          actionLabel: l10n.roomDetailChooseDates,
          onAction: () => context.pushNamed(
            AppRoutes.stayDatesName,
            pathParameters: <String, String>{'hotelId': hotelId},
          ),
        ),
      );
    }
    final AvailabilityRequest request = AvailabilityRequest(
      hotelId: hotelId,
      stay: stay,
      party: party,
    );
    // A failed fetch for these exact criteria is not retried in a loop; it
    // falls through to the "no room" state below.
    final bool failed =
        availability.request == request &&
        availability.result is UiFailure<AvailabilityResult>;
    final bool fresh = availability.isFreshFor(request);
    if (!fresh && !failed) {
      if (availability.result is! UiLoading<AvailabilityResult>) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => ref
              .read(roomAvailabilityControllerProvider.notifier)
              .load(request),
        );
      }
      return Scaffold(
        appBar: HotelAppBar(title: l10n.roomDetailsTitle),
        body: Center(child: LoadingView(label: l10n.stateLoadingTitle)),
      );
    }
    Future<void> refresh() => refreshAll(<Future<Object?>>[
      ref.read(roomAvailabilityControllerProvider.notifier).refresh(),
      ref.refresh(hotelDetailProvider(hotelId).future),
    ]);

    // A pull-to-refresh keeps the shown hotel; only a first load waits.
    if (hotelAsync.isLoading && !hotelAsync.hasValue) {
      return Scaffold(
        appBar: HotelAppBar(title: l10n.roomDetailsTitle),
        body: Center(child: LoadingView(label: l10n.stateLoadingTitle)),
      );
    }

    if (room == null || hotelAsync.value == null) {
      return Scaffold(
        appBar: HotelAppBar(title: l10n.roomDetailsTitle),
        body: PullToRefresh(
          onRefresh: refresh,
          child: MessageView(
            icon: AppIcons.room,
            title: l10n.reviewNoSelectionTitle,
            message: l10n.roomsNoResultsBody,
            actionLabel: l10n.reviewBackToRooms,
            onAction: () => context.pop(),
          ),
        ),
      );
    }

    final Hotel hotel = hotelAsync.value!;
    final bool isSelected =
        selection != null &&
        selection.matches(request) &&
        selection.roomTypeId == roomTypeId;

    void select() {
      ref
          .read(roomSelectionControllerProvider.notifier)
          .select(
            RoomSelection.fromAvailableRoom(
              room: room,
              hotelId: hotel.id,
              hotelName: hotel.name,
              stay: stay,
              party: party,
            ),
          );
      // Figma routing: ROOM_Detail "اختيار هذه الغرفة" → booking summary
      // (the v2 rooms list has no Continue bar). BOOKING_GuestDetails is
      // covered by the deferred sign-in + profile step the summary routes
      // through, since the booker is the guest account itself. Replacing
      // this page keeps "back" on the summary returning to the rooms list.
      context.pushReplacementNamed(
        AppRoutes.roomSelectionReviewName,
        pathParameters: <String, String>{'hotelId': hotel.id},
      );
    }

    void deselect() {
      ref.read(roomSelectionControllerProvider.notifier).clear();
      context.pop();
    }

    final Money? serviceFee =
        hotel.details.serviceFee?.feeFor(room.stayTotal(stay.nights));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: PullToRefresh(
          onRefresh: refresh,
          child: _Body(room: room, stay: stay, party: party, hotel: hotel),
        ),
      ),
      bottomNavigationBar: DetailBottomBar(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _CurrentPriceRow(
              room: room,
              stay: stay,
              party: party,
              serviceFee: serviceFee,
              tax: hotel.details.taxFor(
                room.stayTotal(stay.nights),
                serviceFee: serviceFee,
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            if (isSelected) ...<Widget>[
              PrimaryButton(
                label: l10n.roomSelected,
                icon: AppIcons.check,
                onPressed: () => context.pop(),
              ),
              const SizedBox(height: AppSpacing.xs),
              SecondaryButton(
                label: l10n.roomRemoveSelection,
                onPressed: deselect,
              ),
            ] else
              PrimaryButton(
                label: room.isAvailable
                    ? l10n.roomSelectThisRoom
                    : l10n.roomSoldOut,
                onPressed: room.isAvailable ? select : null,
              ),
          ],
        ),
      ),
    );
  }
}

/// Figma `bottom booking bar` price row: "السعر الحالي" over "N nights · M
/// guests" at the start, the stay total at the end.
class _CurrentPriceRow extends StatelessWidget {
  const _CurrentPriceRow({
    required this.room,
    required this.stay,
    required this.party,
    this.serviceFee,
    this.tax,
  });

  final AvailableRoom room;
  final StayRange stay;
  final GuestParty party;

  /// The hotel's service fee for this stay, included in the total.
  final Money? serviceFee;

  /// The hotel's tax on stay + fee (rates exclude taxes), included in the total.
  final Money? tax;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme text = Theme.of(context).textTheme;
    final AppColorTokens c = context.colors;
    // What the guest pays: the stay plus the hotel's service fee and tax.
    final num total = room.stayTotal(stay.nights).amount +
        (serviceFee?.amount ?? 0) +
        (tax?.amount ?? 0);
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                l10n.roomCurrentPrice,
                style: text.bodySmall?.copyWith(color: c.textSecondary),
              ),
              Text(
                '${l10n.stayNights(stay.nights)} · '
                '${l10n.hotelGuestCount(party.total)}',
                style: text.bodySmall?.copyWith(color: c.textPrimary),
              ),
            ],
          ),
        ),
        MoneyText(
          total,
          currency: room.nightlyRate.currency,
          semanticsLabel: l10n.priceStayTotal(MoneyText.digits(context, total)),
          style: text.titleLarge?.copyWith(color: c.textPrimary),
        ),
      ],
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.room,
    required this.stay,
    required this.party,
    required this.hotel,
  });

  final AvailableRoom room;
  final StayRange stay;
  final GuestParty party;
  final Hotel hotel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final Locale locale = Localizations.localeOf(context);
    final RoomTypeSummary type = room.roomType;

    // The room type's real gallery photos (`gallery[].url` on the backend
    // room-type / availability resource) — empty until the hotel uploads
    // media for this room type, which renders the branded placeholder rather
    // than a stock/seeded photo.
    final List<String> photos = type.galleryUrls;

    // "السعر يشمل": breakfast (flag), the operator's items, free
    // cancellation (flag) — each with the Figma tick-circle glyph.
    final List<String> included = <String>[
      if (type.breakfastIncluded) l10n.roomBreakfastIncluded,
      for (final LocalizedText item in type.inclusions) item.resolve(locale),
      if (type.refundable) l10n.roomFreeCancellation,
    ];

    // The facility grid: the room's catalog facilities (label + operator
    // icon). Offline fixtures without catalog data fall back to the legacy
    // amenity set.
    final List<(IconData, String)> facilities = type.facilities.isNotEmpty
        ? <(IconData, String)>[
            for (final HotelFacility f in type.facilities)
              (AppIcons.forFacility(f.icon, f.key), f.label.resolve(locale)),
          ]
        : <(IconData, String)>[
            for (final RoomAmenity a in type.amenities)
              if (a != RoomAmenity.freeWifi)
                (_amenityIcon(a), l10n.roomAmenityLabel(a)),
          ];

    final HotelGuestDetails details = hotel.details;
    final String? checkIn = formatHotelTime(details.checkInTime, l10n);
    final String? checkOut = formatHotelTime(details.checkOutTime, l10n);

    final String description = type.description.resolve(locale);
    // Figma `content`: cards 16px apart.
    const SizedBox gap = SizedBox(height: AppSpacing.space4);

    // A short, bounded column of cards — built eagerly (not a lazy list) so
    // every section is in the tree for screen readers and tests.
    return SingleChildScrollView(
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
            entityId: type.id,
            photos: photos,
            aspectRatio: 361 / 358,
            centerCounter: true,
            backFallbackLocation: AppRoutes.hotelDetail.replaceFirst(
              ':hotelId',
              hotel.id,
            ),
            actions: <Widget>[
              DetailHeroButton(
                icon: AppIcons.share,
                tooltip: l10n.hotelShare,
                onPressed: () => shareHotel(
                  context,
                  name: hotel.name.resolve(locale),
                  location: hotel.country?.resolve(locale) ?? '',
                  latitude: hotel.details.location?.latitude,
                  longitude: hotel.details.location?.longitude,
                ),
              ),
              _RoomFavoriteButton(
                room: FavoriteRoom(
                  roomTypeId: type.id,
                  hotelId: hotel.id,
                  name: type.name,
                  coverUrl: type.galleryUrls.firstOrNull,
                ),
              ),
            ],
          ),
          gap,
          _RoomInfoCard(room: room),
          gap,
          _BookingDetailsCard(
            room: room,
            stay: stay,
            party: party,
            taxesIncluded: details.pricesIncludeTaxes,
            serviceFee: details.serviceFee?.feeFor(room.stayTotal(stay.nights)),
            taxRate: details.taxRate,
            tax: details.taxFor(
              room.stayTotal(stay.nights),
              serviceFee: details.serviceFee?.feeFor(room.stayTotal(stay.nights)),
            ),
          ),
          if (included.isNotEmpty) ...<Widget>[
            gap,
            DetailCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    l10n.roomIncludedHeading,
                    style: detailTitleStyle(context),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  for (int i = 0; i < included.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(height: AppSpacing.space3),
                    _IncludedRow(
                      icon: AppIcons.successOutline,
                      label: included[i],
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (facilities.isNotEmpty) ...<Widget>[
            gap,
            DetailCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    l10n.roomDetailAmenitiesHeading,
                    style: detailTitleStyle(context),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  DetailTileGrid(
                    columns: 3,
                    gap: AppSpacing.space2,
                    children: <Widget>[
                      for (final (IconData icon, String label) in facilities)
                        _FacilityTile(icon: icon, label: label),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (description.isNotEmpty) ...<Widget>[
            gap,
            _AboutCard(text: description),
          ],
          gap,
          DetailCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  l10n.roomPoliciesHeading,
                  style: detailTitleStyle(context),
                ),
                const SizedBox(height: AppSpacing.space4),
                _PolicyTile(
                  title: l10n.roomDetailCancellationHeading,
                  body: switch ((
                    type.refundable,
                    ref
                        .watch(appContentProvider)
                        .valueOrNull
                        ?.freeCancellationHours,
                  )) {
                    (false, _) => l10n.roomPolicyNonRefundable,
                    (true, final int hours) => l10n.roomPolicyRefundable(hours),
                    (true, null) => l10n.roomPolicyRefundableShort,
                  },
                ),
                if (checkIn != null) ...<Widget>[
                  const SizedBox(height: 10),
                  _PolicyTile(
                    icon: AppIcons.time,
                    title: l10n.roomPolicyCheckInTitle,
                    body: context.localDigits(
                      l10n.roomPolicyCheckInBody(checkIn),
                    ),
                  ),
                ],
                if (checkOut != null) ...<Widget>[
                  const SizedBox(height: 10),
                  _PolicyTile(
                    icon: AppIcons.time,
                    title: l10n.roomPolicyCheckOutTitle,
                    body: context.localDigits(
                      l10n.roomPolicyCheckOutBody(checkOut),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Room amenity → glyph (the [RoomAmenity] set is fixed, so every value has a
/// deliberate icon).
IconData _amenityIcon(RoomAmenity amenity) => switch (amenity) {
  RoomAmenity.freeWifi => AppIcons.wifi,
  RoomAmenity.airConditioning => AppIcons.airConditioning,
  RoomAmenity.cityView => AppIcons.cityView,
  RoomAmenity.balcony => AppIcons.balcony,
  RoomAmenity.kitchenette => AppIcons.coffee,
};

/// Figma `room info card`: name (18 Bold / 28) + the nightly rate, then
/// 2-up spec tiles.
class _RoomInfoCard extends StatelessWidget {
  const _RoomInfoCard({required this.room});

  final AvailableRoom room;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final Locale locale = Localizations.localeOf(context);
    final TextTheme text = Theme.of(context).textTheme;
    final RoomTypeSummary type = room.roomType;

    // Figma order from the start: guests · area, then view · bed.
    final List<Widget> facts = <Widget>[
      _FactTile(
        icon: AppIcons.guests,
        label: l10n.roomSpecGuests,
        value: l10n.hotelGuestCount(type.maxOccupancy),
      ),
      if (type.areaSqm != null)
        _FactTile(
          icon: AppIcons.area,
          label: l10n.roomSpecArea,
          value: l10n.roomAreaSqm(type.areaSqm!),
        ),
      // The room type's own view (`view`) when on file; otherwise the
      // legacy `city_view` amenity.
      if (type.view != null && type.view!.resolve(locale).isNotEmpty)
        _FactTile(
          icon: AppIcons.cityView,
          label: l10n.roomSpecView,
          value: type.view!.resolve(locale),
        )
      else if (type.amenities.contains(RoomAmenity.cityView))
        _FactTile(
          icon: AppIcons.cityView,
          label: l10n.roomSpecView,
          value: l10n.roomAmenityLabel(RoomAmenity.cityView),
        ),
      if (type.bedType.resolve(locale).isNotEmpty)
        _FactTile(
          icon: AppIcons.bed,
          label: l10n.roomSpecBed,
          value: type.bedType.resolve(locale),
        ),
      for (final RoomTypeSpec spec in type.customSpecs)
        _FactTile(
          icon: AppIcons.infoOutline,
          label: spec.label,
          value: spec.value,
        ),
    ];

    return DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(type.name.resolve(locale), style: text.titleLarge),
                    if (type.tag != null &&
                        type.tag!.resolve(locale).isNotEmpty) ...<Widget>[
                      const SizedBox(height: 6),
                      _RoomTag(label: type.tag!.resolve(locale)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              MoneyText(
                room.nightlyRate.amount,
                currency: room.nightlyRate.currency,
                suffix: l10n.priceNightSuffix,
                semanticsLabel: l10n.pricePerNight(
                  MoneyText.digits(context, room.nightlyRate.amount),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space4),
          DetailTileGrid(gap: 9, children: facts),
        ],
      ),
    );
  }
}

/// Figma room fact tile: `#F6F6F6`, radius 16, a 32px white icon disc, the
/// label (14) over the value (12, `text/secondary`).
class _FactTile extends StatelessWidget {
  const _FactTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppColorTokens c = context.colors;
    return Container(
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppPrimitives.mist,
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Row(
        children: <Widget>[
          _IconDisc(icon: icon, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  label,
                  style: text.bodySmall?.copyWith(color: c.textPrimary),
                ),
                Text(
                  value,
                  style: text.labelSmall?.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A white icon disc (Figma room cards' icon holders).
class _IconDisc extends StatelessWidget {
  const _IconDisc({required this.icon, required this.size, this.color});

  final IconData icon;
  final double size;

  /// Glyph colour; defaults to `text/primary`.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppPrimitives.white,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: size / 2,
        color: color ?? context.colors.textPrimary,
      ),
    );
  }
}

/// Figma `pricing card` ("تفاصيل حجزك"): three stay tiles, the nightly-rate
/// row, the "شاملة" tax row when the hotel says its rates include taxes,
/// the hotel's service fee (amount) when it charges one, the tax row when
/// its rates exclude taxes and it has a tax rate, the stay total (fee + tax
/// included) and — when taxes are included and there is no fee — the
/// green "final price, no extra fees" note.
class _BookingDetailsCard extends StatelessWidget {
  const _BookingDetailsCard({
    required this.room,
    required this.stay,
    required this.party,
    this.taxesIncluded = false,
    this.serviceFee,
    this.tax,
    this.taxRate,
  });

  final AvailableRoom room;
  final StayRange stay;
  final GuestParty party;

  /// The hotel's "prices include taxes" flag (dashboard).
  final bool taxesIncluded;

  /// The hotel's booking service fee for this stay; `null` when it has none.
  final Money? serviceFee;

  /// The hotel's tax on stay + fee when its rates exclude taxes, and its %.
  final Money? tax;
  final num? taxRate;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme text = Theme.of(context).textTheme;
    final AppColorTokens c = context.colors;
    final Locale locale = Localizations.localeOf(context);
    // What the guest pays: the stay plus the hotel's service fee and tax.
    final num total = room.stayTotal(stay.nights).amount +
        (serviceFee?.amount ?? 0) +
        (tax?.amount ?? 0);

    Widget includedRow(String label) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.space3),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: text.bodySmall?.copyWith(color: c.textPrimary),
            ),
          ),
          Text(
            l10n.roomPriceIncludedValue,
            style: text.labelSmall?.copyWith(color: c.accentWarmFg),
          ),
        ],
      ),
    );

    Widget tile(String label, String value) => Expanded(
      child: Container(
        constraints: const BoxConstraints(minHeight: 70),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.bgSubtle,
          borderRadius: const BorderRadius.all(Radius.circular(16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              label,
              style: text.labelSmall?.copyWith(color: c.textSecondary),
            ),
            Text(value, style: text.bodySmall?.copyWith(color: c.textPrimary)),
          ],
        ),
      ),
    );

    return DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.roomBookingDetailsHeading,
            style: detailTitleStyle(context),
          ),
          const SizedBox(height: AppSpacing.space4),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Figma order from the start: guests · dates · duration.
                tile(l10n.roomStayGuests, l10n.hotelGuestCount(party.total)),
                const SizedBox(width: 8),
                tile(
                  l10n.roomStayDates,
                  context.localDigits(formatStayDateRange(locale, stay)),
                ),
                const SizedBox(width: 8),
                tile(l10n.roomStayDuration, l10n.stayNights(stay.nights)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  l10n.roomNightlyPriceLabel,
                  style: text.bodySmall?.copyWith(color: c.textPrimary),
                ),
              ),
              MoneyText(
                room.nightlyRate.amount,
                currency: room.nightlyRate.currency,
                suffix: l10n.priceNightSuffix,
                semanticsLabel: l10n.pricePerNight(
                  MoneyText.digits(context, room.nightlyRate.amount),
                ),
                markSize: 12,
                style: text.bodySmall?.copyWith(color: c.textPrimary),
              ),
            ],
          ),
          if (taxesIncluded) includedRow(l10n.roomTaxesLabel),
          if (serviceFee != null) ...<Widget>[
            const SizedBox(height: AppSpacing.space3),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    l10n.bookingServiceFee,
                    style: text.bodySmall?.copyWith(color: c.textPrimary),
                  ),
                ),
                MoneyText(
                  serviceFee!.amount,
                  currency: serviceFee!.currency,
                  markSize: 12,
                  style: text.bodySmall?.copyWith(color: c.textPrimary),
                ),
              ],
            ),
          ],
          if (tax != null) ...<Widget>[
            const SizedBox(height: AppSpacing.space3),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    l10n.bookingTaxRow(formatTaxRate(taxRate)),
                    style: text.bodySmall?.copyWith(color: c.textPrimary),
                  ),
                ),
                MoneyText(
                  tax!.amount,
                  currency: tax!.currency,
                  markSize: 12,
                  style: text.bodySmall?.copyWith(color: c.textPrimary),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.space4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: c.bgSubtle,
              borderRadius: const BorderRadius.all(Radius.circular(16)),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    l10n.roomTotalLabel,
                    style: text.bodySmall?.copyWith(color: c.accentWarmFg),
                  ),
                ),
                MoneyText(
                  total,
                  currency: room.nightlyRate.currency,
                  semanticsLabel: l10n.priceStayTotal(
                    MoneyText.digits(context, total),
                  ),
                  style: text.titleMedium?.copyWith(color: c.textPrimary),
                ),
              ],
            ),
          ),
          // "No extra fees" is only true when taxes are in the rate and the
          // hotel charges no separate service fee.
          if (taxesIncluded && serviceFee == null) ...<Widget>[
            const SizedBox(height: AppSpacing.space4),
            _FinalPriceNote(text: l10n.roomFinalPriceNote),
          ],
        ],
      ),
    );
  }
}

/// Figma `final price note`: success-tinted, radius 16, a 28px white shield
/// disc and one line in `success/fg`.
class _FinalPriceNote extends StatelessWidget {
  const _FinalPriceNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final AppColorTokens c = context.colors;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: c.successBg,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      child: Row(
        children: <Widget>[
          const _IconDisc(icon: AppIcons.shieldTickOutline, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: c.successFg),
            ),
          ),
        ],
      ),
    );
  }
}

/// Figma `room tag`: a warm pill (radius 999, 10/4 padding, 12 text).
class _RoomTag extends StatelessWidget {
  const _RoomTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final AppColorTokens c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.accentWarmBg,
        borderRadius: const BorderRadius.all(Radius.circular(999)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: c.accentWarmFg),
      ),
    );
  }
}

/// Figma `included list` row: a 28px white disc with the warm tick-circle
/// and the label (12).
class _IncludedRow extends StatelessWidget {
  const _IncludedRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _IconDisc(icon: icon, size: 28, color: context.colors.accentWarmFg),
        const SizedBox(width: AppSpacing.space2),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: context.colors.textPrimary, height: 2),
          ),
        ),
      ],
    );
  }
}

/// Figma room-facility tile: white, radius 16, a 40px icon disc over the
/// label (12), three per row.
class _FacilityTile extends StatelessWidget {
  const _FacilityTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final AppColorTokens c = context.colors;
    return Container(
      constraints: const BoxConstraints(minHeight: 82),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: c.bgSurface,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(color: c.borderDefault, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppPrimitives.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: c.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: c.textPrimary),
          ),
        ],
      ),
    );
  }
}

/// Figma `about card`: the description (12, `text/secondary`), clamped to
/// three lines with a `عرض المزيد` / `عرض أقل` toggle when it is longer.
class _AboutCard extends StatefulWidget {
  const _AboutCard({required this.text});

  final String text;

  @override
  State<_AboutCard> createState() => _AboutCardState();
}

class _AboutCardState extends State<_AboutCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme text = Theme.of(context).textTheme;
    final AppColorTokens c = context.colors;
    final TextStyle? body = text.labelSmall?.copyWith(
      color: c.textSecondary,
      height: 1.5,
    );

    return DetailCard(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints box) {
          final TextPainter probe = TextPainter(
            text: TextSpan(text: widget.text, style: body),
            textDirection: Directionality.of(context),
            maxLines: 3,
          )..layout(maxWidth: box.maxWidth);
          final bool overflows = probe.didExceedMaxLines;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(l10n.roomAboutHeading, style: detailTitleStyle(context)),
              const SizedBox(height: AppSpacing.space2),
              Text(
                widget.text,
                style: body,
                maxLines: _expanded ? null : 3,
                overflow: _expanded ? null : TextOverflow.ellipsis,
              ),
              if (overflows) ...<Widget>[
                const SizedBox(height: AppSpacing.space2),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: InkWell(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Text(
                      _expanded ? l10n.commonShowLess : l10n.commonShowMore,
                      style: text.labelMedium?.copyWith(
                        color: c.accentWarmFg,
                        fontWeight: AppTypography.medium,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Figma policy tile: `stone/100`, radius 16, a 32px white disc, the title
/// (14) over the body (12, `text/secondary`).
class _PolicyTile extends StatelessWidget {
  const _PolicyTile({
    required this.title,
    required this.body,
    this.icon = AppIcons.shieldTickOutline,
  });

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppColorTokens c = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.bgSubtle,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      child: Row(
        children: <Widget>[
          _IconDisc(icon: icon, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: text.bodySmall?.copyWith(color: c.textPrimary),
                ),
                Text(
                  body,
                  style: text.labelSmall?.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The room hero saves this room (room type) to the guest's server-backed
/// favourites, listed under Account → المفضلة.
class _RoomFavoriteButton extends ConsumerWidget {
  const _RoomFavoriteButton({required this.room});

  final FavoriteRoom room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final bool favorite = ref.watch(
      favoriteRoomsProvider.select(
        (List<FavoriteRoom> rooms) =>
            rooms.any((FavoriteRoom r) => r.roomTypeId == room.roomTypeId),
      ),
    );
    return DetailHeroButton(
      key: const ValueKey<String>('room-favorite'),
      icon: favorite ? AppIcons.favoriteActive : AppIcons.favorite,
      iconColor: AppPrimitives.red600,
      selected: favorite,
      tooltip: favorite ? l10n.roomFavoriteRemove : l10n.roomFavoriteAdd,
      onPressed: () => toggleRoomFavorite(context, ref, room),
    );
  }
}
