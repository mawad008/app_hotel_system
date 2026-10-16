import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/network/api_client.dart';
import 'package:hotel_guest_app/core/network/interceptors/error_interceptor.dart';
import 'package:hotel_guest_app/core/network/response_cache.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// A server that answers, or fails the way [mode] says.
class _Server implements HttpClientAdapter {
  String mode = 'ok';
  int version = 1;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    switch (mode) {
      case 'offline':
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'no route to host',
        );
      case '404':
        return ResponseBody.fromString('{"message":"gone"}', 404, headers: _json);
      case '500':
        return ResponseBody.fromString('{"message":"down"}', 500, headers: _json);
    }
    return ResponseBody.fromString(
      jsonEncode(<String, dynamic>{'data': <String, dynamic>{'v': version}}),
      200,
      headers: _json,
    );
  }

  static final Map<String, List<String>> _json = <String, List<String>>{
    Headers.contentTypeHeader: <String>[Headers.jsonContentType],
  };

  @override
  void close({bool force = false}) {}
}

void main() {
  late _Server server;
  late InMemoryResponseCache cache;
  String language = 'ar';

  ApiClient client() => ApiClient.withDio(
        Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
          ..httpClientAdapter = server
          ..interceptors.add(ErrorInterceptor()),
        responseCache: cache,
        languageCode: () => language,
      );

  setUp(() {
    server = _Server();
    cache = InMemoryResponseCache();
    language = 'ar';
  });

  test('offline or server down: the last good response is served', () async {
    expect(
      (await client().getJson('/guest/hotels', offlineFallback: true))['data'],
      <String, dynamic>{'v': 1},
    );

    for (final String failure in <String>['offline', '500']) {
      server.mode = failure;
      expect(
        (await client().getJson('/guest/hotels', offlineFallback: true))['data'],
        <String, dynamic>{'v': 1},
        reason: failure,
      );
    }
  });

  test('a real answer such as 404 is never masked by a saved copy', () async {
    await client().getJson('/guest/hotels/9', offlineFallback: true);
    server.mode = '404';
    expect(
      () => client().getJson('/guest/hotels/9', offlineFallback: true),
      throwsA(isA<DioException>()),
    );
  });

  test('saved copies are per language, and only for opted-in reads', () async {
    await client().getJson('/guest/hotels', offlineFallback: true);
    await client().getJson('/guest/hotels/4/availability');
    server.mode = 'offline';

    language = 'en';
    expect(
      () => client().getJson('/guest/hotels', offlineFallback: true),
      throwsA(isA<DioException>()),
      reason: 'the Arabic copy must not stand in for English',
    );
    language = 'ar';
    expect(
      () => client().getJson('/guest/hotels/4/availability'),
      throwsA(isA<DioException>()),
      reason: 'availability is never served stale',
    );
  });

  test('the persistent cache keeps only the most recent entries', () async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final PersistentResponseCache persistent = PersistentResponseCache(capacity: 2);
    await persistent.write('a', <String, dynamic>{'n': 1});
    await persistent.write('b', <String, dynamic>{'n': 2});
    await persistent.write('c', <String, dynamic>{'n': 3});

    expect(await persistent.read('a'), isNull);
    expect(await persistent.read('b'), <String, dynamic>{'n': 2});
    expect(await persistent.read('c'), <String, dynamic>{'n': 3});
  });
}
