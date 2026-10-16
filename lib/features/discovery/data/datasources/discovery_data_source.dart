import '../../domain/entities/hotel_filters.dart';
import '../../domain/entities/hotel_sort.dart';
import '../models/discovery_models.dart';

/// The discovery data contract. Dummy + API implementations, selected by DI
/// (`AppConfig.useDummyData`) exactly like `AuthDataSource` / `HealthDataSource`.
///
/// Retrieval, filtering and sorting live here, not in widgets or controllers
/// (phase brief §4). Methods return DTO models; the repository maps them to
/// domain entities.
abstract interface class DiscoveryDataSource {
  Future<List<CityModel>> fetchCities();

  Future<List<HotelSummaryModel>> fetchFeaturedHotels();

  /// One page (1-based [page]) of matching hotels.
  Future<HotelSearchResultModel> searchHotels({
    required String query,
    required HotelFilters filters,
    required HotelSort sort,
    int page = 1,
  });

  Future<HotelModel> fetchHotel(String hotelId);

  Future<AvailabilityResultModel> fetchAvailability({
    required String hotelId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int adults,
    required int children,
  });

  /// How many hotels the group operates — the Home screen switches to its
  /// single-hotel layout when this is 1.
  Future<int> fetchGroupHotelCount();

  /// A hotel's room types with their list ("from") prices and current
  /// sold-out flags, **without** a stay filter — for the single-hotel Home
  /// "استكشف الغرف" list.
  Future<List<AvailableRoomModel>> fetchHotelRooms(String hotelId);

  /// The signed-in guest's next confirmed stay, or `null` when there is none.
  /// The Home `إقامتك القادمة` card renders it.
  Future<UpcomingStayModel?> fetchUpcomingStay();
}
