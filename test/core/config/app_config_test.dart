import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/config/app_config.dart';
import 'package:hotel_guest_app/core/config/app_environment.dart';

void main() {
  // No `--dart-define=API_BASE_URL` is set while running `flutter test`, so
  // `AppConfig.fromEnvironment()` always falls back to the per-platform dev
  // default under test — exactly the branch this guards.
  group('AppConfig.fromEnvironment platform default (no API_BASE_URL override)', () {
    final TargetPlatform? original = debugDefaultTargetPlatformOverride;

    tearDown(() {
      debugDefaultTargetPlatformOverride = original;
    });

    test('Android gets the emulator-to-host loopback alias, not localhost', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      final config = AppConfig.fromEnvironment();

      expect(config.apiBaseUrl, 'http://10.0.2.2:8000');
    });

    test('iOS gets the real loopback — 10.0.2.2 is meaningless off the Android emulator', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      final config = AppConfig.fromEnvironment();

      expect(config.apiBaseUrl, 'http://127.0.0.1:8000');
    });
  });

  group('a release build without defines', () {
    final TargetPlatform? original = debugDefaultTargetPlatformOverride;

    tearDown(() {
      debugDefaultTargetPlatformOverride = original;
    });

    test('talks to production on every platform, never a dev machine', () {
      // The App Review failure: an iOS archive built without the defines.
      for (final TargetPlatform platform in <TargetPlatform>[
        TargetPlatform.iOS,
        TargetPlatform.android,
      ]) {
        debugDefaultTargetPlatformOverride = platform;

        final AppConfig config = AppConfig.resolve(release: true);

        expect(
          config.apiBaseUrl,
          AppConfig.productionBaseUrl,
          reason: '$platform',
        );
        expect(config.environment, AppEnvironment.production);
        expect(config.useDummyData, isFalse);
      }
    });

    test('still lets defines that were passed win', () {
      final AppConfig config = AppConfig.resolve(
        release: true,
        appEnv: 'staging',
        apiBaseUrl: 'https://staging.example.com',
      );

      expect(config.apiBaseUrl, 'https://staging.example.com');
      expect(config.environment, AppEnvironment.staging);
    });
  });

  test('the production fallback matches config/production.json', () {
    final Map<String, dynamic> production = jsonDecode(
      File('config/production.json').readAsStringSync(),
    ) as Map<String, dynamic>;

    expect(AppConfig.productionBaseUrl, production['API_BASE_URL']);
    expect(production['APP_ENV'], 'production');
  });
}
