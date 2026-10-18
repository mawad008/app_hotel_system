import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/config/app_config.dart';
import 'package:hotel_guest_app/core/network/api_client.dart';
import 'package:hotel_guest_app/core/security/in_memory_token_store.dart';
import 'package:hotel_guest_app/features/authentication/data/datasources/api_auth_data_source.dart';
import 'package:hotel_guest_app/features/discovery/data/datasources/api_discovery_data_source.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/guest_party.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/hotel_filters.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/hotel_sort.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/localized_text.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/money.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/stay_range.dart';
import 'package:hotel_guest_app/features/reservation/data/datasources/api_reservation_data_source.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/create_reservation_request.dart';

/// Records the URL of every outgoing request and fails it before any socket
/// opens, so the real [ApiClient] → Dio URL composition is observed with no
/// network traffic.
class _RecordingHttpClient implements HttpClient {
  _RecordingHttpClient(this.calls);

  final List<String> calls;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    calls.add('$method $url');
    throw const SocketException('blocked by test');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  // The production wiring: config from (absent) dart-defines → real ApiClient.
  test('real endpoints resolve under https://admin.hotel.webstdy.com/api/v1 exactly once', () async {
    final List<String> calls = <String>[];
    final ApiClient client = ApiClient(
      config: AppConfig.fromEnvironment(),
      tokenStore: InMemoryTokenStore(),
    );

    Future<void> attempt(Future<Object?> Function() call) async {
      try {
        await call();
      } catch (_) {
        // Expected: the recording client refuses every connection.
      }
    }

    await HttpOverrides.runZoned(() async {
      final ApiDiscoveryDataSource discovery = ApiDiscoveryDataSource(client);
      final ApiAuthDataSource auth = ApiAuthDataSource(client);
      final ApiReservationDataSource reservations = ApiReservationDataSource(client);

      await attempt(() => discovery.searchHotels(
            query: '',
            filters: const HotelFilters(),
            sort: HotelSort.recommended,
          ));
      await attempt(() => auth.requestOtp('+966500000000'));
      await attempt(() => auth.verifyOtp(
            challengeId: 'c',
            phoneE164: '+966500000000',
            attemptsRemaining: 3,
            code: '000000',
          ));
      await attempt(() => auth.completeProfile(
            accessToken: 't',
            phoneE164: '+966500000000',
            fullName: 'Test',
            email: 'test@example.com',
          ));
      await attempt(() => reservations.create(CreateReservationRequest(
            hotelId: '1',
            hotelName: const LocalizedText(ar: '', en: ''),
            roomTypeId: '1',
            roomName: const LocalizedText(ar: '', en: ''),
            stay: StayRange(checkIn: DateTime(2030, 1, 1), checkOut: DateTime(2030, 1, 2)),
            party: const GuestParty(adults: 1, children: 0),
            guestReference: 'url-test',
            priceSnapshot: const Money(amount: 1),
          )));
    }, createHttpClient: (SecurityContext? c) => _RecordingHttpClient(calls));

    expect(calls, <Matcher>[
      // A read whose connection fails is retried once (ApiClient.getJson);
      // writes never are.
      startsWith('GET https://admin.hotel.webstdy.com/api/v1/guest/hotels?'),
      startsWith('GET https://admin.hotel.webstdy.com/api/v1/guest/hotels?'),
      equals('POST https://admin.hotel.webstdy.com/api/v1/guest/auth/otp/request'),
      equals('POST https://admin.hotel.webstdy.com/api/v1/guest/auth/otp/verify'),
      equals('PATCH https://admin.hotel.webstdy.com/api/v1/guest/profile'),
      equals('POST https://admin.hotel.webstdy.com/api/v1/guest/reservations'),
    ]);
    for (final String call in calls) {
      expect(call, isNot(contains('/api/v1/api')));
      expect(call.split('/api/v1').length, 2, reason: call);
    }
  });
}
