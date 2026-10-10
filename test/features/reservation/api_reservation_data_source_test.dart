import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/network/api_client.dart';
import 'package:hotel_guest_app/core/network/interceptors/error_interceptor.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/guest_party.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/localized_text.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/money.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/room_selection.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/room_type_summary.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/stay_range.dart';
import 'package:hotel_guest_app/features/reservation/data/datasources/api_reservation_data_source.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/create_reservation_request.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.routes);

  final Map<String, (int, Map<String, dynamic>)> routes;
  final List<RequestOptions> received = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
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

ApiReservationDataSource _source(_FakeAdapter adapter) {
  final Dio dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
    ..httpClientAdapter = adapter
    ..interceptors.add(ErrorInterceptor());
  return ApiReservationDataSource(ApiClient.withDio(dio));
}

void main() {
  test('create posts room_type_id/dates/party and sets Idempotency-Key', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'POST /guest/reservations': (201, <String, dynamic>{
        'success': true,
        'message': 'Created',
        'data': <String, dynamic>{
          'id': 9,
          'hotel_id': 1,
          'room_type_id': 5,
          'status': 'pending',
          'check_in': '2026-09-06',
          'check_out': '2026-09-08',
          'nights': 2,
          'adults': 2,
          'children': 0,
          'price_snapshot': '600.00',
          'currency': 'SAR',
          'created_at': '2026-09-01T00:00:00Z',
        },
      }),
    });

    final RoomSelection selection = RoomSelection(
      hotelId: '1',
      hotelName: const LocalizedText(ar: 'واحة', en: 'Oasis'),
      roomType: const RoomTypeSummary(
        id: '5',
        name: LocalizedText(ar: 'ديلوكس', en: 'Deluxe'),
        description: LocalizedText(ar: '', en: ''),
        bedType: LocalizedText(ar: '', en: ''),
        maxOccupancy: 3,
        amenities: <RoomAmenity>[],
        nightlyRate: Money(amount: 300, currency: 'SAR'),
        breakfastIncluded: false,
        refundable: false,
      ),
      stay: StayRange(checkIn: DateTime(2026, 9, 6), checkOut: DateTime(2026, 9, 8)),
      party: const GuestParty(adults: 2, children: 0),
      nightlyRate: const Money(amount: 300, currency: 'SAR'),
    );

    final request = CreateReservationRequest.fromSelection(
      selection,
      guestReference: '+966500000000',
    );

    final model = await _source(adapter).create(request);

    expect(model.id, '9');
    expect(model.status.wireValue, 'pending');
    expect(model.priceSnapshot.amount, 600);
    expect(adapter.received.single.data, <String, dynamic>{
      'room_type_id': 5,
      'check_in': '2026-09-06',
      'check_out': '2026-09-08',
      'adults': 2,
      'children': 0,
    });
    // Header-safe for the backend (`[A-Za-z0-9._:-]`) and per attempt.
    final String key = adapter.received.single.headers['Idempotency-Key'] as String;
    expect(key, matches(RegExp(r'^[A-Za-z0-9._:-]+$')));
    final adapter2 = _FakeAdapter(adapter.routes);
    await _source(adapter2).create(request.withAttempt('abc123'));
    expect(adapter2.received.single.headers['Idempotency-Key'], 'rsv-abc123');
  });

  test('fetchById parses the nested hotel/room_type summaries', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'GET /guest/reservations/9': (200, <String, dynamic>{
        'success': true,
        'message': 'OK',
        'data': <String, dynamic>{
          'id': 9,
          'hotel_id': 1,
          'room_type_id': 5,
          'status': 'verified',
          'check_in': '2026-09-06',
          'check_out': '2026-09-08',
          'adults': 2,
          'children': 0,
          'price_snapshot': '600.00',
          'currency': 'SAR',
          'created_at': '2026-09-01T00:00:00Z',
          'hotel': <String, dynamic>{
            'id': 1,
            'name': 'Oasis',
            'city': 'Riyadh',
            'prices_include_taxes': true,
          },
          'room_type': <String, dynamic>{'id': 5, 'name': 'Deluxe', 'capacity': 3},
        },
      }),
    });

    final model = await _source(adapter).fetchById('9');
    expect(model.pricesIncludeTaxes, isTrue);
    expect(model.hotelName.en, 'Oasis');
    expect(model.roomName.en, 'Deluxe');
  });
}
