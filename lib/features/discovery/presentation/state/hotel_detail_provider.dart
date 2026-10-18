import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/localization/content_language_provider.dart';
import '../../../../core/presentation/cache_for.dart';
import '../../domain/entities/hotel.dart';
import 'discovery_providers.dart';

/// The full hotel for the detail screen (`02 · Discover & Book`, screen 3),
/// keyed by hotel id. Kept for a few minutes after the last screen using it
/// closes, so hotel → rooms → back → hotel doesn't refetch the same hotel.
final hotelDetailProvider = FutureProvider.autoDispose.family<Hotel, String>(
  (Ref ref, String hotelId) {
  ref.cacheFor(CacheDurations.catalogue);
  // Refetch in the new language after a language switch.
  ref.watch(contentLanguageProvider);
    return ref.watch(discoveryRepositoryProvider).hotel(hotelId);
  },
);

/// Index into the hotel's combined photo list of the picture currently shown
/// as the `HOTEL_Detail` hero — the guest swaps it by tapping a thumbnail in
/// the [HeroPhotoStrip]. `autoDispose` + keyed by hotel id so it always
/// starts back at the cover photo (index 0) on a fresh visit.
final heroPhotoIndexProvider =
    StateProvider.autoDispose.family<int, String>((Ref ref, String hotelId) => 0);
