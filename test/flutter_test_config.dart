import 'dart:async';

import 'package:hotel_guest_app/core/presentation/cache_for.dart';
import 'package:hotel_guest_app/core/widgets/app_image.dart';
import 'package:hotel_guest_app/features/discovery/presentation/widgets/hotel_location_map.dart';

/// Global setup for every test file (picked up by `flutter test`).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Map tiles can't load in widget tests, and the tile loader's real network /
  // on-disk cache I/O can hold a test process open for minutes.
  HotelLocationMap.tilesEnabled = false;
  // The image disk cache needs platform storage (path_provider, sqflite),
  // which tests don't have: use plain network images there.
  AppNetworkImages.diskCache = false;
  // In-memory caching keeps providers alive on a timer, which would outlive
  // each test's widget tree.
  CacheDurations.enabled = false;
  await testMain();
}
