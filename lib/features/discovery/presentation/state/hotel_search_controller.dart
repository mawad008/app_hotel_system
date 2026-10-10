import '../../../../core/localization/content_language_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/presentation/ui_state.dart';
import '../../domain/entities/hotel_filters.dart';
import '../../domain/entities/hotel_search_result.dart';
import '../../domain/entities/hotel_sort.dart';
import 'discovery_providers.dart';

/// The hotel-search screen state (`15 · Search, filters & sort`): the current
/// query, the composed filters, the sort order and the results as a [UiState].
///
/// [results] is `empty` when the query/filters match nothing, `failure` on a
/// data error, and `initial` only before the first load.
@immutable
class HotelSearchState {
  const HotelSearchState({
    this.query = '',
    this.filters = HotelFilters.none,
    this.sort = HotelSort.recommended,
    this.results = const UiInitial<HotelSearchResult>(),
  });

  final String query;
  final HotelFilters filters;
  final HotelSort sort;
  final UiState<HotelSearchResult> results;

  bool get hasActiveRefinement => query.trim().isNotEmpty || filters.isActive;

  HotelSearchState copyWith({
    String? query,
    HotelFilters? filters,
    HotelSort? sort,
    UiState<HotelSearchResult>? results,
  }) {
    return HotelSearchState(
      query: query ?? this.query,
      filters: filters ?? this.filters,
      sort: sort ?? this.sort,
      results: results ?? this.results,
    );
  }
}

class HotelSearchController extends Notifier<HotelSearchState> {
  int _requestId = 0;

  @override
  HotelSearchState build() {
    // Re-run the current search (keeping query/filters/sort) after a
    // language switch so result names come back in the new language.
    ref.listen<String>(contentLanguageProvider, (String? previous, String next) {
      if (previous != next && state.results is! UiInitial<HotelSearchResult>) _run();
    });
    return const HotelSearchState();
  }

  /// Loads the "all hotels" list if nothing has been loaded yet. Called by the
  /// search page on first open.
  Future<void> ensureLoaded() {
    if (state.results is! UiInitial<HotelSearchResult>) return Future<void>.value();
    return _run();
  }

  /// Called on every change to the query field.
  void setQuery(String query) {
    if (query == state.query) return;
    state = state.copyWith(query: query);
    _run();
  }

  void clearQuery() {
    if (state.query.isEmpty) return;
    state = state.copyWith(query: '');
    _run();
  }

  void applyFilters(HotelFilters filters) {
    if (filters == state.filters) return;
    state = state.copyWith(filters: filters);
    _run();
  }

  void resetFilters() {
    if (!state.filters.isActive) return;
    state = state.copyWith(filters: HotelFilters.none);
    _run();
  }

  void setSort(HotelSort sort) {
    if (sort == state.sort) return;
    state = state.copyWith(sort: sort);
    _run();
  }

  Future<void> retry() => _run();

  /// Pull-to-refresh: re-runs the current search while the shown results stay
  /// on screen. On failure they are kept and the error is rethrown.
  Future<void> refresh() => _run(keepShown: true);

  Future<void> _run({bool keepShown = false}) async {
    final int requestId = ++_requestId;
    final bool showing = keepShown &&
        (state.results is UiSuccess<HotelSearchResult> ||
            state.results is UiEmpty<HotelSearchResult>);
    if (!showing) {
      state = state.copyWith(results: const UiLoading<HotelSearchResult>());
    }

    try {
      final HotelSearchResult result =
          await ref.read(discoveryRepositoryProvider).searchHotels(
                query: state.query,
                filters: state.filters,
                sort: state.sort,
              );
      if (requestId != _requestId) return; // a newer query superseded this one
      state = state.copyWith(
        results: result.isEmpty
            ? const UiEmpty<HotelSearchResult>()
            : UiState<HotelSearchResult>.success(result),
      );
    } catch (error) {
      if (requestId != _requestId) return;
      if (showing) rethrow;
      state = state.copyWith(
        results: UiState<HotelSearchResult>.failure(ErrorMapper.toFailure(error)),
      );
    }
  }
}

final hotelSearchControllerProvider =
    NotifierProvider<HotelSearchController, HotelSearchState>(
  HotelSearchController.new,
);
