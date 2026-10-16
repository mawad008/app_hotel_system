import '../entities/availability_result.dart';
import '../entities/available_room.dart';
import '../entities/city.dart';
import '../entities/guest_party.dart';
import '../entities/hotel.dart';
import '../entities/hotel_filters.dart';
import '../entities/hotel_search_result.dart';
import '../entities/hotel_sort.dart';
import '../entities/hotel_summary.dart';
import '../entities/stay_range.dart';
import '../entities/upcoming_stay.dart';

/// The discover / search / availability contract the presentation layer depends
/// on. Which data source fulfils it (dummy vs the future Laravel API) is a DI
/// decision, exactly as in [AuthRepository] / [HealthRepository].
///
/// Every method throws a [Failure] on error (mapped by the implementation) so
/// callers only handle the user-safe type.
abstract interface class DiscoveryRepository {
  /// Curated hotels for the discover screen (`02 · Discover & Book`).
  Future<List<HotelSummary>> featuredHotels();

  /// The destinations the group operates in — for the city filter and search
  /// suggestions.
  Future<List<City>> cities();

  /// Searches the group's hotels. [query] matches hotel and city names;
  /// [filters] and [sort] are applied by the data source.
  ///
  /// One [page] (1-based) at a time; [HotelSearchResult.hasMore] says
  /// whether to ask for the next.
  Future<HotelSearchResult> searchHotels({
    String query = '',
    HotelFilters filters = HotelFilters.none,
    HotelSort sort = HotelSort.recommended,
    int page = 1,
  });

  /// The full hotel for the detail screen.
  Future<Hotel> hotel(String hotelId);

  /// Dummy availability for a stay. The mobile app never treats this as
  /// authoritative — a later phase's API replaces the source.
  Future<AvailabilityResult> availability({
    required String hotelId,
    required StayRange stay,
    required GuestParty party,
  });

  /// How many hotels the group operates. The Home screen switches to its
  /// single-hotel layout when this is 1.
  Future<int> groupHotelCount();

  /// A hotel's room types with list prices, without a stay filter — the
  /// single-hotel Home "استكشف الغرف" list.
  Future<List<AvailableRoom>> hotelRooms(String hotelId);

  /// The signed-in guest's next confirmed stay, or `null` — the Home
  /// `إقامتك القادمة` card.
  ///
  /// Superseded for real-API mode: discovery has no reservation access, so
  /// [DiscoverController] composes this itself from `ReservationRepository`
  /// (list → detail) + this repository's [hotel] instead of calling this
  /// method. Kept for the dummy source's design-only fixture; a real
  /// implementation should not be added here — see
  /// `DiscoverController._resolveUpcomingStay`.
  Future<UpcomingStay?> upcomingStay();
}
