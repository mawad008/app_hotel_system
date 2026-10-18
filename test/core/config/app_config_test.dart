import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/config/app_config.dart';

void main() {
  // No `--dart-define=API_BASE_URL` is set while running `flutter test`, so
  // `AppConfig.fromEnvironment()` always falls back to the hosted default.
  group('AppConfig.fromEnvironment default (no API_BASE_URL override)', () {
    final TargetPlatform? original = debugDefaultTargetPlatformOverride;

    tearDown(() {
      debugDefaultTargetPlatformOverride = original;
    });

    for (final TargetPlatform platform in <TargetPlatform>[
      TargetPlatform.android,
      TargetPlatform.iOS,
    ]) {
      test('$platform uses the hosted backend', () {
        debugDefaultTargetPlatformOverride = platform;

        final config = AppConfig.fromEnvironment();

        expect(config.apiBaseUrl, 'https://admin.hotel.webstdy.com');
        expect(config.apiRoot, 'https://admin.hotel.webstdy.com/api/v1');
      });
    }
  });
}
