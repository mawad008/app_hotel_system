import '../../../../core/localization/content_language_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failure.dart';
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
    this.loadingMore = false,
    this.loadMoreFailure,
  });

  final String query;
  final HotelFilters filters;
  final HotelSort sort;
  final UiState<HotelSearchResult> results;

  /// The next page is being fetched (the list shows a footer spinner).
  final bool loadingMore;

  /// The last next-page fetch failed; the list offers a retry footer and
  /// keeps the hotels already shown.
  final Failure? loadMoreFailure;

  bool get hasActiveRefinement => query.trim().isNotEmpty || filters.isActive;

  HotelSearchState copyWith({
    String? query,
    HotelFilters? filters,
    HotelSort? sort,
    UiState<HotelSearchResult>? results,
    bool? loadingMore,
    Failure? loadMoreFailure,
    bool clearLoadMoreFailure = false,
  }) {
    return HotelSearchState(
      query: query ?? this.query,
      filters: filters ?? this.filters,
      sort: sort ?? this.sort,
      results: results ?? this.results,
      loadingMore: loadingMore ?? this.loadingMore,
      loadMoreFailure: clearLoadMoreFailure
          ? null
          : (loadMoreFailure ?? this.loadMoreFailure),
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

  /// Lazy loading: fetches the next page of the current search and appends
  /// it. Called by the list as the guest nears its end; does nothing while a
  /// page is already loading, or when there are no more pages.
  Future<void> loadMore() async {
    final UiState<HotelSearchResult> current = state.results;
    if (current is! UiSuccess<HotelSearchResult> ||
        !current.data.hasMore ||
        state.loadingMore) {
      return;
    }
    final int requestId = _requestId; // a new search supersedes this page
    state = state.copyWith(loadingMore: true, clearLoadMoreFailure: true);
    try {
      final HotelSearchResult next =
          await ref.read(discoveryRepositoryProvider).searchHotels(
                query: state.query,
                filters: state.filters,
                sort: state.sort,
                page: current.data.page + 1,
              );
      if (requestId != _requestId) return;
      final UiState<HotelSearchResult> now = state.results;
      if (now is! UiSuccess<HotelSearchResult>) return;
      state = state.copyWith(
        results: UiState<HotelSearchResult>.success(now.data.append(next)),
        loadingMore: false,
      );
    } catch (error) {
      if (requestId != _requestId) return;
      state = state.copyWith(
        loadingMore: false,
        loadMoreFailure: ErrorMapper.toFailure(error),
      );
    }
  }

  Future<void> _run({bool keepShown = false}) async {
    final int requestId = ++_requestId;
    // A new search starts from page 1: any next-page load in flight is stale.
    state = state.copyWith(loadingMore: false, clearLoadMoreFailure: true);
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
