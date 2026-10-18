import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/errors/failure.dart';
import 'package:hotel_guest_app/core/presentation/ui_state.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/hotel_filters.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/hotel_search_result.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/hotel_sort.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/hotel_summary.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/localized_text.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/money.dart';
import 'package:hotel_guest_app/features/discovery/domain/repositories/discovery_repository.dart';
import 'package:hotel_guest_app/features/discovery/presentation/state/discovery_providers.dart';
import 'package:hotel_guest_app/features/discovery/presentation/state/hotel_search_controller.dart';

HotelSummary _hotel(int n) => HotelSummary(
      id: 'h$n',
      name: LocalizedText(ar: 'فندق $n', en: 'Hotel $n'),
      cityId: 'riyadh',
      cityName: const LocalizedText(ar: 'الرياض', en: 'Riyadh'),
      tagline: const LocalizedText(ar: '', en: ''),
      rating: 4.5,
      reviewCount: 10,
      nightlyRateFrom: Money(amount: 300),
      isAvailable: true,
    );

/// 45 hotels, served 20 per page like the API.
class _PagedRepo implements DiscoveryRepository {
  final List<int> pagesAsked = <int>[];
  bool failNext = false;

  @override
  Future<HotelSearchResult> searchHotels({
    String query = '',
    HotelFilters filters = HotelFilters.none,
    HotelSort sort = HotelSort.recommended,
    int page = 1,
  }) async {
    pagesAsked.add(page);
    if (failNext) {
      failNext = false;
      throw const Failure(FailureKind.network);
    }
    const int total = 45;
    final int start = (page - 1) * 20;
    final int end = (start + 20).clamp(0, total);
    return HotelSearchResult(
      hotels: <HotelSummary>[for (int i = start; i < end; i++) _hotel(i)],
      totalCount: total,
      page: page,
      hasMore: end < total,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late _PagedRepo repo;
  late ProviderContainer c;

  setUp(() {
    repo = _PagedRepo();
    c = ProviderContainer(
      overrides: <Override>[discoveryRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);
  });

  HotelSearchResult shown() =>
      (c.read(hotelSearchControllerProvider).results as UiSuccess<HotelSearchResult>).data;

  test('loads 20 hotels first, then appends each next page on demand', () async {
    final HotelSearchController controller =
        c.read(hotelSearchControllerProvider.notifier);
    await controller.ensureLoaded();
    expect(shown().hotels, hasLength(20));
    expect(shown().hasMore, isTrue);

    await controller.loadMore();
    await controller.loadMore();
    expect(shown().hotels, hasLength(45));
    expect(shown().hasMore, isFalse);

    await controller.loadMore(); // nothing left: no request
    expect(repo.pagesAsked, <int>[1, 2, 3]);
  });

  test('a failed next page keeps what is shown and offers a retry', () async {
    final HotelSearchController controller =
        c.read(hotelSearchControllerProvider.notifier);
    await controller.ensureLoaded();
    repo.failNext = true;
    await controller.loadMore();

    expect(shown().hotels, hasLength(20));
    expect(c.read(hotelSearchControllerProvider).loadMoreFailure, isNotNull);

    await controller.loadMore(); // the retry
    expect(shown().hotels, hasLength(40));
    expect(c.read(hotelSearchControllerProvider).loadMoreFailure, isNull);
  });

  test('a new search starts again from page 1', () async {
    final HotelSearchController controller =
        c.read(hotelSearchControllerProvider.notifier);
    await controller.ensureLoaded();
    await controller.loadMore();
    controller.setSort(HotelSort.priceAsc);
    await Future<void>.delayed(Duration.zero);

    expect(shown().hotels, hasLength(20));
    expect(repo.pagesAsked.last, 1);
  });
}
