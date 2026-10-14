import '../../../../core/localization/content_language_provider.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/presentation/ui_state.dart';
import '../../domain/entities/availability_request.dart';
import '../../domain/entities/availability_result.dart';
import '../../domain/entities/available_room.dart';
import '../../domain/entities/room_sort.dart';
import 'discovery_providers.dart';

/// State for the available-rooms list (`16 · Stay dates & available rooms`).
///
/// [result] follows the standard [UiState] set: `initial` before the first
/// lookup, `loading` while fetching, `empty` when no room type can host the
/// party (the no-results screen), `success` otherwise — even when every room is
/// sold out, so the list can still render them greyed — and `failure` on error.
///
/// [request] is the exact criteria [result] was produced for. A `success` /
/// `empty` result whose [request] no longer matches the guest's current dates,
/// party or hotel is stale and must be re-fetched before it is trusted.
@immutable
class RoomAvailabilityState {
  const RoomAvailabilityState({
    this.sort = RoomSort.priceAsc,
    this.result = const UiInitial<AvailabilityResult>(),
    this.request,
  });

  final RoomSort sort;
  final UiState<AvailabilityResult> result;
  final AvailabilityRequest? request;

  /// `true` when [result] holds data (success or empty) that was produced for
  /// [request].
  bool isFreshFor(AvailabilityRequest current) =>
      request == current &&
      (result is UiSuccess<AvailabilityResult> ||
          result is UiEmpty<AvailabilityResult>);

  RoomAvailabilityState copyWith({
    RoomSort? sort,
    UiState<AvailabilityResult>? result,
    AvailabilityRequest? request,
  }) {
    return RoomAvailabilityState(
      sort: sort ?? this.sort,
      result: result ?? this.result,
      request: request ?? this.request,
    );
  }
}

/// Availability is a standalone stateful operation: `StayRange + GuestParty +
/// Hotel → request → loading → success / empty / error`. The controller never
/// assumes a previous result stays valid — every [load] is tagged with its
/// [AvailabilityRequest], a slower response cannot overwrite a newer one, and
/// an identical in-flight/fresh request is a no-op.
class RoomAvailabilityController extends Notifier<RoomAvailabilityState> {
  int _requestId = 0;
  AvailabilityRequest? _inFlight;

  @override
  RoomAvailabilityState build() {
    // Re-fetch the last request after a language switch so room names and
    // specs come back in the new language (selection state is untouched).
    ref.listen<String>(contentLanguageProvider, (
      String? previous,
      String next,
    ) {
      if (previous != next) retry();
    });
    return const RoomAvailabilityState();
  }

  /// Fetches availability for [request]. Skips the fetch when the current
  /// result is already fresh for the same request and [force] is `false`.
  Future<void> load(AvailabilityRequest request, {bool force = false}) async {
    if (!force && (state.isFreshFor(request) || _inFlight == request)) return;

    final int requestId = ++_requestId;
    _inFlight = request;
    state = state.copyWith(result: const UiLoading<AvailabilityResult>());

    try {
      final AvailabilityResult result = await ref
          .read(discoveryRepositoryProvider)
          .availability(
            hotelId: request.hotelId,
            stay: request.stay,
            party: request.party,
          );
      if (requestId != _requestId) return; // superseded by a newer request
      _inFlight = null;
      state = RoomAvailabilityState(
        sort: state.sort,
        result: _present(result, state.sort),
        request: request,
      );
    } catch (error) {
      if (requestId != _requestId) return;
      _inFlight = null;
      state = RoomAvailabilityState(
        sort: state.sort,
        result: UiState<AvailabilityResult>.failure(
          ErrorMapper.toFailure(error),
        ),
        request: request,
      );
    }
  }

  /// Pull-to-refresh: refetches the last request while the current rooms stay
  /// on screen. On failure the shown result is kept and the error rethrown.
  Future<void> refresh() async {
    final AvailabilityRequest? last = state.request;
    if (last == null) return;
    if (state.result is! UiSuccess<AvailabilityResult> &&
        state.result is! UiEmpty<AvailabilityResult>) {
      return load(last, force: true);
    }
    final int requestId = ++_requestId;
    _inFlight = last;
    try {
      final AvailabilityResult result = await ref
          .read(discoveryRepositoryProvider)
          .availability(
            hotelId: last.hotelId,
            stay: last.stay,
            party: last.party,
          );
      if (requestId != _requestId) return;
      state = RoomAvailabilityState(
        sort: state.sort,
        result: _present(result, state.sort),
        request: last,
      );
    } finally {
      if (requestId == _requestId) _inFlight = null;
    }
  }

  /// Re-runs the last request (the retry action on the error/empty state).
  Future<void> retry() async {
    final AvailabilityRequest? last = state.request;
    if (last != null) await load(last, force: true);
  }

  void setSort(RoomSort sort) {
    if (sort == state.sort) return;
    final UiState<AvailabilityResult> current = state.result;
    if (current is UiSuccess<AvailabilityResult>) {
      state = state.copyWith(sort: sort, result: _present(current.data, sort));
    } else {
      state = state.copyWith(sort: sort);
    }
  }

  void reset() {
    _inFlight = null;
    state = const RoomAvailabilityState();
  }

  UiState<AvailabilityResult> _present(
    AvailabilityResult result,
    RoomSort sort,
  ) {
    if (result.rooms.isEmpty) return const UiEmpty<AvailabilityResult>();
    return UiState<AvailabilityResult>.success(
      AvailabilityResult(
        hotelId: result.hotelId,
        stay: result.stay,
        party: result.party,
        rooms: _sorted(result.rooms, sort),
      ),
    );
  }

  static List<AvailableRoom> _sorted(List<AvailableRoom> rooms, RoomSort sort) {
    final List<AvailableRoom> copy = List<AvailableRoom>.of(rooms);
    copy.sort((AvailableRoom a, AvailableRoom b) {
      // Bookable rooms first, then by price in the chosen direction.
      if (a.isAvailable != b.isAvailable) return a.isAvailable ? -1 : 1;
      final int byPrice = a.nightlyRate.amount.compareTo(b.nightlyRate.amount);
      return sort == RoomSort.priceAsc ? byPrice : -byPrice;
    });
    return copy;
  }
}

final roomAvailabilityControllerProvider =
    NotifierProvider<RoomAvailabilityController, RoomAvailabilityState>(
      RoomAvailabilityController.new,
    );
