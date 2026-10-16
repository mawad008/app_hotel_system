import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/network/connect_timeout.dart';

void main() {
  late HttpOverrides? previous;
  setUp(() => previous = HttpOverrides.current);
  tearDown(() => HttpOverrides.global = previous);

  test('every HttpClient created afterwards gets the connect timeout', () {
    installConnectTimeout(timeout: const Duration(seconds: 7));
    final HttpClient client = HttpClient();
    addTearDown(client.close);
    expect(client.connectionTimeout, const Duration(seconds: 7));
  });
}
