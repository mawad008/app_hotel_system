// Data-transfer models for the discovery feature.
//
// Each model parses a JSON-shaped map and maps to a domain entity. The dummy
// data source builds these from `discovery_fixtures.dart`; a future
// `ApiDiscoveryDataSource` would build them from `ApiClient` responses. The
// exact Laravel field names are not an approved contract yet — these keys are
// the dummy layer's own and will be reconciled when the contract lands.

import '../../domain/entities/availability_result.dart';
import '../../domain/entities/available_room.dart';
import '../../domain/entities/city.dart';
import '../../domain/entities/guest_party.dart';
import '../../domain/entities/hotel.dart';
import '../../domain/entities/hotel_facility.dart';
import '../../domain/entities/hotel_guest_details.dart';
import '../../domain/entities/hotel_review_summary.dart';
import '../../domain/entities/hotel_search_result.dart';
import '../../domain/entities/hotel_summary.dart';
import '../../domain/entities/localized_text.dart';
import '../../domain/entities/money.dart';
import '../../domain/entities/room_type_summary.dart';
import '../../domain/entities/stay_range.dart';
import '../../domain/entities/upcoming_stay.dart';

typedef Json = Map<String, Object?>;

LocalizedText _text(Object? value) {
  final Json map = (value as Json?) ?? const <String, Object?>{};
  return LocalizedText(
    ar: (map['ar'] as String?) ?? '',
    en: (map['en'] as String?) ?? '',
  );
}

Json _textJson(LocalizedText text) => <String, Object?>{
  'ar': text.ar,
  'en': text.en,
};

Money _money(Object? value) {
  final Json map = (value as Json?) ?? const <String, Object?>{};
  return Money(
    amount: (map['amount'] as num?)?.toInt() ?? 0,
    currency: (map['currency'] as String?) ?? Money.fallbackCurrency,
  );
}

Json _moneyJson(Money money) => <String, Object?>{
  'amount': money.amount,
  'currency': money.currency,
};

class CityModel {
  const CityModel({
    required this.id,
    required this.name,
    required this.hotelCount,
  });

  factory CityModel.fromJson(Json json) => CityModel(
    id: json['id'] as String,
    name: _text(json['name']),
    hotelCount: (json['hotel_count'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final LocalizedText name;
  final int hotelCount;

  City toEntity() => City(id: id, name: name, hotelCount: hotelCount);
}

class HotelSummaryModel {
  const HotelSummaryModel({
    required this.id,
    required this.name,
    required this.cityId,
    required this.cityName,
    required this.tagline,
    required this.rating,
    required this.reviewCount,
    required this.nightlyRateFrom,
    required this.isAvailable,
    this.coverUrl,
    this.starRating,
  });

  factory HotelSummaryModel.fromJson(Json json) => HotelSummaryModel(
    id: json['id'] as String,
    name: _text(json['name']),
    cityId: json['city_id'] as String,
    cityName: _text(json['city_name']),
    tagline: _text(json['tagline']),
    rating: (json['rating'] as num?)?.toDouble(),
    reviewCount: (json['review_count'] as num?)?.toInt(),
    nightlyRateFrom: _money(json['nightly_rate_from']),
    isAvailable: (json['is_available'] as bool?) ?? true,
    coverUrl: json['cover_url'] as String?,
    starRating: (json['star_rating'] as num?)?.toInt(),
  );

  final String id;
  final LocalizedText name;
  final String cityId;
  final LocalizedText cityName;
  final LocalizedText tagline;
  final double? rating;
  final int? reviewCount;
  final Money nightlyRateFrom;
  final bool isAvailable;
  final String? coverUrl;
  final int? starRating;

  HotelSummary toEntity() => HotelSummary(
    id: id,
    name: name,
    cityId: cityId,
    cityName: cityName,
    tagline: tagline,
    rating: rating,
    reviewCount: reviewCount,
    nightlyRateFrom: nightlyRateFrom,
    isAvailable: isAvailable,
    coverUrl: coverUrl,
    starRating: starRating,
  );
}

class HotelModel {
  const HotelModel({
    required this.summary,
    required this.description,
    required this.facilities,
    required this.roomTypeCount,
    required this.photoCount,
    this.entryRoom,
    this.galleryUrls = const <String>[],
    this.country,
    this.reviewSummary,
    this.details = const HotelGuestDetails(),
  });

  factory HotelModel.fromJson(Json json) => HotelModel(
    summary: HotelSummaryModel.fromJson(json),
    description: _text(json['description']),
    // Dummy fixtures still list `amenities` as bare `HotelAmenity` wire
    // keys (no facility catalog to fetch labels from) — wrapped here
    // into the same `{key, label}` shape the real API returns, using
    // the exact copy the l10n `amenity*` strings carry, so dummy mode's
    // facility display is unchanged from before this field existed.
    facilities: <HotelFacility>[
      for (final Object? raw
          in (json['amenities'] as List<Object?>? ?? const <Object?>[]))
        if (_amenityByName[raw] != null)
          HotelFacility(
            key: raw as String,
            label: _dummyFacilityLabel[_amenityByName[raw]]!,
          ),
    ],
    roomTypeCount: (json['room_type_count'] as num?)?.toInt() ?? 0,
    photoCount: (json['photo_count'] as num?)?.toInt() ?? 0,
    entryRoom: _entryRoom(json['entry_room']),
    country: json['country'] == null ? null : _text(json['country']),
    details: parseGuestDetails(json),
  );

  final HotelSummaryModel summary;
  final LocalizedText description;
  final List<HotelFacility> facilities;
  final int roomTypeCount;
  final int photoCount;
  final RoomTypeSummaryModel? entryRoom;
  final List<String> galleryUrls;
  final LocalizedText? country;

  /// The live review summary — API only ([ApiDiscoveryDataSource] parses
  /// `review_summary` via [parseReviewSummary]). Dummy fixtures carry none:
  /// no rating is ever fabricated.
  final HotelReviewSummary? reviewSummary;

  /// Operator-managed detail content ([parseGuestDetails]; offline fixtures
  /// carry the same keys for parity).
  final HotelGuestDetails details;

  Hotel toEntity() => Hotel(
    summary: summary.toEntity(),
    description: description,
    facilities: facilities,
    roomTypeCount: roomTypeCount,
    photoCount: photoCount,
    entryRoom: entryRoom?.toEntity(),
    galleryUrls: galleryUrls,
    country: country,
    reviewSummary: reviewSummary,
    details: details,
  );

  static RoomTypeSummaryModel? _entryRoom(Object? value) {
    if (value == null) return null;
    return RoomTypeSummaryModel.fromJson(value as Json);
  }

  /// Parses `review_summary` (`{average, count, categories: [{id, label,
  /// icon, average, ratings_count}]}`) — every category the backend sent, in
  /// its order; nothing is assumed about which or how many.
  static HotelReviewSummary? parseReviewSummary(Object? value) {
    if (value is! Json) return null;
    final List<Object?> raw =
        (value['categories'] as List<Object?>?) ?? const <Object?>[];
    return HotelReviewSummary(
      average: _decimal(value['average']),
      count: (value['count'] as num?)?.toInt() ?? 0,
      categories: <ReviewCategoryScore>[
        for (final Object? c in raw)
          if (c is Json && c['id'] != null && c['label'] is String)
            ReviewCategoryScore(
              id: '${c['id']}',
              label: c['label']! as String,
              average: _decimal(c['average']),
              ratingsCount: (c['ratings_count'] as num?)?.toInt() ?? 0,
              icon: c['icon'] as String?,
            ),
      ],
    );
  }

  /// Parses the hotel detail content from the `GET /guest/hotels/{id}`
  /// payload: `check_in_time`, `check_out_time`, `suitable_for`,
  /// `rooms_count`, `highlights[{icon, title, subtitle}]` and `location{note,
  /// latitude, longitude, nearby_places[{icon, category, name, travel_minutes,
  /// distance, distance_unit, latitude, longitude}]}`. Blank strings count as
  /// absent; list rows without a label are skipped; a distance without a
  /// known unit (or a half coordinate pair) is dropped.
  /// `service_fee: {type: fixed|percentage, value}` or null (no fee).
  static HotelServiceFee? _serviceFee(Object? raw) {
    if (raw is! Json) return null;
    final num? value = switch (raw['value']) {
      final num n => n,
      final String s => num.tryParse(s),
      _ => null,
    };
    if (value == null || value <= 0) return null;
    return HotelServiceFee(
      isPercentage: raw['type'] == 'percentage',
      value: value,
    );
  }

  static HotelGuestDetails parseGuestDetails(Json h) {
    final Object? loc = h['location'];
    return HotelGuestDetails(
      checkInTime: _nonBlank(h['check_in_time']),
      checkOutTime: _nonBlank(h['check_out_time']),
      pricesIncludeTaxes: (h['prices_include_taxes'] as bool?) ?? false,
      serviceFee: _serviceFee(h['service_fee']),
      suitableFor: _nonBlank(h['suitable_for']),
      roomsCount: (h['rooms_count'] as num?)?.toInt(),
      highlights: <HotelHighlight>[
        for (final Object? raw
            in (h['highlights'] as List<Object?>?) ?? const <Object?>[])
          if (raw is Json && _nonBlank(raw['title']) != null)
            HotelHighlight(
              title: _nonBlank(raw['title'])!,
              subtitle: _nonBlank(raw['subtitle']),
              icon: _nonBlank(raw['icon']),
            ),
      ],
      location: loc is! Json
          ? null
          : HotelLocation(
              note: _nonBlank(loc['note']),
              latitude: _decimal(loc['latitude']),
              longitude: _decimal(loc['longitude']),
              nearbyPlaces: <NearbyPlace>[
                for (final Object? raw
                    in (loc['nearby_places'] as List<Object?>?) ??
                        const <Object?>[])
                  if (raw is Json && _nonBlank(raw['name']) != null)
                    _nearbyPlace(raw),
              ],
            ),
    );
  }

  static NearbyPlace _nearbyPlace(Json raw) {
    final DistanceUnit? unit = DistanceUnit.fromWire(raw['distance_unit']);
    final double? distance = _decimal(raw['distance']);
    final double? lat = _decimal(raw['latitude']);
    final double? lng = _decimal(raw['longitude']);
    final bool pinned = lat != null && lng != null;
    return NearbyPlace(
      name: _nonBlank(raw['name'])!,
      travelMinutes: (raw['travel_minutes'] as num?)?.toInt(),
      icon: _nonBlank(raw['icon']),
      category: _nonBlank(raw['category']),
      distance: unit == null ? null : distance,
      distanceUnit: distance == null ? null : unit,
      latitude: pinned ? lat : null,
      longitude: pinned ? lng : null,
    );
  }

  static String? _nonBlank(Object? v) =>
      v is String && v.trim().isNotEmpty ? v.trim() : null;

  /// Numbers arrive as JSON numbers (or, for some aggregates, strings).
  static double? _decimal(Object? v) => switch (v) {
    num n => n.toDouble(),
    String s => double.tryParse(s),
    _ => null,
  };

  static const Map<String?, HotelAmenity> _amenityByName =
      <String?, HotelAmenity>{
        'free_wifi': HotelAmenity.freeWifi,
        'breakfast': HotelAmenity.breakfast,
        'parking': HotelAmenity.parking,
        'pool': HotelAmenity.pool,
        'gym': HotelAmenity.gym,
        'family_rooms': HotelAmenity.familyRooms,
        'airport_shuttle': HotelAmenity.airportShuttle,
        'room_service': HotelAmenity.roomService,
      };

  /// Dummy-mode-only display copy — mirrors the real `amenity*` l10n
  /// strings (`app_en.arb`/`app_ar.arb`) verbatim so switching a screen from
  /// dummy to real data never visibly changes a facility's label.
  static const Map<HotelAmenity, LocalizedText> _dummyFacilityLabel =
      <HotelAmenity, LocalizedText>{
        HotelAmenity.freeWifi: LocalizedText(
          ar: 'واي فاي مجاني',
          en: 'Free Wi-Fi',
        ),
        HotelAmenity.breakfast: LocalizedText(ar: 'إفطار', en: 'Breakfast'),
        HotelAmenity.parking: LocalizedText(ar: 'موقف سيارات', en: 'Parking'),
        HotelAmenity.pool: LocalizedText(ar: 'مسبح', en: 'Pool'),
        HotelAmenity.gym: LocalizedText(ar: 'صالة رياضية', en: 'Gym'),
        HotelAmenity.familyRooms: LocalizedText(
          ar: 'غرف عائلية',
          en: 'Family rooms',
        ),
        HotelAmenity.airportShuttle: LocalizedText(
          ar: 'نقل من/إلى المطار',
          en: 'Airport shuttle',
        ),
        HotelAmenity.roomService: LocalizedText(
          ar: 'خدمة الغرف',
          en: 'Room service',
        ),
      };
}

class HotelSearchResultModel {
  const HotelSearchResultModel({
    required this.hotels,
    required this.totalCount,
  });

  factory HotelSearchResultModel.fromJson(Json json) => HotelSearchResultModel(
    hotels: <HotelSummaryModel>[
      for (final Object? raw
          in (json['data'] as List<Object?>? ?? const <Object?>[]))
        HotelSummaryModel.fromJson(raw as Json),
    ],
    totalCount: (json['total'] as num?)?.toInt() ?? 0,
  );

  final List<HotelSummaryModel> hotels;
  final int totalCount;

  HotelSearchResult toEntity() => HotelSearchResult(
    hotels: hotels
        .map((HotelSummaryModel m) => m.toEntity())
        .toList(growable: false),
    totalCount: totalCount,
  );
}

class RoomTypeSummaryModel {
  const RoomTypeSummaryModel({
    required this.id,
    required this.name,
    required this.description,
    required this.bedType,
    required this.maxOccupancy,
    required this.amenities,
    required this.nightlyRate,
    required this.breakfastIncluded,
    required this.refundable,
    this.areaSqm,
    this.view,
    this.customSpecs = const <RoomTypeSpec>[],
    this.galleryUrls = const <String>[],
    this.tag,
    this.inclusions = const <LocalizedText>[],
    this.facilities = const <HotelFacility>[],
  });

  factory RoomTypeSummaryModel.fromJson(Json json) => RoomTypeSummaryModel(
    id: json['id'] as String,
    name: _text(json['name']),
    description: _text(json['description']),
    bedType: _text(json['bed_type']),
    maxOccupancy: (json['max_occupancy'] as num?)?.toInt() ?? 1,
    amenities: <RoomAmenity>[
      for (final Object? raw
          in (json['amenities'] as List<Object?>? ?? const <Object?>[]))
        if (_amenityByName[raw as String?] != null) _amenityByName[raw]!,
    ],
    nightlyRate: _money(json['nightly_rate']),
    breakfastIncluded: (json['breakfast_included'] as bool?) ?? false,
    refundable: (json['refundable'] as bool?) ?? false,
    areaSqm: (json['area_sqm'] as num?)?.toInt(),
    view: json['view'] == null ? null : _text(json['view']),
    customSpecs: <RoomTypeSpec>[
      for (final Object? raw
          in (json['custom_specs'] as List<Object?>?) ?? const <Object?>[])
        if (raw is Map<String, Object?> &&
            raw['label'] is String &&
            raw['value'] is String)
          (label: raw['label']! as String, value: raw['value']! as String),
    ],
    tag: parseRoomTag(json['tag']),
    inclusions: parseRoomInclusions(json['inclusions']),
    facilities: parseRoomFacilities(json['facilities']),
  );

  /// A locale-resolved API string (same text in both slots) or an offline
  /// `{ar, en}` fixture map; blank → `null`.
  static LocalizedText? _localized(Object? raw) {
    if (raw is String) {
      final String v = raw.trim();
      return v.isEmpty ? null : LocalizedText(ar: v, en: v);
    }
    if (raw is Map<String, Object?>) {
      final LocalizedText t = _text(raw);
      return t.ar.trim().isEmpty && t.en.trim().isEmpty ? null : t;
    }
    return null;
  }

  /// `tag`: the optional room badge.
  static LocalizedText? parseRoomTag(Object? raw) => _localized(raw);

  /// `inclusions`: non-blank items, in order.
  static List<LocalizedText> parseRoomInclusions(
    Object? raw,
  ) => <LocalizedText>[
    for (final Object? item in raw is List<Object?> ? raw : const <Object?>[])
      if (_localized(item) != null) _localized(item)!,
  ];

  /// `facilities`: `{key, label, icon}` catalog entries, rendered by label.
  static List<HotelFacility> parseRoomFacilities(
    Object? raw,
  ) => <HotelFacility>[
    for (final Object? item in raw is List<Object?> ? raw : const <Object?>[])
      if (item is Map<String, Object?> && _localized(item['label']) != null)
        HotelFacility(
          key: (item['key'] as String?) ?? '',
          label: _localized(item['label'])!,
          icon: item['icon'] as String?,
        ),
  ];

  final String id;
  final LocalizedText name;
  final LocalizedText description;
  final LocalizedText bedType;
  final int maxOccupancy;
  final List<RoomAmenity> amenities;
  final Money nightlyRate;
  final bool breakfastIncluded;
  final bool refundable;
  final int? areaSqm;
  final LocalizedText? view;
  final List<RoomTypeSpec> customSpecs;

  /// Real gallery photo URLs. Never populated by [fromJson] — the dummy
  /// fixtures carry no media field (see the doc comment on
  /// `RoomTypeSummary.galleryUrls`); only [ApiDiscoveryDataSource] resolves
  /// them (it needs `ApiClient.resolveMediaUrl`, unavailable to this
  /// plain-JSON model), passing them in through this constructor.
  final List<String> galleryUrls;
  final LocalizedText? tag;
  final List<LocalizedText> inclusions;
  final List<HotelFacility> facilities;

  RoomTypeSummary toEntity() => RoomTypeSummary(
    id: id,
    name: name,
    description: description,
    bedType: bedType,
    maxOccupancy: maxOccupancy,
    amenities: amenities,
    nightlyRate: nightlyRate,
    breakfastIncluded: breakfastIncluded,
    refundable: refundable,
    areaSqm: areaSqm,
    view: view,
    customSpecs: customSpecs,
    galleryUrls: galleryUrls,
    tag: tag,
    inclusions: inclusions,
    facilities: facilities,
  );

  static const Map<String?, RoomAmenity> _amenityByName =
      <String?, RoomAmenity>{
        'free_wifi': RoomAmenity.freeWifi,
        'air_conditioning': RoomAmenity.airConditioning,
        'city_view': RoomAmenity.cityView,
        'balcony': RoomAmenity.balcony,
        'kitchenette': RoomAmenity.kitchenette,
      };
}

class AvailableRoomModel {
  const AvailableRoomModel({required this.roomType, required this.isAvailable});

  factory AvailableRoomModel.fromJson(Json json) => AvailableRoomModel(
    roomType: RoomTypeSummaryModel.fromJson(json['room_type'] as Json),
    isAvailable: (json['is_available'] as bool?) ?? true,
  );

  final RoomTypeSummaryModel roomType;
  final bool isAvailable;

  AvailableRoom toEntity() =>
      AvailableRoom(roomType: roomType.toEntity(), isAvailable: isAvailable);
}

class AvailabilityResultModel {
  const AvailabilityResultModel({
    required this.hotelId,
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    required this.children,
    required this.rooms,
  });

  factory AvailabilityResultModel.fromJson(Json json) =>
      AvailabilityResultModel(
        hotelId: json['hotel_id'] as String,
        checkIn: DateTime.parse(json['check_in'] as String),
        checkOut: DateTime.parse(json['check_out'] as String),
        adults: (json['adults'] as num).toInt(),
        children: (json['children'] as num).toInt(),
        rooms: <AvailableRoomModel>[
          for (final Object? raw
              in (json['rooms'] as List<Object?>? ?? const <Object?>[]))
            AvailableRoomModel.fromJson(raw as Json),
        ],
      );

  final String hotelId;
  final DateTime checkIn;
  final DateTime checkOut;
  final int adults;
  final int children;
  final List<AvailableRoomModel> rooms;

  /// Room types that cannot seat the party are dropped, so the list never
  /// offers a room that does not fit the chosen adults + children. Laravel
  /// already omits them; this guards older servers that still return them
  /// greyed out.
  AvailabilityResult toEntity() {
    final GuestParty party = GuestParty(adults: adults, children: children);
    return AvailabilityResult(
      hotelId: hotelId,
      stay: StayRange(checkIn: checkIn, checkOut: checkOut),
      party: party,
      rooms: rooms
          .where(
            (AvailableRoomModel m) => party.fitsIn(m.roomType.maxOccupancy),
          )
          .map((AvailableRoomModel m) => m.toEntity())
          .toList(growable: false),
    );
  }
}

class UpcomingStayModel {
  const UpcomingStayModel({
    required this.reservationId,
    required this.roomName,
    required this.hotelName,
    required this.cityName,
    required this.nightlyRate,
    required this.isAvailable,
    this.imageUrl,
    this.imageSeed,
  });

  factory UpcomingStayModel.fromJson(Json json) => UpcomingStayModel(
    reservationId: json['reservation_id'] as String,
    roomName: _text(json['room_name']),
    hotelName: _text(json['hotel_name']),
    cityName: _text(json['city_name']),
    nightlyRate: _money(json['nightly_rate']),
    isAvailable: (json['is_available'] as bool?) ?? true,
    imageUrl: json['image_url'] as String?,
    imageSeed: json['image_seed'] as String?,
  );

  final String reservationId;
  final LocalizedText roomName;
  final LocalizedText hotelName;
  final LocalizedText cityName;
  final Money nightlyRate;
  final bool isAvailable;
  final String? imageUrl;
  final String? imageSeed;

  UpcomingStay toEntity() => UpcomingStay(
    reservationId: reservationId,
    roomName: roomName,
    hotelName: hotelName,
    cityName: cityName,
    nightlyRate: nightlyRate,
    isAvailable: isAvailable,
    imageUrl: imageUrl,
    imageSeed: imageSeed,
  );
}

// Kept for symmetry / a future API data source that serialises requests.
Json localizedTextToJson(LocalizedText text) => _textJson(text);
Json moneyToJson(Money money) => _moneyJson(money);
