import '../../../../core/localization/content_language_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_providers.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/presentation/ui_state.dart';
import '../../../authentication/presentation/state/auth_controller.dart';
import '../../../authentication/presentation/state/auth_state.dart';
import '../../../reservation/domain/entities/reservation.dart';
import '../../../reservation/domain/entities/reservation_status.dart';
import '../../../reservation/presentation/state/reservation_providers.dart';
import '../../domain/entities/available_room.dart';
import '../../domain/entities/hotel_summary.dart';
import '../../domain/entities/money.dart';
import '../../domain/entities/upcoming_stay.dart';
import '../../domain/repositories/discovery_repository.dart';
import 'discovery_providers.dart';

/// Reservation states still "ahead of or during" the stay — the candidate
/// pool for the Home `إقامتك القادمة` card. Terminal states (checked out,
/// invoiced, cancelled) are excluded, mirroring the backend state machine
/// (mobile/docs/architecture.md §6 — mirror Laravel, never invent a state).
const Set<ReservationStatus> _upcomingStayStatuses = <ReservationStatus>{
  ReservationStatus.pending,
  ReservationStatus.depositHeld,
  ReservationStatus.verified,
  ReservationStatus.checkedIn,
  ReservationStatus.inStay,
};

/// Everything the Home screen (`HOME_Default` / `HOME_if One hotel`) needs in one
/// value: the greeting name, the guest's upcoming stay, and either the group
/// hotel grid or — when the group runs a single hotel — that hotel's rooms.
@immutable
class DiscoverView {
  const DiscoverView({
    required this.greetingName,
    required this.featuredHotels,
    required this.upcomingStay,
    required this.isSingleHotel,
    required this.soleHotelRooms,
  });

  /// First name of the signed-in guest, or `null` (generic greeting).
  final String? greetingName;
  final List<HotelSummary> featuredHotels;

  /// The signed-in guest's next confirmed stay — `null` for a guest or when
  /// there is none.
  final UpcomingStay? upcomingStay;

  /// `true` when the group operates one hotel: Home shows `استكشف الغرف` instead
  /// of the hotel grid.
  final bool isSingleHotel;
  final List<AvailableRoom> soleHotelRooms;

  HotelSummary? get soleHotel =>
      isSingleHotel && featuredHotels.isNotEmpty ? featuredHotels.first : null;

  @override
  bool operator ==(Object other) =>
      other is DiscoverView &&
      other.greetingName == greetingName &&
      listEquals(other.featuredHotels, featuredHotels) &&
      other.upcomingStay == upcomingStay &&
      other.isSingleHotel == isSingleHotel &&
      listEquals(other.soleHotelRooms, soleHotelRooms);

  @override
  int get hashCode => Object.hash(
        greetingName,
        Object.hashAll(featuredHotels),
        upcomingStay,
        isSingleHotel,
        Object.hashAll(soleHotelRooms),
      );
}

/// Loads the Home screen. Read as a `UiState` via [discoverUiState].
class DiscoverController extends AutoDisposeAsyncNotifier<DiscoverView> {
  @override
  Future<DiscoverView> build() async {
    // Watch auth so the greeting + upcoming stay fill in once restore resolves.
    final AuthState auth = ref.watch(authControllerProvider);
    // Hotel names/taglines come back in the request language — reload on a switch.
    ref.watch(contentLanguageProvider);
    final repo = ref.watch(discoveryRepositoryProvider);

    final List<HotelSummary> hotels = await repo.featuredHotels();
    final int groupCount = await repo.groupHotelCount();
    final bool single = groupCount <= 1 && hotels.isNotEmpty;

    return DiscoverView(
      greetingName: _greetingName(auth),
      featuredHotels: hotels,
      isSingleHotel: single,
      soleHotelRooms:
          single ? await repo.hotelRooms(hotels.first.id) : const <AvailableRoom>[],
      upcomingStay: _isSignedIn(auth) ? await _upcomingStayOrNull(ref, repo) : null,
    );
  }

  /// The upcoming-stay card is extra: when the guest's reservations can't be
  /// read (offline, a server hiccup) Home still shows the hotels — which may
  /// come from the offline copy — and the card returns on the next refresh.
  Future<UpcomingStay?> _upcomingStayOrNull(
    Ref ref,
    DiscoveryRepository repo,
  ) async {
    try {
      return await _resolveUpcomingStay(ref, repo);
    } on Failure {
      return null;
    }
  }

  /// The guest's next confirmed stay for the Home `إقامتك القادمة` card.
  ///
  /// Dummy mode keeps its existing design-only fixture
  /// (`DiscoveryRepository.upcomingStay`) — offline/demo mode is unaffected.
  /// Real-API mode composes it itself, since discovery has no reservation
  /// access by design (see the doc-comment on `DiscoveryRepository
  /// .upcomingStay`): read the guest's own reservations, pick the soonest one
  /// still ahead of/during its stay, then fetch its full detail (for the real
  /// hotel/room names) and the hotel's own city name. `null` when there is
  /// none — the Home card section simply doesn't render, never a fabricated
  /// stand-in.
  Future<UpcomingStay?> _resolveUpcomingStay(Ref ref, DiscoveryRepository repo) async {
    if (ref.watch(appConfigProvider).useDummyData) {
      return repo.upcomingStay();
    }

    final List<Reservation> reservations =
        await ref.watch(reservationRepositoryProvider).list();
    final List<Reservation> candidates = reservations
        .where((Reservation r) => _upcomingStayStatuses.contains(r.status))
        .toList()
      ..sort((Reservation a, Reservation b) =>
          a.stay.checkIn.compareTo(b.stay.checkIn));
    if (candidates.isEmpty) return null;

    final Reservation full =
        await ref.watch(reservationRepositoryProvider).getById(candidates.first.id);
    final hotel = await ref.watch(discoveryRepositoryProvider).hotel(full.hotelId);

    final int nights = full.nights > 0 ? full.nights : 1;
    return UpcomingStay(
      reservationId: full.id,
      roomName: full.roomName,
      hotelName: full.hotelName,
      cityName: hotel.summary.cityName,
      // The booked nightly rate; otherwise the stay total per night, kept to
      // the halala (never rounded to whole riyals).
      nightlyRate: full.nightlyRate ??
          Money(
            amount: (full.priceSnapshot.amount * 100 / nights).round() / 100,
            currency: full.priceSnapshot.currency,
          ),
      isAvailable: !full.status.isCancelled,
      imageUrl: hotel.summary.coverUrl,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue<DiscoverView>.loading();
    state = await AsyncValue.guard(build);
  }

  bool _isSignedIn(AuthState auth) => auth.map(
        unknown: () => false,
        unauthenticated: () => false,
        awaitingProfile: (_) => true,
        authenticated: (_) => true,
        sessionExpired: () => false,
      );

  String? _greetingName(AuthState auth) {
    final String? fullName = auth.map(
      unknown: () => null,
      unauthenticated: () => null,
      awaitingProfile: (session) => session.profile.fullName,
      authenticated: (session) => session.profile.fullName,
      sessionExpired: () => null,
    );
    final String? trimmed = fullName?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed.split(RegExp(r'\s+')).first;
  }
}

final discoverControllerProvider =
    AutoDisposeAsyncNotifierProvider<DiscoverController, DiscoverView>(
  DiscoverController.new,
);

/// Adapts the Riverpod [AsyncValue] to the app's [UiState] vocabulary.
UiState<DiscoverView> discoverUiState(AsyncValue<DiscoverView> value) {
  return value.map(
    data: (AsyncData<DiscoverView> d) => d.value.featuredHotels.isEmpty
        ? const UiEmpty<DiscoverView>()
        : UiState<DiscoverView>.success(d.value),
    loading: (_) => const UiLoading<DiscoverView>(),
    error: (AsyncError<DiscoverView> e) =>
        UiState<DiscoverView>.failure(ErrorMapper.toFailure(e.error)),
  );
}
