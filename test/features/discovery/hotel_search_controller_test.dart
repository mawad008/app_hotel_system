import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/di/core_providers.dart';
import 'package:hotel_guest_app/core/presentation/ui_state.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/hotel_filters.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/hotel_search_result.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/hotel_sort.dart';
import 'package:hotel_guest_app/features/discovery/presentation/state/hotel_search_controller.dart';

import '../../support/test_config.dart';

ProviderContainer _container() {
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[appConfigProvider.overrideWithValue(testConfig)],
  );
  addTearDown(container.dispose);
  container.listen(hotelSearchControllerProvider, (_, _) {});
  return container;
}

HotelSearchController _notifier(ProviderContainer c) =>
    c.read(hotelSearchControllerProvider.notifier);

Future<void> _settle(ProviderContainer c) async {
  for (int i = 0; i < 50; i++) {
    if (c.read(hotelSearchControllerProvider).results is! UiLoading<HotelSearchResult>) {
      return;
    }
    await Future<void>.delayed(Duration.zero);
  }
}

HotelSearchResult _result(ProviderContainer c) =>
    (c.read(hotelSearchControllerProvider).results as UiSuccess<HotelSearchResult>)
        .data;

void main() {
  test('starts initial, then ensureLoaded loads every hotel', () async {
    final ProviderContainer c = _container();
    expect(c.read(hotelSearchControllerProvider).results,
        isA<UiInitial<HotelSearchResult>>());

    await _notifier(c).ensureLoaded();
    await _settle(c);

    expect(_result(c).totalCount, greaterThanOrEqualTo(8));
  });

  test('setQuery narrows the results', () async {
    final ProviderContainer c = _container();
    await _notifier(c).ensureLoaded();
    await _settle(c);

    _notifier(c).setQuery('الواحة');
    await _settle(c);
    expect(_result(c).hotels.single.id, 'oasis');
  });

  test('a query with no matches produces an empty state', () async {
    final ProviderContainer c = _container();
    _notifier(c).setQuery('zzzzz');
    await _settle(c);
    expect(c.read(hotelSearchControllerProvider).results,
        isA<UiEmpty<HotelSearchResult>>());
  });

  test('clearQuery restores the full list', () async {
    final ProviderContainer c = _container();
    _notifier(c).setQuery('zzzzz');
    await _settle(c);
    _notifier(c).clearQuery();
    await _settle(c);
    expect(c.read(hotelSearchControllerProvider).results,
        isA<UiSuccess<HotelSearchResult>>());
  });

  test('applyFilters and resetFilters flow through to the results', () async {
    final ProviderContainer c = _container();
    await _notifier(c).ensureLoaded();
    await _settle(c);

    _notifier(c).applyFilters(const HotelFilters(cityIds: <String>{'jeddah'}));
    await _settle(c);
    expect(_result(c).hotels.every((h) => h.cityId == 'jeddah'), isTrue);
    expect(c.read(hotelSearchControllerProvider).filters.isActive, isTrue);

    _notifier(c).resetFilters();
    await _settle(c);
    expect(c.read(hotelSearchControllerProvider).filters.isActive, isFalse);
    expect(_result(c).hotels.length, greaterThan(2));
  });

  test('setSort reorders and is remembered', () async {
    final ProviderContainer c = _container();
    await _notifier(c).ensureLoaded();
    await _settle(c);

    _notifier(c).setSort(HotelSort.priceAsc);
    await _settle(c);
    expect(c.read(hotelSearchControllerProvider).sort, HotelSort.priceAsc);

    final prices = _result(c).hotels.map((h) => h.nightlyRateFrom.amount).toList();
    for (int i = 1; i < prices.length; i++) {
      expect(prices[i] >= prices[i - 1], isTrue);
    }
  });
}
