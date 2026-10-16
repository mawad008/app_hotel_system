import 'package:flutter/foundation.dart';

import 'hotel_summary.dart';

/// The outcome of a hotel search: the matching summaries plus the total the data
/// source counted (drives "١٢ فندقاً متاحاً"). [hotels] is already filtered and
/// sorted by the data source — the presentation layer does not re-order it.
///
/// Results arrive a page at a time: [page] is the last page loaded and
/// [hasMore] says whether the server has further pages (loaded lazily as the
/// guest scrolls — see [append]).
@immutable
class HotelSearchResult {
  const HotelSearchResult({
    required this.hotels,
    required this.totalCount,
    this.page = 1,
    this.hasMore = false,
  });

  final List<HotelSummary> hotels;
  final int totalCount;
  final int page;
  final bool hasMore;

  bool get isEmpty => hotels.isEmpty;

  /// This result followed by [next], the following page. A hotel already
  /// shown is not repeated (the catalogue can shift between page loads).
  HotelSearchResult append(HotelSearchResult next) {
    final Set<String> shown = <String>{for (final HotelSummary h in hotels) h.id};
    return HotelSearchResult(
      hotels: <HotelSummary>[
        ...hotels,
        for (final HotelSummary h in next.hotels)
          if (!shown.contains(h.id)) h,
      ],
      totalCount: next.totalCount,
      page: next.page,
      hasMore: next.hasMore,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is HotelSearchResult &&
      listEquals(other.hotels, hotels) &&
      other.totalCount == totalCount &&
      other.page == page &&
      other.hasMore == hasMore;

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(hotels), totalCount, page, hasMore);
}
