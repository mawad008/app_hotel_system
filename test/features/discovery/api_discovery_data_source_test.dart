import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show Locale;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/errors/app_exception.dart';
import 'package:hotel_guest_app/core/network/api_client.dart';
import 'package:hotel_guest_app/core/network/api_image_url_resolver.dart';
import 'package:hotel_guest_app/core/network/interceptors/error_interceptor.dart';
import 'package:hotel_guest_app/core/network/response_cache.dart';
import 'package:hotel_guest_app/features/discovery/data/datasources/api_discovery_data_source.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/hotel_facility.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/hotel_filters.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/hotel_sort.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.routes);

  final Map<String, (int, Map<String, dynamic>)> routes;
  final List<RequestOptions> received = <RequestOptions>[];

  /// No connection: every request fails before reaching the server.
  bool offline = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (offline) {
      throw DioException.connectionError(requestOptions: options, reason: 'offline');
    }
    received.add(options);
    final String key = '${options.method} ${options.path}';
    final (int, Map<String, dynamic>) entry =
        routes[key] ?? (404, <String, dynamic>{'success': false, 'message': 'no route $key'});
    return ResponseBody.fromString(
      jsonEncode(entry.$2),
      entry.$1,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ApiDiscoveryDataSource _source(
  _FakeAdapter adapter, {
  ApiImageUrlResolver? imageUrlResolver,
  ResponseCache? responseCache,
}) {
  final Dio dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
    ..httpClientAdapter = adapter
    ..interceptors.add(ErrorInterceptor());
  return ApiDiscoveryDataSource(
    imageUrlResolver == null
        ? ApiClient.withDio(dio, responseCache: responseCache)
        : ApiClient.withDio(
            dio,
            imageUrlResolver: imageUrlResolver,
            responseCache: responseCache,
          ),
  );
}

void main() {
  test('fetchCities maps city + hotel_count', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'GET /guest/hotels/cities': (200, <String, dynamic>{
        'success': true,
        'message': 'OK',
        'data': <Map<String, dynamic>>[
          <String, dynamic>{'city': 'Riyadh', 'hotel_count': 3},
        ],
      }),
    });

    final cities = await _source(adapter).fetchCities();
    expect(cities.single.id, 'Riyadh');
    expect(cities.single.hotelCount, 3);
  });

  test('searchHotels parses PublicHotelResource rows and reads meta.total', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'GET /guest/hotels': (200, <String, dynamic>{
        'success': true,
        'message': 'OK',
        'data': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 1,
            'name': 'Oasis',
            'tagline': 'Nice place',
            'city': 'Riyadh',
            'star_rating': 4,
            'price_from': '250.00',
          },
        ],
        'meta': <String, dynamic>{'total': 12},
      }),
    });

    final result = await _source(adapter).searchHotels(
      query: '',
      filters: HotelFilters.none,
      sort: HotelSort.recommended,
    );

    expect(result.hotels.single.id, '1');
    expect(result.hotels.single.cityId, 'Riyadh');
    expect(result.hotels.single.nightlyRateFrom.amount, 250);
    expect(result.totalCount, 12);
  });

  test('searchHotels asks for one page at a time and reports whether more '
      'pages exist', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'GET /guest/hotels': (200, <String, dynamic>{
        'success': true,
        'message': 'OK',
        'data': <Map<String, dynamic>>[],
        'meta': <String, dynamic>{'current_page': 2, 'last_page': 3, 'total': 45},
      }),
    });

    final result = await _source(adapter).searchHotels(
      query: '',
      filters: HotelFilters.none,
      sort: HotelSort.recommended,
      page: 2,
    );

    expect(adapter.received.single.queryParameters['page'], 2);
    expect(
      adapter.received.single.queryParameters['per_page'],
      ApiDiscoveryDataSource.searchPageSize,
    );
    expect(result.page, 2);
    expect(result.hasMore, isTrue);
    expect(result.totalCount, 45);
  });

  test('searchHotels sends the single selected city as the city query param', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'GET /guest/hotels': (200, <String, dynamic>{
        'success': true,
        'message': 'OK',
        'data': <Map<String, dynamic>>[],
      }),
    });

    await _source(adapter).searchHotels(
      query: 'spa',
      filters: const HotelFilters(cityIds: <String>{'Jeddah'}),
      sort: HotelSort.recommended,
    );

    expect(adapter.received.single.queryParameters['city'], 'Jeddah');
    expect(adapter.received.single.queryParameters['q'], 'spa');
  });

  test('fetchAvailability parses RoomAvailabilityResource rows', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'GET /guest/hotels/1/availability': (200, <String, dynamic>{
        'success': true,
        'message': 'OK',
        'data': <String, dynamic>{
          'hotel_id': 1,
          'check_in': '2026-09-06',
          'check_out': '2026-09-08',
          'adults': 2,
          'children': 0,
          'rooms': <Map<String, dynamic>>[
            <String, dynamic>{
              'room_type_id': 5,
              'name': 'Deluxe',
              'base_price': '300.00',
              'capacity': 3,
              'rooms_available': 2,
              'is_available': true,
            },
          ],
        },
      }),
    });

    final result = await _source(adapter).fetchAvailability(
      hotelId: '1',
      checkIn: DateTime(2026, 9, 6),
      checkOut: DateTime(2026, 9, 8),
      adults: 2,
      children: 0,
    );

    expect(result.hotelId, '1');
    expect(result.rooms.single.isAvailable, isTrue);
    expect(result.rooms.single.roomType.nightlyRate.amount, 300);
  });

  test('fetchAvailability maps the real bed type / area / breakfast / refundable fields', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'GET /guest/hotels/1/availability': (200, <String, dynamic>{
        'success': true,
        'message': 'OK',
        'data': <String, dynamic>{
          'hotel_id': 1,
          'check_in': '2026-09-06',
          'check_out': '2026-09-08',
          'adults': 2,
          'children': 0,
          'rooms': <Map<String, dynamic>>[
            <String, dynamic>{
              'room_type_id': 5,
              'name': 'Deluxe',
              'base_price': '300.00',
              'capacity': 3,
              'is_available': true,
              'bed_type': 'Double bed',
              'area_sqm': 28,
              'breakfast_included': true,
              'refundable': true,
            },
          ],
        },
      }),
    });

    final result = await _source(adapter).fetchAvailability(
      hotelId: '1',
      checkIn: DateTime(2026, 9, 6),
      checkOut: DateTime(2026, 9, 8),
      adults: 2,
      children: 0,
    );

    final roomType = result.rooms.single.roomType;
    expect(roomType.bedType.resolve(const Locale('en')), 'Double bed');
    expect(roomType.areaSqm, 28);
    expect(roomType.breakfastIncluded, isTrue);
    expect(roomType.refundable, isTrue);
  });

  test('fetchAvailability leaves bed type / area / breakfast / refundable at their safe defaults when absent', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'GET /guest/hotels/1/availability': (200, <String, dynamic>{
        'success': true,
        'message': 'OK',
        'data': <String, dynamic>{
          'hotel_id': 1,
          'check_in': '2026-09-06',
          'check_out': '2026-09-08',
          'adults': 2,
          'children': 0,
          'rooms': <Map<String, dynamic>>[
            <String, dynamic>{
              'room_type_id': 5,
              'name': 'Deluxe',
              'base_price': '300.00',
              'capacity': 3,
              'is_available': true,
            },
          ],
        },
      }),
    });

    final result = await _source(adapter).fetchAvailability(
      hotelId: '1',
      checkIn: DateTime(2026, 9, 6),
      checkOut: DateTime(2026, 9, 8),
      adults: 2,
      children: 0,
    );

    final roomType = result.rooms.single.roomType;
    expect(roomType.bedType.resolve(const Locale('en')), '');
    expect(roomType.areaSqm, isNull);
    expect(roomType.breakfastIncluded, isFalse);
    expect(roomType.refundable, isFalse);
  });

  test('fetchAvailability rewrites room-type gallery[].url onto the configured API host', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'GET /guest/hotels/1/availability': (200, <String, dynamic>{
        'success': true,
        'message': 'OK',
        'data': <String, dynamic>{
          'hotel_id': 1,
          'check_in': '2026-09-06',
          'check_out': '2026-09-08',
          'adults': 2,
          'children': 0,
          'rooms': <Map<String, dynamic>>[
            <String, dynamic>{
              'room_type_id': 5,
              'name': 'Deluxe',
              'base_price': '300.00',
              'capacity': 3,
              'is_available': true,
              'gallery': <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 1,
                  'url': 'http://localhost:8000/storage/room-types/5/gallery/a.png',
                },
                <String, dynamic>{
                  'id': 2,
                  'url': 'http://localhost:8000/storage/room-types/5/gallery/b.png',
                },
              ],
            },
          ],
        },
      }),
    });

    final result = await _source(
      adapter,
      imageUrlResolver: const ApiImageUrlResolver('http://10.0.2.2:8000'),
    ).fetchAvailability(
      hotelId: '1',
      checkIn: DateTime(2026, 9, 6),
      checkOut: DateTime(2026, 9, 8),
      adults: 2,
      children: 0,
    );

    final roomType = result.rooms.single.roomType.toEntity();
    expect(roomType.galleryUrls, <String>[
      'http://10.0.2.2:8000/storage/room-types/5/gallery/a.png',
      'http://10.0.2.2:8000/storage/room-types/5/gallery/b.png',
    ]);
    expect(roomType.coverUrl, 'http://10.0.2.2:8000/storage/room-types/5/gallery/a.png');
  });

  test('fetchFeaturedHotels maps real PublicHotelResource rows (Hotels of the Group)', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'GET /guest/hotels': (200, <String, dynamic>{
        'success': true,
        'message': 'OK',
        'data': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 1,
            'name': 'Oasis',
            'tagline': 'Nice place',
            'city': 'Riyadh',
            'star_rating': 4,
            'rating': '4.50',
            'reviews_count': 12,
            'price_from': '250.00',
            'cover_url': 'https://cdn.example.com/oasis.jpg',
          },
        ],
        'meta': <String, dynamic>{'total': 1},
      }),
    });

    final hotels = await _source(adapter).fetchFeaturedHotels();
    expect(hotels.single.id, '1');
    // `rating` comes from the review-average field, never `star_rating`.
    expect(hotels.single.rating, 4.5);
    expect(hotels.single.reviewCount, 12);
    expect(hotels.single.coverUrl, 'https://cdn.example.com/oasis.jpg');
  });

  test('every read Home makes is served from the saved copy offline', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'GET /guest/hotels': (200, <String, dynamic>{
        'success': true,
        'message': 'OK',
        'data': <Map<String, dynamic>>[
          <String, dynamic>{'id': 1, 'name': 'Oasis', 'city': 'Riyadh'},
          <String, dynamic>{'id': 2, 'name': 'Marsa', 'city': 'Dammam'},
        ],
        'meta': <String, dynamic>{'total': 2},
      }),
    });
    final ApiDiscoveryDataSource source =
        _source(adapter, responseCache: InMemoryResponseCache());
    await source.fetchFeaturedHotels();
    await source.fetchGroupHotelCount();

    adapter.offline = true;
    expect(
      (await source.fetchFeaturedHotels()).map((h) => h.id),
      <String>['1', '2'],
    );
    expect(await source.fetchGroupHotelCount(), 2);
  });

  test('fetchFeaturedHotels requests recommended (most-booked) order', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'GET /guest/hotels': (200, <String, dynamic>{
        'success': true,
        'message': 'OK',
        'data': <Map<String, dynamic>>[],
        'meta': <String, dynamic>{'total': 0},
      }),
    });

    await _source(adapter).fetchFeaturedHotels();
    expect(adapter.received.single.queryParameters['sort'], 'recommended');
  });

  test('fetchHotel rewrites cover_url and gallery[].url onto the configured API host', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'GET /guest/hotels/4': (200, <String, dynamic>{
        'success': true,
        'message': 'OK',
        'data': <String, dynamic>{
          'id': 4,
          'name': 'Leo Richmond',
          'city': 'Alexandria',
          'star_rating': 4,
          'cover_url': 'http://localhost:8000/storage/hotels/4/cover/ktPwWh7.webp',
          'gallery': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 3,
              'url': 'http://localhost:8000/storage/hotels/4/gallery/a.png',
            },
          ],
          'room_types': <Map<String, dynamic>>[],
        },
      }),
    });

    final hotel = await _source(
      adapter,
      imageUrlResolver: const ApiImageUrlResolver('http://10.0.2.2:8000'),
    ).fetchHotel('4');

    expect(hotel.summary.coverUrl, 'http://10.0.2.2:8000/storage/hotels/4/cover/ktPwWh7.webp');
    expect(hotel.galleryUrls.single, 'http://10.0.2.2:8000/storage/hotels/4/gallery/a.png');
  });

  test('fetchHotel rewrites entry-room gallery[].url onto the configured API host', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'GET /guest/hotels/4': (200, <String, dynamic>{
        'success': true,
        'message': 'OK',
        'data': <String, dynamic>{
          'id': 4,
          'name': 'Leo Richmond',
          'city': 'Alexandria',
          'star_rating': 4,
          'room_types': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 9,
              'name': 'Deluxe',
              'base_price': '400.00',
              'capacity': 2,
              'gallery': <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 1,
                  'url': 'http://localhost:8000/storage/room-types/9/gallery/a.png',
                },
              ],
            },
          ],
        },
      }),
    });

    final hotel = await _source(
      adapter,
      imageUrlResolver: const ApiImageUrlResolver('http://10.0.2.2:8000'),
    ).fetchHotel('4');

    expect(
      hotel.entryRoom!.toEntity().coverUrl,
      'http://10.0.2.2:8000/storage/room-types/9/gallery/a.png',
    );
  });

  test(
      'fetchHotel derives the "from" price from the cheapest room_type '
      'when the single-hotel resource has no price_from field', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'GET /guest/hotels/4': (200, <String, dynamic>{
        'success': true,
        'message': 'OK',
        'data': <String, dynamic>{
          'id': 4,
          'name': 'Leo Richmond',
          'city': 'Alexandria',
          'country': 'Egypt',
          'star_rating': 4,
          'amenities': <Map<String, dynamic>>[
            <String, dynamic>{'key': 'breakfast', 'label': 'Breakfast', 'description': 'Served 6–11', 'icon': 'coffee'},
            <String, dynamic>{'key': 'airport_shuttle', 'label': 'Airport shuttle', 'description': ' ', 'icon': null},
          ],
          'reviews_count': 0,
          // No `price_from` — only the real API bug this reproduces.
          'room_types': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 7,
              'name': 'Minima est ullam arc',
              'base_price': '3333.00',
              'capacity': 94,
              'amenities': <String>['breakfast', 'airport_shuttle'],
            },
            <String, dynamic>{
              'id': 8,
              'name': 'Cheaper room',
              'base_price': '1200.00',
              'capacity': 2,
              'amenities': <String>[],
            },
          ],
        },
      }),
    });

    final hotel = await _source(adapter).fetchHotel('4');

    // The lowest of the two room types, never the first / a hardcoded value.
    expect(hotel.summary.nightlyRateFrom.amount, 1200);
    expect(hotel.country?.en, 'Egypt');
    expect(hotel.summary.starRating, 4);
    expect(hotel.facilities.map((HotelFacility f) => f.key), <String>['breakfast', 'airport_shuttle']);
    expect(hotel.facilities.first.label.en, 'Breakfast');
    expect(hotel.facilities.first.icon, 'coffee');
    expect(hotel.facilities.first.description?.en, 'Served 6–11');
    // A blank description is absent, not an empty line.
    expect(hotel.facilities.last.description, isNull);
    // `reviews_count: 0` and no `rating` field — never fabricated.
    expect(hotel.summary.rating, isNull);
  });

  test('fetchFeaturedHotels still uses the list endpoint\'s own price_from as-is', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'GET /guest/hotels': (200, <String, dynamic>{
        'success': true,
        'message': 'OK',
        'data': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 1,
            'name': 'Oasis',
            'city': 'Riyadh',
            'star_rating': 4,
            'price_from': '250.00',
          },
        ],
        'meta': <String, dynamic>{'total': 1},
      }),
    });

    final hotels = await _source(adapter).fetchFeaturedHotels();
    expect(hotels.single.nightlyRateFrom.amount, 250);
  });

  test('fetchUpcomingStay stays a documented gap — discovery has no reservation access', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{});
    final source = _source(adapter);

    expect(source.fetchUpcomingStay(), throwsA(isA<NotImplementedInPhaseException>()));
  });

  test('shows the localized city / country names, keeps city as the filter key', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'GET /guest/hotels/cities': (200, <String, dynamic>{
        'success': true,
        'message': 'OK',
        'data': <Map<String, dynamic>>[
          <String, dynamic>{'city': 'Jeddah', 'name': 'جدة', 'hotel_count': 1},
        ],
      }),
      'GET /guest/hotels/4': (200, <String, dynamic>{
        'success': true,
        'message': 'OK',
        'data': <String, dynamic>{
          'id': 4,
          'name': 'فندق الواحة',
          'city': 'Jeddah',
          'city_name': 'جدة',
          'country': 'Saudi Arabia',
          'country_name': 'المملكة العربية السعودية',
          'room_types': <Object?>[],
        },
      }),
    });

    final cities = await _source(adapter).fetchCities();
    expect(cities.single.id, 'Jeddah');
    expect(cities.single.name.ar, 'جدة');

    final hotel = await _source(adapter).fetchHotel('4');
    expect(hotel.summary.cityId, 'Jeddah');
    expect(hotel.summary.cityName.ar, 'جدة');
    expect(hotel.country?.ar, 'المملكة العربية السعودية');
  });
}
