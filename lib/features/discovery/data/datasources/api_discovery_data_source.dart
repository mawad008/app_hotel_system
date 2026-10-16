import '../../../../core/data/data_source.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/hotel.dart';
import '../../domain/entities/hotel_facility.dart';
import '../../domain/entities/hotel_filters.dart';
import '../../domain/entities/hotel_sort.dart';
import '../../domain/entities/localized_text.dart';
import '../../domain/entities/money.dart';
import '../../domain/entities/room_type_summary.dart';
import '../models/discovery_models.dart';
import 'discovery_data_source.dart';

typedef Json = Map<String, Object?>;

List<RoomTypeSpec> _customRoomSpecs(Object? raw) => <RoomTypeSpec>[
  for (final Object? item in (raw as List<Object?>?) ?? const <Object?>[])
    if (item is Json && item['label'] is String && item['value'] is String)
      (label: item['label']! as String, value: item['value']! as String),
];

/// API-backed discovery source.
///
/// Real, unauthenticated guest contract (`GuestDiscoveryController`):
/// `GET /guest/hotels`, `/guest/hotels/cities`, `/guest/hotels/{hotel}`,
/// `/guest/hotels/{hotel}/availability` — active hotels / active room types
/// only, no caller identity, so no hotel scope.
///
/// The backend resources (`PublicHotelResource`, `PublicRoomTypeResource`,
/// `RoomAvailabilityResource`) carry real bed type (`bed_type`, resolved
/// server-side from `room_types.bed_type_i18n`), `area_sqm`,
/// `breakfast_included` and `refundable` columns — mapped 1:1 below, `null`/
/// `false` only when the room type genuinely has none on file, never
/// fabricated client-side. Room-type `gallery` photos are likewise a real
/// field on both resources (once `RoomType::galleryMedia` is eager-loaded
/// server-side) and are mapped 1:1, the same way the hotel's own `gallery`
/// is.
///
/// `GET /guest/hotels` accepts `city`, `q`, `per_page`, `sort`
/// (`recommended` | `highest_rated` | `cheapest`), `min_price`, `max_price`
/// and `facilities` (comma-separated keys, AND semantics) — all applied
/// server-side over the full catalogue via real DB aggregates/ordering.
/// [HotelSort] and [HotelFilters] map onto these 1:1; nothing is re-sorted or
/// re-filtered client-side over a single fetched page. `city` is a single
/// value server-side — [HotelFilters.cityIds] with more than one entry
/// narrows the (already server-filtered-by-first-city) page client-side as a
/// display convenience, not a claim of full-dataset multi-city search (the
/// backend has no such parameter; a genuine multi-city filter is a backend
/// gap, not invented here).
///
/// The public catalogue reads (cities, hotel lists, a hotel's details) keep
/// their last good response for offline browsing (`offlineFallback`); live
/// availability never does — a stale price or "available" must not show.
class ApiDiscoveryDataSource implements DiscoveryDataSource, RemoteDataSource {
  ApiDiscoveryDataSource(this._client);

  /// Hotels per search page: small enough for a fast first screen, the rest
  /// loads as the guest scrolls.
  static const int searchPageSize = 20;

  final ApiClient _client;

  @override
  Future<List<CityModel>> fetchCities() async {
    final Map<String, dynamic> json = await _client.getJson(
      '/guest/hotels/cities',
      offlineFallback: true,
    );
    final List<Object?> data =
        (json['data'] as List<Object?>?) ?? const <Object?>[];
    return data
        .whereType<Json>()
        .map((Json row) {
          // `city` is the filter key (sent back as `?city=`); `name` is its
          // display name in the request locale.
          final String city = (row['city'] as String?) ?? '';
          final String name = (row['name'] as String?) ?? city;
          return CityModel(
            id: city,
            name: LocalizedText(ar: name, en: name),
            hotelCount: (row['hotel_count'] as num?)?.toInt() ?? 0,
          );
        })
        .toList(growable: false);
  }

  @override
  Future<List<HotelSummaryModel>> fetchFeaturedHotels() async {
    // "Hotels of the Group" (`HOME_Default`) — this deployment has exactly
    // one hotel group, so the full active-hotel list *is* the group's
    // hotels; no separate group-scoped endpoint exists or is needed. Default
    // (`recommended`) ordering matches the Home screen's unselected "الكل"
    // chip state.
    final Map<String, dynamic> json = await _client.getJson(
      '/guest/hotels',
      query: const <String, dynamic>{'sort': 'recommended', 'per_page': 20},
      offlineFallback: true,
    );
    final List<Object?> rows =
        (json['data'] as List<Object?>?) ?? const <Object?>[];
    return rows
        .whereType<Json>()
        .map(_hotelSummaryFromPublicHotel)
        .toList(growable: false);
  }

  @override
  Future<HotelSearchResultModel> searchHotels({
    required String query,
    required HotelFilters filters,
    required HotelSort sort,
    int page = 1,
  }) async {
    final Map<String, dynamic> json = await _client.getJson(
      '/guest/hotels',
      query: <String, dynamic>{
        if (query.trim().isNotEmpty) 'q': query.trim(),
        if (filters.cityIds.isNotEmpty) 'city': filters.cityIds.first,
        if (filters.priceRange != null) 'min_price': filters.priceRange!.min,
        if (filters.priceRange != null) 'max_price': filters.priceRange!.max,
        if (filters.facilities.isNotEmpty)
          'facilities': filters.facilities.map(_facilityKey).join(','),
        'sort': _sortParam(sort),
        'page': page,
        'per_page': searchPageSize,
      },
      offlineFallback: true,
    );
    final List<Object?> rows =
        (json['data'] as List<Object?>?) ?? const <Object?>[];
    List<HotelSummaryModel> hotels = rows
        .whereType<Json>()
        .map(_hotelSummaryFromPublicHotel)
        .toList(growable: false);

    // `city` is a single server-side value; a second/third selected city
    // narrows the already-fetched (first-city) page as a display convenience
    // only — the backend has no multi-city parameter (see class doc).
    if (filters.cityIds.length > 1) {
      hotels = hotels
          .where((HotelSummaryModel h) => filters.cityIds.contains(h.cityId))
          .toList(growable: false);
    }

    final Json meta = (json['meta'] as Json?) ?? const <String, Object?>{};
    final int currentPage = (meta['current_page'] as num?)?.toInt() ?? page;
    final int lastPage = (meta['last_page'] as num?)?.toInt() ?? currentPage;
    return HotelSearchResultModel(
      hotels: hotels,
      totalCount: (meta['total'] as num?)?.toInt() ?? hotels.length,
      page: currentPage,
      hasMore: currentPage < lastPage,
    );
  }

  @override
  Future<HotelModel> fetchHotel(String hotelId) async {
    final Map<String, dynamic> json = await _client.getJson(
      '/guest/hotels/$hotelId',
      offlineFallback: true,
    );
    final Json data = (json['data'] as Json?) ?? const <String, Object?>{};
    return _hotelFromPublicHotel(data);
  }

  @override
  Future<AvailabilityResultModel> fetchAvailability({
    required String hotelId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int adults,
    required int children,
  }) async {
    final Map<String, dynamic> json = await _client.getJson(
      '/guest/hotels/$hotelId/availability',
      query: <String, dynamic>{
        'check_in': _isoDate(checkIn),
        'check_out': _isoDate(checkOut),
        'adults': adults,
        'children': children,
      },
    );
    final Json data = (json['data'] as Json?) ?? const <String, Object?>{};
    final List<Object?> rooms =
        (data['rooms'] as List<Object?>?) ?? const <Object?>[];
    return AvailabilityResultModel(
      hotelId: '${data['hotel_id']}',
      checkIn: DateTime.parse(data['check_in'] as String),
      checkOut: DateTime.parse(data['check_out'] as String),
      adults: (data['adults'] as num?)?.toInt() ?? adults,
      children: (data['children'] as num?)?.toInt() ?? children,
      rooms: rooms
          .whereType<Json>()
          .map(
            (Json r) => AvailableRoomModel(
              roomType: _roomTypeSummaryFromAvailability(r),
              isAvailable: (r['is_available'] as bool?) ?? false,
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<int> fetchGroupHotelCount() async {
    final Map<String, dynamic> json = await _client.getJson(
      '/guest/hotels',
      query: const <String, dynamic>{'per_page': 1},
      // Home needs this too: offline it must not fail while the hotel list
      // itself is served from the saved copy.
      offlineFallback: true,
    );
    final Json meta = (json['meta'] as Json?) ?? const <String, Object?>{};
    return (meta['total'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<List<AvailableRoomModel>> fetchHotelRooms(String hotelId) async {
    // No date-scoped availability requested — these are the hotel's offered
    // room types (real data), each marked available since no stay window was
    // checked; a genuine live availability read is `fetchAvailability`.
    final Map<String, dynamic> json = await _client.getJson(
      '/guest/hotels/$hotelId',
      offlineFallback: true,
    );
    final Json data = (json['data'] as Json?) ?? const <String, Object?>{};
    final List<Object?> roomTypes =
        (data['room_types'] as List<Object?>?) ?? const <Object?>[];
    return roomTypes
        .whereType<Json>()
        .map(
          (Json rt) => AvailableRoomModel(
            roomType: _roomTypeSummaryFromPublicRoomType(rt),
            isAvailable: true,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<UpcomingStayModel?> fetchUpcomingStay() async {
    // Not a discovery concern — the guest's own upcoming stay comes from the
    // authenticated reservation list, which this unauthenticated data source
    // has no access to. Composing it needs a cross-feature (reservation)
    // read at the repository layer, not a discovery endpoint.
    throw const NotImplementedInPhaseException(
      'Upcoming-stay needs the authenticated guest reservation list, not a '
      'discovery endpoint',
    );
  }

  // ── mapping helpers ──────────────────────────────────────────────────

  HotelSummaryModel _hotelSummaryFromPublicHotel(Json h) => HotelSummaryModel(
    id: '${h['id']}',
    name: _text(h['name']),
    cityId: (h['city'] as String?) ?? '',
    // `city_name` is localized to the request locale; `city` stays the
    // English filter key (older backends only send `city`).
    cityName: _text(h['city_name'] ?? h['city']),
    tagline: _text(h['tagline']),
    // `rating` is the real average of published guest reviews
    // (`PublicHotelResource`); `star_rating` is the hotel's own
    // classification (1-5 stars set by the operator) and is a different
    // concept — never substituted here.
    rating: _parseRating(h['rating']),
    reviewCount: (h['reviews_count'] as num?)?.toInt(),
    nightlyRateFrom: _priceFrom(h),
    isAvailable: true,
    coverUrl: _client.resolveMediaUrl(h['cover_url'] as String?),
    starRating: (h['star_rating'] as num?)?.toInt(),
  );

  HotelModel _hotelFromPublicHotel(Json h) {
    final List<Object?> roomTypes =
        (h['room_types'] as List<Object?>?) ?? const <Object?>[];
    final List<Object?> amenities =
        (h['amenities'] as List<Object?>?) ?? const <Object?>[];
    final List<Object?> gallery =
        (h['gallery'] as List<Object?>?) ?? const <Object?>[];
    return HotelModel(
      summary: _hotelSummaryFromPublicHotel(h),
      description: _text(h['description']),
      // Each hotel's real, open facility catalog membership — `{key, label,
      // icon}` per `PublicHotelResource`. Rendered by `label`, never by
      // looking `key` up in a hardcoded map (that catalog is admin-managed
      // and can grow without a mobile release).
      facilities: <HotelFacility>[
        for (final Object? raw in amenities)
          if (raw is Json && raw['label'] is String)
            HotelFacility(
              key: (raw['key'] as String?) ?? '',
              label: _text(raw['label']),
              description:
                  raw['description'] is String &&
                      (raw['description']! as String).trim().isNotEmpty
                  ? _text((raw['description']! as String).trim())
                  : null,
              icon: raw['icon'] as String?,
            ),
      ],
      roomTypeCount:
          (h['room_types_count'] as num?)?.toInt() ?? roomTypes.length,
      photoCount: gallery.length,
      entryRoom: roomTypes.isEmpty
          ? null
          : _roomTypeSummaryFromPublicRoomType(roomTypes.first as Json),
      galleryUrls: <String>[
        for (final Object? raw in gallery)
          if (raw is Json && raw['url'] is String)
            _client.resolveMediaUrl(raw['url']! as String)!,
      ],
      // `country_name` is localized to the request locale (the legacy
      // `country` string is English). `null` when the resource has none on
      // file; never guessed from `city`/`city_id`.
      country: (h['country_name'] ?? h['country']) is String
          ? _text(h['country_name'] ?? h['country'])
          : null,
      // Detail endpoint only: the live rating summary with the hotel's
      // dynamic review categories.
      reviewSummary: HotelModel.parseReviewSummary(h['review_summary']),
      // Detail endpoint only: operator-managed Hotel Detail content.
      details: HotelModel.parseGuestDetails(h),
    );
  }

  /// The "from" nightly price shown on hotel cards/the detail header.
  ///
  /// `GET /guest/hotels` (list/search rows) computes `price_from` server-side
  /// across the hotel's full room-type catalogue — used as-is. `GET
  /// /guest/hotels/{hotel}` (single-hotel, used by [fetchHotel]) carries no
  /// `price_from` field at all, only the `room_types` this specific resource
  /// embeds; the lowest `base_price` among those is the real "from" price for
  /// that case, never a hardcoded or first-room figure.
  static Money _priceFrom(Json h) {
    if (h['price_from'] != null) return _money(h['price_from'], h['currency']);
    final List<Object?> roomTypes =
        (h['room_types'] as List<Object?>?) ?? const <Object?>[];
    num? lowest;
    for (final Object? raw in roomTypes) {
      if (raw is! Json) continue;
      final num amount = _money(raw['base_price'], raw['currency']).amount;
      if (lowest == null || amount < lowest) lowest = amount;
    }
    return _money(lowest ?? 0, h['currency']);
  }

  /// `rating` arrives as a decimal-formatted string (e.g. `"4.50"`, matching
  /// `price_from`'s convention) or is absent/null when the hotel has zero
  /// published reviews.
  static double? _parseRating(Object? raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw);
    return null;
  }

  static String _sortParam(HotelSort sort) => switch (sort) {
    HotelSort.recommended => 'recommended',
    HotelSort.ratingDesc => 'highest_rated',
    HotelSort.priceAsc => 'cheapest',
  };

  static const Map<HotelAmenity, String> _facilityKeyByAmenity =
      <HotelAmenity, String>{
        HotelAmenity.freeWifi: 'free_wifi',
        HotelAmenity.breakfast: 'breakfast',
        HotelAmenity.parking: 'parking',
        HotelAmenity.pool: 'pool',
        HotelAmenity.gym: 'gym',
        HotelAmenity.familyRooms: 'family_rooms',
        HotelAmenity.airportShuttle: 'airport_shuttle',
        HotelAmenity.roomService: 'room_service',
      };

  static String _facilityKey(HotelAmenity amenity) =>
      _facilityKeyByAmenity[amenity] ?? '';

  RoomTypeSummaryModel _roomTypeSummaryFromPublicRoomType(Json rt) {
    final List<Object?> amenities =
        (rt['amenities'] as List<Object?>?) ?? const <Object?>[];
    return RoomTypeSummaryModel(
      id: '${rt['id']}',
      name: _text(rt['name']),
      description: _text(rt['description']),
      bedType: _text(rt['bed_type']),
      maxOccupancy: (rt['capacity'] as num?)?.toInt() ?? 1,
      amenities: <RoomAmenity>[
        for (final Object? raw in amenities)
          if (_roomAmenityByKey[raw as String?] != null)
            _roomAmenityByKey[raw]!,
      ],
      nightlyRate: _money(rt['base_price'], rt['currency']),
      breakfastIncluded: (rt['breakfast_included'] as bool?) ?? false,
      refundable: (rt['refundable'] as bool?) ?? false,
      areaSqm: (rt['area_sqm'] as num?)?.toInt(),
      view: rt['view'] is String ? _text(rt['view']) : null,
      customSpecs: _customRoomSpecs(rt['custom_specs']),
      galleryUrls: _gallery(rt['gallery']),
      tag: RoomTypeSummaryModel.parseRoomTag(rt['tag']),
      inclusions: RoomTypeSummaryModel.parseRoomInclusions(rt['inclusions']),
      facilities: RoomTypeSummaryModel.parseRoomFacilities(rt['facilities']),
    );
  }

  RoomTypeSummaryModel _roomTypeSummaryFromAvailability(Json r) {
    final List<Object?> amenities =
        (r['amenities'] as List<Object?>?) ?? const <Object?>[];
    return RoomTypeSummaryModel(
      id: '${r['room_type_id']}',
      name: _text(r['name']),
      description: _text(r['description']),
      bedType: _text(r['bed_type']),
      maxOccupancy: (r['capacity'] as num?)?.toInt() ?? 1,
      amenities: <RoomAmenity>[
        for (final Object? raw in amenities)
          if (_roomAmenityByKey[raw as String?] != null)
            _roomAmenityByKey[raw]!,
      ],
      nightlyRate: _money(r['base_price'], r['currency']),
      breakfastIncluded: (r['breakfast_included'] as bool?) ?? false,
      refundable: (r['refundable'] as bool?) ?? false,
      areaSqm: (r['area_sqm'] as num?)?.toInt(),
      view: r['view'] is String ? _text(r['view']) : null,
      customSpecs: _customRoomSpecs(r['custom_specs']),
      galleryUrls: _gallery(r['gallery']),
      tag: RoomTypeSummaryModel.parseRoomTag(r['tag']),
      inclusions: RoomTypeSummaryModel.parseRoomInclusions(r['inclusions']),
      facilities: RoomTypeSummaryModel.parseRoomFacilities(r['facilities']),
    );
  }

  /// Resolves a `PublicRoomTypeResource.gallery` / `RoomAvailabilityResource.gallery`
  /// array (each row shaped like `HotelMediaResource`/`RoomMediaResource`,
  /// i.e. `{url: ...}`) into absolute display URLs, in server order — same
  /// convention as the hotel `gallery` parsing in [_hotelFromPublicHotel].
  List<String> _gallery(Object? raw) => <String>[
    for (final Object? row in (raw as List<Object?>?) ?? const <Object?>[])
      if (row is Json && row['url'] is String)
        _client.resolveMediaUrl(row['url']! as String)!,
  ];

  static LocalizedText _text(Object? raw) {
    if (raw is String) return LocalizedText(ar: raw, en: raw);
    return const LocalizedText(ar: '', en: '');
  }

  /// A `decimal:2` price in the response's `currency` (halalas kept).
  static Money _money(Object? raw, [Object? currency]) => Money(
        amount: Money.parseAmount(raw),
        currency: currency is String && currency.isNotEmpty
            ? currency
            : Money.fallbackCurrency,
      );

  static String _isoDate(DateTime date) {
    final DateTime d = DateTime(date.year, date.month, date.day);
    final String y = d.year.toString().padLeft(4, '0');
    final String m = d.month.toString().padLeft(2, '0');
    final String dd = d.day.toString().padLeft(2, '0');
    return '$y-$m-$dd';
  }

  static const Map<String?, RoomAmenity> _roomAmenityByKey =
      <String?, RoomAmenity>{
        'free_wifi': RoomAmenity.freeWifi,
        'air_conditioning': RoomAmenity.airConditioning,
        'city_view': RoomAmenity.cityView,
        'balcony': RoomAmenity.balcony,
        'kitchenette': RoomAmenity.kitchenette,
      };
}
