import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/app/router/app_router.dart';
import 'package:hotel_guest_app/app/router/app_routes.dart';
import 'package:hotel_guest_app/core/localization/generated/app_localizations.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/hotel.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/hotel_facility.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/hotel_summary.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/localized_text.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/money.dart';
import 'package:hotel_guest_app/features/discovery/presentation/state/guest_party_controller.dart';
import 'package:hotel_guest_app/features/discovery/presentation/state/hotel_detail_provider.dart';
import 'package:hotel_guest_app/features/stay_services/domain/entities/hotel_service.dart';
import 'package:hotel_guest_app/features/stay_services/domain/entities/service_order.dart';
import 'package:hotel_guest_app/features/stay_services/domain/repositories/stay_services_repository.dart';
import 'package:hotel_guest_app/features/stay_services/presentation/state/stay_services_providers.dart';

import '../../support/pump_app.dart';

const String _hotelId = 'info-row-test-hotel';

Hotel _hotelWith({
  LocalizedText? country,
  List<HotelFacility> facilities = const <HotelFacility>[],
  int? starRating,
  int roomTypeCount = 0,
}) =>
    Hotel(
      summary: HotelSummary(
        id: _hotelId,
        name: const LocalizedText(ar: 'فندق تجريبي', en: 'Test Hotel'),
        cityId: 'Riyadh',
        cityName: const LocalizedText(ar: 'الرياض', en: 'Riyadh'),
        tagline: const LocalizedText(ar: '', en: ''),
        rating: null,
        reviewCount: 999, // deliberately distinct from any guest count
        nightlyRateFrom: const Money(amount: 300),
        isAvailable: true,
        starRating: starRating,
      ),
      description: const LocalizedText(ar: '', en: ''),
      facilities: facilities,
      roomTypeCount: roomTypeCount,
      photoCount: 0,
      country: country,
    );

class _FakeStayServicesRepository implements StayServicesRepository {
  _FakeStayServicesRepository(this.services);
  final List<HotelService> services;

  @override
  Future<ServiceCatalogue> catalogue(String hotelId) async =>
      ServiceCatalogue(categories: const <ServiceCategory>[], services: services);

  @override
  Future<List<ServiceOrder>> ordersFor(String reservationId) async =>
      <ServiceOrder>[];

  @override
  Future<ServiceOrder> orderById(String reservationId, String orderId) {
    throw UnimplementedError('not used in this test');
  }

  @override
  Future<ServiceOrder> requestService(CreateServiceRequest request) {
    throw UnimplementedError('not used in this test');
  }

  @override
  Future<ServiceOrder> cancelOrder(String reservationId, String orderId) {
    throw UnimplementedError('not used in this test');
  }
}

Future<ProviderContainer> _pumpHotelDetail(
  WidgetTester tester,
  Hotel hotel, {
  List<Override> extraOverrides = const <Override>[],
}) async {
  final ProviderContainer container = await pumpApp(
    tester,
    locale: const Locale('en'),
    extraOverrides: <Override>[
      hotelDetailProvider(_hotelId).overrideWith((Ref ref) async => hotel),
      ...extraOverrides,
    ],
  );
  container.read(appRouterProvider).goNamed(
        AppRoutes.hotelDetailName,
        pathParameters: <String, String>{'hotelId': _hotelId},
      );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('shows the country and the current search-state guest count',
      (WidgetTester tester) async {
    final AppLocalizations en = await AppLocalizations.delegate.load(const Locale('en'));
    await _pumpHotelDetail(
      tester,
      _hotelWith(country: const LocalizedText(ar: 'السعودية', en: 'Saudi Arabia')),
    );

    expect(find.text('Saudi Arabia'), findsOneWidget);
    // GuestParty.initial is 2 adults + 0 children — never the hotel's
    // `reviews_count` (999) and never a hardcoded/room-capacity figure.
    expect(find.text(en.hotelGuestCount(2)), findsOneWidget);
    expect(find.text(en.hotelGuestCount(999)), findsNothing);

    // The replaced area/bed-type content is gone.
    expect(find.textContaining('m²'), findsNothing);
  });

  testWidgets('omits the country chip when the hotel has none on file',
      (WidgetTester tester) async {
    await _pumpHotelDetail(tester, _hotelWith(country: null));

    expect(find.text('Saudi Arabia'), findsNothing);
  });

  testWidgets('reflects a guest-party change made elsewhere (shared search state)',
      (WidgetTester tester) async {
    final AppLocalizations en = await AppLocalizations.delegate.load(const Locale('en'));
    final ProviderContainer container = await _pumpHotelDetail(
      tester,
      _hotelWith(country: null),
    );

    container.read(guestPartyControllerProvider.notifier)
      ..setAdults(3)
      ..setChildren(1);
    await tester.pumpAndSettle();

    expect(find.text(en.hotelGuestCount(4)), findsOneWidget);
  });

  testWidgets('shows the real, open-catalog facilities under "What this hotel offers"',
      (WidgetTester tester) async {
    final AppLocalizations en = await AppLocalizations.delegate.load(const Locale('en'));
    await _pumpHotelDetail(
      tester,
      _hotelWith(
        facilities: const <HotelFacility>[
          HotelFacility(key: 'breakfast', label: LocalizedText(ar: 'إفطار', en: 'Breakfast')),
          // A facility key the app has no built-in knowledge of — proves
          // the label is rendered as-is from the backend, never dropped by
          // a hardcoded key->label map.
          HotelFacility(key: 'private_beach', label: LocalizedText(ar: 'شاطئ خاص', en: 'Private beach')),
        ],
      ),
    );

    expect(find.text(en.hotelDetailAmenities), findsOneWidget);
    expect(find.text('Breakfast'), findsOneWidget);
    expect(find.text('Private beach'), findsOneWidget);
  });

  testWidgets('omits the amenities section entirely when the hotel has none on file',
      (WidgetTester tester) async {
    final AppLocalizations en = await AppLocalizations.delegate.load(const Locale('en'));
    await _pumpHotelDetail(tester, _hotelWith());

    expect(find.text(en.hotelDetailAmenities), findsNothing);
  });

  testWidgets('shows the real star classification, distinct from the guest rating',
      (WidgetTester tester) async {
    final AppLocalizations en = await AppLocalizations.delegate.load(const Locale('en'));
    await _pumpHotelDetail(tester, _hotelWith(starRating: 4));

    expect(find.text(en.hotelDetailStarRating(4)), findsOneWidget);
  });

  testWidgets('omits the star badge when the hotel has none on file',
      (WidgetTester tester) async {
    final AppLocalizations en = await AppLocalizations.delegate.load(const Locale('en'));
    await _pumpHotelDetail(tester, _hotelWith());

    expect(find.text(en.hotelDetailStarRating(4)), findsNothing);
  });

  testWidgets('shows the real room-type count, never a hardcoded figure',
      (WidgetTester tester) async {
    final AppLocalizations en = await AppLocalizations.delegate.load(const Locale('en'));
    await _pumpHotelDetail(tester, _hotelWith(roomTypeCount: 6));

    expect(find.text(en.hotelRoomTypeCount(6)), findsOneWidget);
  });

  testWidgets('omits the rooms chip when the hotel has no room types on file',
      (WidgetTester tester) async {
    await _pumpHotelDetail(tester, _hotelWith());

    expect(find.textContaining('room type'), findsNothing);
  });

  testWidgets('never shows a hotel services section, even when the hotel has active services',
      (WidgetTester tester) async {
    await _pumpHotelDetail(
      tester,
      _hotelWith(),
      extraOverrides: <Override>[
        stayServicesRepositoryProvider.overrideWithValue(
          _FakeStayServicesRepository(<HotelService>[
            const HotelService(
              id: 'svc-1',
              name: LocalizedText(ar: 'خدمة الغرف', en: 'Room Service'),
              description: LocalizedText(ar: '', en: ''),
              price: Money(amount: 40),
              isActive: true,
              rating: 4.8,
              reviewsCount: 125,
            ),
          ]),
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('Hotel services'), findsNothing);
    expect(find.text('Room Service'), findsNothing);
  });
}
