import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show KeepAliveLink;

/// How long public, slowly-changing data stays in memory after its last
/// screen closes.
abstract final class CacheDurations {
  /// A hotel's detail page: details, photos, rooms on offer.
  static const Duration catalogue = Duration(minutes: 5);

  /// Reference lists that change a few times a year at most (FAQ, document
  /// types, review categories, a hotel's service menu).
  static const Duration reference = Duration(minutes: 30);

  /// Off in widget tests (`flutter_test_config.dart`): a countdown still
  /// running when a test's widget tree is torn down fails the test.
  static bool enabled = true;
}

extension CacheForRef on Ref {
  /// Keeps an `autoDispose` provider's value for [duration] after its last
  /// listener goes away, so returning to the screen within that window shows
  /// it at once instead of fetching it again. Any new listener cancels the
  /// countdown; `ref.invalidate` / pull-to-refresh still refetch on demand.
  ///
  /// Only for public data (hotels, reference lists) — never for the guest's
  /// own live data (bookings, payments, notifications), which must be fresh.
  void cacheFor(Duration duration) {
    if (!CacheDurations.enabled) return;
    final KeepAliveLink link = keepAlive();
    Timer? timer;
    onCancel(() {
      timer?.cancel();
      timer = Timer(duration, link.close);
    });
    onResume(() => timer?.cancel());
    onDispose(() => timer?.cancel());
  }
}
