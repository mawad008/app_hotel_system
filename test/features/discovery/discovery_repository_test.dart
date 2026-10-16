import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/errors/app_exception.dart';
import 'package:hotel_guest_app/core/errors/failure.dart';
import 'package:hotel_guest_app/features/discovery/data/datasources/discovery_data_source.dart';
import 'package:hotel_guest_app/features/discovery/data/datasources/dummy_discovery_data_source.dart';
import 'package:hotel_guest_app/features/discovery/data/models/discovery_models.dart';
import 'package:hotel_guest_app/features/discovery/data/repositories/discovery_repository_impl.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/guest_party.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/hotel_filters.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/hotel_sort.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/stay_range.dart';

class _ThrowingDataSource implements DiscoveryDataSource {
  const _ThrowingDataSource(this.error);
  final Object error;

  @override
  Future<AvailabilityResultModel> fetchAvailability({
    required String hotelId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int adults,
    required int children,
  }) async =>
      throw error;

  @override
  Future<List<CityModel>> fetchCities() async => throw error;

  @override
  Future<List<HotelSummaryModel>> fetchFeaturedHotels() async => throw error;

  @override
  Future<HotelModel> fetchHotel(String hotelId) async => throw error;

  @override
  Future<HotelSearchResultModel> searchHotels({
    required String query,
    required HotelFilters filters,
    required HotelSort sort,
    int page = 1,
  }) async =>
      throw error;

  @override
  Future<int> fetchGroupHotelCount() async => throw error;

  @override
  Future<List<AvailableRoomModel>> fetchHotelRooms(String hotelId) async =>
      throw error;

  @override
  Future<UpcomingStayModel?> fetchUpcomingStay() async => throw error;
}

void main() {
  final DiscoveryRepositoryImpl repo =
      DiscoveryRepositoryImpl(const DummyDiscoveryDataSource());

  test('maps dummy models to domain entities', () async {
    final hotels = await repo.featuredHotels();
    expect(hotels, isNotEmpty);
    expect(hotels.first.name.resolve(const Locale('en')), isNotEmpty);

    final hotel = await repo.hotel('oasis');
    expect(hotel.id, 'oasis');

    final result = await repo.searchHotels(
      query: 'الواحة',
      filters: HotelFilters.none,
      sort: HotelSort.recommended,
    );
    expect(result.hotels.single.id, 'oasis');

    final availability = await repo.availability(
      hotelId: 'oasis',
      stay: StayRange(checkIn: DateTime(2026, 9, 6), checkOut: DateTime(2026, 9, 8)),
      party: GuestParty.initial,
    );
    expect(availability.hotelId, 'oasis');
    expect(availability.rooms, isNotEmpty);
  });

  test('a NotFound from the data source becomes a notFound Failure', () async {
    await expectLater(
      repo.hotel('nope'),
      throwsA(
        isA<Failure>().having((f) => f.kind, 'kind', FailureKind.notFound),
      ),
    );
  });

  test('an arbitrary error is mapped to a Failure, not leaked raw', () async {
    final failing = DiscoveryRepositoryImpl(
      const _ThrowingDataSource(FormatException('boom')),
    );
    await expectLater(failing.cities(), throwsA(isA<Failure>()));
  });

  test('a NotImplemented stub becomes a notImplemented Failure', () async {
    final failing = DiscoveryRepositoryImpl(
      const _ThrowingDataSource(NotImplementedInPhaseException('x')),
    );
    await expectLater(
      failing.featuredHotels(),
      throwsA(isA<Failure>()
          .having((f) => f.kind, 'kind', FailureKind.notImplemented)),
    );
  });
}
