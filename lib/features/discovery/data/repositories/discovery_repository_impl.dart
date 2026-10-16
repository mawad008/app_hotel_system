import '../../../../core/errors/error_mapper.dart';
import '../../domain/entities/availability_result.dart';
import '../../domain/entities/available_room.dart';
import '../../domain/entities/city.dart';
import '../../domain/entities/guest_party.dart';
import '../../domain/entities/hotel.dart';
import '../../domain/entities/hotel_filters.dart';
import '../../domain/entities/hotel_search_result.dart';
import '../../domain/entities/hotel_sort.dart';
import '../../domain/entities/hotel_summary.dart';
import '../../domain/entities/stay_range.dart';
import '../../domain/entities/upcoming_stay.dart';
import '../../domain/repositories/discovery_repository.dart';
import '../datasources/discovery_data_source.dart';

/// Coordinates the discovery data source and maps DTO models to domain entities.
///
/// Which [DiscoveryDataSource] it holds (dummy vs API) is a DI decision, not
/// made here (feature_guide.md Step 5). Every data-layer error is mapped to a
/// `Failure` via [ErrorMapper] so the presentation layer only handles the
/// user-safe type.
class DiscoveryRepositoryImpl implements DiscoveryRepository {
  DiscoveryRepositoryImpl(this._dataSource);

  final DiscoveryDataSource _dataSource;

  @override
  Future<List<City>> cities() => _guard(() async {
        final result = await _dataSource.fetchCities();
        return result.map((c) => c.toEntity()).toList(growable: false);
      });

  @override
  Future<List<HotelSummary>> featuredHotels() => _guard(() async {
        final result = await _dataSource.fetchFeaturedHotels();
        return result.map((h) => h.toEntity()).toList(growable: false);
      });

  @override
  Future<HotelSearchResult> searchHotels({
    String query = '',
    HotelFilters filters = HotelFilters.none,
    HotelSort sort = HotelSort.recommended,
    int page = 1,
  }) =>
      _guard(() async {
        final result = await _dataSource.searchHotels(
          query: query,
          filters: filters,
          sort: sort,
          page: page,
        );
        return result.toEntity();
      });

  @override
  Future<Hotel> hotel(String hotelId) =>
      _guard(() async => (await _dataSource.fetchHotel(hotelId)).toEntity());

  @override
  Future<AvailabilityResult> availability({
    required String hotelId,
    required StayRange stay,
    required GuestParty party,
  }) =>
      _guard(() async {
        final result = await _dataSource.fetchAvailability(
          hotelId: hotelId,
          checkIn: stay.checkIn,
          checkOut: stay.checkOut,
          adults: party.adults,
          children: party.children,
        );
        return result.toEntity();
      });

  @override
  Future<int> groupHotelCount() =>
      _guard(() => _dataSource.fetchGroupHotelCount());

  @override
  Future<List<AvailableRoom>> hotelRooms(String hotelId) => _guard(() async {
        final result = await _dataSource.fetchHotelRooms(hotelId);
        return result.map((m) => m.toEntity()).toList(growable: false);
      });

  @override
  Future<UpcomingStay?> upcomingStay() => _guard(() async {
        final result = await _dataSource.fetchUpcomingStay();
        return result?.toEntity();
      });

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (error) {
      throw ErrorMapper.toFailure(error);
    }
  }
}
