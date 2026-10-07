import '../../../../core/data/data_source.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/hotel_filters.dart';
import '../../domain/entities/hotel_sort.dart';
import '../../domain/entities/money.dart';
import '../fixtures/discovery_fixtures.dart';
import '../models/discovery_models.dart';
import 'discovery_data_source.dart';

/// Deterministic, offline discovery source used while the Laravel catalogue API
/// is not wired.
///
/// Guarantees required by the phase brief:
/// * no network, no timers, no randomness, no artificial delays;
/// * results depend only on the method arguments and the fixed
///   [DiscoveryFixtures] dataset;
/// * availability is a *demonstration* — the mobile app never computes
///   authoritative availability. The rule here is simple and documented: a room
///   type is offered when its `max_occupancy` covers the whole party and the
///   fixture marks the offering `available`. If the party is larger than every
///   room type, the result is empty (the no-results screen).
class DummyDiscoveryDataSource implements DiscoveryDataSource, DummyDataSource {
  const DummyDiscoveryDataSource({this.singleHotelGroup = false});

  /// When `true` the group is presented as operating one hotel (`oasis`) — the
  /// Home screen then shows its single-hotel layout. QA flag only
  /// (`--dart-define=SINGLE_HOTEL=true`).
  final bool singleHotelGroup;

  static const String _soleHotelId = 'oasis';

  Iterable<Json> get _hotels => singleHotelGroup
      ? DiscoveryFixtures.hotels.where((Json h) => h['id'] == _soleHotelId)
      : DiscoveryFixtures.hotels;

  @override
  Future<List<CityModel>> fetchCities() async => <CityModel>[
        for (final Json city in DiscoveryFixtures.cities) CityModel.fromJson(city),
      ];

  @override
  Future<List<HotelSummaryModel>> fetchFeaturedHotels() async {
    final List<Json> featured = _hotels
        .where((Json h) => (h['featured'] as bool?) ?? false)
        .toList(growable: false)
      ..sort(_byFeaturedRank);
    return <HotelSummaryModel>[
      for (final Json hotel in featured) HotelSummaryModel.fromJson(hotel),
    ];
  }

  @override
  Future<int> fetchGroupHotelCount() async => _hotels.length;

  @override
  Future<List<AvailableRoomModel>> fetchHotelRooms(String hotelId) async {
    final Json hotel = _hotelById(hotelId);
    return <AvailableRoomModel>[
      for (final Object? raw in (hotel['room_offerings'] as List<Object?>? ??
          const <Object?>[]))
        AvailableRoomModel.fromJson(<String, Object?>{
          'is_available': ((raw! as Json)['available'] as bool?) ?? true,
          'room_type': <String, Object?>{
            ...DiscoveryFixtures.roomCatalogue[(raw as Json)['room_type_id']]!,
            'nightly_rate': <String, Object?>{
              'amount': ((raw)['nightly_rate'] as num).toInt(),
              'currency': Money.fallbackCurrency,
            },
          },
        }),
    ];
  }

  @override
  Future<UpcomingStayModel?> fetchUpcomingStay() async =>
      UpcomingStayModel.fromJson(_designUpcomingStay);

  /// Design-only fixture for the Home `إقامتك القادمة` card. Not a real
  /// reservation — the reservations feature / Laravel own that.
  static const Json _designUpcomingStay = <String, Object?>{
    // The seeded Palm Hotel booking in `DummyReservationDataSource`, so the
    // card opens a real demo booking instead of "Booking not found".
    'reservation_id': 'seed-verified',
    'room_name': <String, Object?>{
      'ar': 'غرفة مزدوجة ديلوكس',
      'en': 'Deluxe Double Room',
    },
    'hotel_name': <String, Object?>{'ar': 'فندق النخيل', 'en': 'The Palm Hotel'},
    'city_name': <String, Object?>{'ar': 'الرياض', 'en': 'Riyadh'},
    'image_seed': 'RSV-DEMO-1',
    'nightly_rate': <String, Object?>{'amount': 450, 'currency': Money.fallbackCurrency},
    'is_available': true,
  };

  @override
  Future<HotelSearchResultModel> searchHotels({
    required String query,
    required HotelFilters filters,
    required HotelSort sort,
  }) async {
    final String needle = query.trim().toLowerCase();

    final List<Json> matched = _hotels.where((Json hotel) {
      if (needle.isNotEmpty && !_matchesQuery(hotel, needle)) return false;
      if (filters.cityIds.isNotEmpty &&
          !filters.cityIds.contains(hotel['city_id'])) {
        return false;
      }
      if (filters.priceRange != null &&
          !filters.priceRange!.contains(_rateFrom(hotel))) {
        return false;
      }
      return true;
    }).toList(growable: false);

    matched.sort(_comparatorFor(sort));

    return HotelSearchResultModel(
      hotels: <HotelSummaryModel>[
        for (final Json hotel in matched) HotelSummaryModel.fromJson(hotel),
      ],
      totalCount: matched.length,
    );
  }

  @override
  Future<HotelModel> fetchHotel(String hotelId) async {
    final Json hotel = _hotelById(hotelId);
    return HotelModel.fromJson(<String, Object?>{
      ...hotel,
      if (_entryRoomJson(hotel) != null) 'entry_room': _entryRoomJson(hotel),
    });
  }

  /// The cheapest bookable offering, resolved against the room catalogue — the
  /// detail screen's spec chips (area / occupancy / bed) come from it.
  Json? _entryRoomJson(Json hotel) {
    final List<Object?> offerings =
        (hotel['room_offerings'] as List<Object?>? ?? const <Object?>[]);
    Json? cheapest;
    int cheapestRate = 1 << 30;
    for (final Object? raw in offerings) {
      final Json offering = raw! as Json;
      if (!((offering['available'] as bool?) ?? true)) continue;
      final int rate = (offering['nightly_rate'] as num).toInt();
      if (rate >= cheapestRate) continue;
      cheapestRate = rate;
      cheapest = offering;
    }
    if (cheapest == null) return null;
    return <String, Object?>{
      ...DiscoveryFixtures.roomCatalogue[cheapest['room_type_id']]!,
      'nightly_rate': <String, Object?>{
        'amount': cheapestRate,
        'currency': Money.fallbackCurrency,
      },
    };
  }

  @override
  Future<AvailabilityResultModel> fetchAvailability({
    required String hotelId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int adults,
    required int children,
  }) async {
    final Json hotel = _hotelById(hotelId);
    final int party = adults + children;

    final List<Json> rooms = <Json>[];
    for (final Object? raw in (hotel['room_offerings'] as List<Object?>? ?? const <Object?>[])) {
      final Json offering = raw! as Json;
      final Json catalogue =
          DiscoveryFixtures.roomCatalogue[offering['room_type_id']]!;
      final int maxOccupancy = (catalogue['max_occupancy'] as num).toInt();
      if (party > maxOccupancy) continue; // party cannot fit this room type

      rooms.add(<String, Object?>{
        'is_available': (offering['available'] as bool?) ?? true,
        'room_type': <String, Object?>{
          ...catalogue,
          'nightly_rate': <String, Object?>{
            'amount': (offering['nightly_rate'] as num).toInt(),
            'currency': Money.fallbackCurrency,
          },
        },
      });
    }

    return AvailabilityResultModel.fromJson(<String, Object?>{
      'hotel_id': hotelId,
      'check_in': _isoDate(checkIn),
      'check_out': _isoDate(checkOut),
      'adults': adults,
      'children': children,
      'rooms': rooms,
    });
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  Json _hotelById(String hotelId) {
    for (final Json hotel in _hotels) {
      if (hotel['id'] == hotelId) return hotel;
    }
    throw NotFoundException('No hotel with id "$hotelId"');
  }

  static bool _matchesQuery(Json hotel, String needle) {
    final Json name = hotel['name']! as Json;
    final Json city = hotel['city_name']! as Json;
    return <Object?>[name['ar'], name['en'], city['ar'], city['en']]
        .whereType<String>()
        .any((String value) => value.toLowerCase().contains(needle));
  }

  static int _rateFrom(Json hotel) =>
      ((hotel['nightly_rate_from']! as Json)['amount']! as num).toInt();

  static double? _rating(Json hotel) => (hotel['rating'] as num?)?.toDouble();

  static int _byFeaturedRank(Json a, Json b) =>
      (a['featured_rank']! as num).compareTo(b['featured_rank']! as num);

  static Comparator<Json> _comparatorFor(HotelSort sort) {
    switch (sort) {
      case HotelSort.recommended:
        return _byFeaturedRank;
      case HotelSort.priceAsc:
        return (Json a, Json b) {
          final int byPrice = _rateFrom(a).compareTo(_rateFrom(b));
          return byPrice != 0 ? byPrice : _byFeaturedRank(a, b);
        };
      case HotelSort.ratingDesc:
        return (Json a, Json b) {
          final int byRating = (_rating(b) ?? 0).compareTo(_rating(a) ?? 0);
          return byRating != 0 ? byRating : _byFeaturedRank(a, b);
        };
    }
  }

  static String _isoDate(DateTime date) =>
      DateTime(date.year, date.month, date.day).toIso8601String();
}
