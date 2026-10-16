import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/network/api_client.dart';
import 'package:hotel_guest_app/core/network/interceptors/error_interceptor.dart';

/// Answers each request with the next scripted outcome: `'drop'` (the
/// connection fails before any response), `'timeout'` (connecting times
/// out), an HTTP status such as `'500'`, or `'ok'`.
class _Server implements HttpClientAdapter {
  _Server(this.script);

  final List<String> script;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final String outcome = script[calls++];
    switch (outcome) {
      case 'drop':
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'connection reset',
        );
      case 'timeout':
        throw DioException.connectionTimeout(
          timeout: const Duration(seconds: 10),
          requestOptions: options,
        );
      case 'ok':
        return ResponseBody.fromString(
          jsonEncode(<String, dynamic>{'data': 'fresh'}),
          200,
          headers: _json,
        );
    }
    return ResponseBody.fromString(
      '{"message":"no"}',
      int.parse(outcome),
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
  ApiClient client(_Server server) => ApiClient.withDio(
    Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = server
      ..interceptors.add(ErrorInterceptor()),
  );

  test('a read that never reached the server is retried once', () async {
    for (final String failure in <String>['drop', 'timeout']) {
      final _Server server = _Server(<String>[failure, 'ok']);
      expect(
        (await client(server).getJson('/guest/hotels'))['data'],
        'fresh',
        reason: failure,
      );
      expect(server.calls, 2, reason: failure);
    }
  });

  test('only once: a second failed connection is reported', () async {
    final _Server server = _Server(<String>['drop', 'drop', 'ok']);
    await expectLater(
      client(server).getJson('/guest/hotels'),
      throwsA(isA<DioException>()),
    );
    expect(server.calls, 2);
  });

  test('an answer from the server is never retried', () async {
    for (final String status in <String>['404', '429', '500']) {
      final _Server server = _Server(<String>[status, 'ok']);
      await expectLater(
        client(server).getJson('/guest/hotels'),
        throwsA(isA<DioException>()),
        reason: status,
      );
      expect(server.calls, 1, reason: status);
    }
  });

  test('writes are never retried, even when the connection dropped', () async {
    final _Server server = _Server(<String>['drop', 'ok']);
    await expectLater(
      client(server).postJson('/guest/reservations', body: <String, dynamic>{}),
      throwsA(isA<DioException>()),
    );
    expect(server.calls, 1);
  });
}
