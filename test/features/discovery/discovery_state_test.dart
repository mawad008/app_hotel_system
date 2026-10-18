import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/di/core_providers.dart';
import 'package:hotel_guest_app/core/presentation/ui_state.dart';
import 'package:hotel_guest_app/core/time/clock.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/availability_request.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/availability_result.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/guest_party.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/localized_text.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/money.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/room_selection.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/room_sort.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/room_type_summary.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/stay_range.dart';
import 'package:hotel_guest_app/features/discovery/domain/validators/stay_dates_validator.dart';
import 'package:hotel_guest_app/features/discovery/presentation/state/guest_party_controller.dart';
import 'package:hotel_guest_app/features/discovery/presentation/state/room_availability_controller.dart';
import 'package:hotel_guest_app/features/discovery/presentation/state/room_selection_controller.dart';
import 'package:hotel_guest_app/features/discovery/presentation/state/stay_dates_controller.dart';

import '../../support/test_config.dart';

final DateTime _today = DateTime(2026, 9, 1);

ProviderContainer _container() {
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      appConfigProvider.overrideWithValue(testConfig),
      clockProvider.overrideWithValue(() => _today),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

AvailabilityRequest _request({
  String hotelId = 'oasis',
  GuestParty? party,
}) =>
    AvailabilityRequest(
      hotelId: hotelId,
      stay: StayRange(checkIn: DateTime(2026, 9, 6), checkOut: DateTime(2026, 9, 8)),
      party: party ?? GuestParty.initial,
    );

void main() {
  final DateTime today = DateTime(2026, 9, 1);

  group('StayDatesController', () {
    test('first tap sets check-in, second sets check-out', () {
      final ProviderContainer c = _container();
      final controller = c.read(stayDatesControllerProvider.notifier);

      controller.selectDay(DateTime(2026, 9, 6));
      expect(c.read(stayDatesControllerProvider).checkIn, DateTime(2026, 9, 6));
      expect(c.read(stayDatesControllerProvider).checkOut, isNull);

      controller.selectDay(DateTime(2026, 9, 8));
      final draft = c.read(stayDatesControllerProvider);
      expect(draft.checkOut, DateTime(2026, 9, 8));
      expect(draft.rangeAgainst(today)!.nights, 2);
    });

    test('a second tap before check-in restarts the selection', () {
      final ProviderContainer c = _container();
      final controller = c.read(stayDatesControllerProvider.notifier);
      controller.selectDay(DateTime(2026, 9, 8));
      controller.selectDay(DateTime(2026, 9, 6));
      expect(c.read(stayDatesControllerProvider).checkIn, DateTime(2026, 9, 6));
      expect(c.read(stayDatesControllerProvider).checkOut, isNull);
    });

    test('a third tap starts a new range', () {
      final ProviderContainer c = _container();
      final controller = c.read(stayDatesControllerProvider.notifier);
      controller.selectDay(DateTime(2026, 9, 6));
      controller.selectDay(DateTime(2026, 9, 8));
      controller.selectDay(DateTime(2026, 9, 20));
      final draft = c.read(stayDatesControllerProvider);
      expect(draft.checkIn, DateTime(2026, 9, 20));
      expect(draft.checkOut, isNull);
    });

    test('clear empties the draft', () {
      final ProviderContainer c = _container();
      final controller = c.read(stayDatesControllerProvider.notifier);
      controller.selectDay(DateTime(2026, 9, 6));
      controller.clear();
      expect(c.read(stayDatesControllerProvider).isEmpty, isTrue);
    });

    test('an incomplete draft reports the incomplete error', () {
      final ProviderContainer c = _container();
      c.read(stayDatesControllerProvider.notifier).selectDay(DateTime(2026, 9, 6));
      expect(
        c.read(stayDatesControllerProvider).errorAgainst(today),
        StayDatesError.incomplete,
      );
      expect(c.read(stayDatesControllerProvider).rangeAgainst(today), isNull);
    });
  });

  group('GuestPartyController', () {
    test('increments and decrements within bounds', () {
      final ProviderContainer c = _container();
      final controller = c.read(guestPartyControllerProvider.notifier);

      controller.incrementAdults();
      expect(c.read(guestPartyControllerProvider).adults, 3);

      for (int i = 0; i < 10; i++) {
        controller.decrementAdults();
      }
      expect(c.read(guestPartyControllerProvider).adults, GuestParty.minAdults);

      controller.incrementChildren();
      expect(c.read(guestPartyControllerProvider).children, 1);

      controller.reset();
      expect(c.read(guestPartyControllerProvider), GuestParty.initial);
    });
  });

  group('RoomAvailabilityController', () {
    test('initial state is UiInitial with no request', () {
      final ProviderContainer c = _container();
      final state = c.read(roomAvailabilityControllerProvider);
      expect(state.result, isA<UiInitial<AvailabilityResult>>());
      expect(state.request, isNull);
    });

    test('loads a success result sorted cheapest-first and tags the request',
        () async {
      final ProviderContainer c = _container();
      final req = _request();
      await c.read(roomAvailabilityControllerProvider.notifier).load(req);

      final state = c.read(roomAvailabilityControllerProvider);
      expect(state.result, isA<UiSuccess<AvailabilityResult>>());
      expect(state.request, req);
      expect(state.isFreshFor(req), isTrue);

      final rooms = (state.result as UiSuccess<AvailabilityResult>).data.rooms;
      final bookable = rooms.where((r) => r.isAvailable).toList();
      for (int i = 1; i < bookable.length; i++) {
        expect(
          bookable[i].nightlyRate.amount >= bookable[i - 1].nightlyRate.amount,
          isTrue,
        );
      }
    });

    test('a party too large for any room yields an empty state', () async {
      final ProviderContainer c = _container();
      await c.read(roomAvailabilityControllerProvider.notifier).load(
            _request(party: const GuestParty(adults: 6, children: 2)),
          );
      expect(
        c.read(roomAvailabilityControllerProvider).result,
        isA<UiEmpty<AvailabilityResult>>(),
      );
    });

    test('an identical fresh request is a no-op (deduped)', () async {
      final ProviderContainer c = _container();
      final controller = c.read(roomAvailabilityControllerProvider.notifier);
      final req = _request();

      await controller.load(req);
      final first = c.read(roomAvailabilityControllerProvider).result;
      await controller.load(req); // same request, already fresh
      expect(identical(c.read(roomAvailabilityControllerProvider).result, first),
          isTrue);
    });

    test('a different request refetches and re-tags', () async {
      final ProviderContainer c = _container();
      final controller = c.read(roomAvailabilityControllerProvider.notifier);

      await controller.load(_request(hotelId: 'oasis'));
      await controller.load(_request(hotelId: 'palm'));

      expect(
        c.read(roomAvailabilityControllerProvider).request!.hotelId,
        'palm',
      );
    });

    test('a slower earlier request cannot overwrite a newer one', () async {
      final ProviderContainer c = _container();
      final controller = c.read(roomAvailabilityControllerProvider.notifier);

      final slow = controller.load(_request(hotelId: 'oasis'));
      final fast = controller.load(_request(hotelId: 'palm'));
      await Future.wait(<Future<void>>[slow, fast]);

      expect(
        c.read(roomAvailabilityControllerProvider).request!.hotelId,
        'palm',
      );
    });

    test('retry re-runs the last request', () async {
      final ProviderContainer c = _container();
      final controller = c.read(roomAvailabilityControllerProvider.notifier);
      await controller.load(_request());
      await controller.retry();
      expect(c.read(roomAvailabilityControllerProvider).result,
          isA<UiSuccess<AvailabilityResult>>());
    });

    test('setSort flips the order without refetching', () async {
      final ProviderContainer c = _container();
      final controller = c.read(roomAvailabilityControllerProvider.notifier);
      await controller.load(_request());

      controller.setSort(RoomSort.priceDesc);
      final rooms = (c.read(roomAvailabilityControllerProvider).result
              as UiSuccess<AvailabilityResult>)
          .data
          .rooms;
      final bookable = rooms.where((r) => r.isAvailable).toList();
      for (int i = 1; i < bookable.length; i++) {
        expect(
          bookable[i].nightlyRate.amount <= bookable[i - 1].nightlyRate.amount,
          isTrue,
        );
      }
      expect(c.read(roomAvailabilityControllerProvider).sort, RoomSort.priceDesc);
    });

    test('reset returns to the initial state', () async {
      final ProviderContainer c = _container();
      final controller = c.read(roomAvailabilityControllerProvider.notifier);
      await controller.load(_request());
      controller.reset();
      final state = c.read(roomAvailabilityControllerProvider);
      expect(state.result, isA<UiInitial<AvailabilityResult>>());
      expect(state.request, isNull);
    });
  });

  group('RoomSelectionController', () {
    RoomSelection selectionFor(ProviderContainer c) {
      final party = c.read(guestPartyControllerProvider);
      final stay = c
          .read(stayDatesControllerProvider)
          .rangeAgainst(_today)!;
      return RoomSelection(
        hotelId: 'oasis',
        hotelName: const LocalizedText(ar: 'الواحة', en: 'Oasis'),
        roomType: _fakeRoomType(),
        stay: stay,
        party: party,
        nightlyRate: _fakeRoomType().nightlyRate,
      );
    }

    void pickDates(ProviderContainer c) {
      c.read(stayDatesControllerProvider.notifier)
        ..selectDay(DateTime(2026, 9, 6))
        ..selectDay(DateTime(2026, 9, 8));
    }

    test('select then clear', () {
      final ProviderContainer c = _container();
      pickDates(c);
      final notifier = c.read(roomSelectionControllerProvider.notifier);

      notifier.select(selectionFor(c));
      expect(c.read(roomSelectionControllerProvider), isNotNull);

      notifier.clear();
      expect(c.read(roomSelectionControllerProvider), isNull);
    });

    test('changing the dates clears the selection', () {
      final ProviderContainer c = _container();
      pickDates(c);
      c.read(roomSelectionControllerProvider.notifier).select(selectionFor(c));

      c.read(stayDatesControllerProvider.notifier).selectDay(DateTime(2026, 9, 10));
      expect(c.read(roomSelectionControllerProvider), isNull);
    });

    test('changing the guest party clears the selection', () {
      final ProviderContainer c = _container();
      pickDates(c);
      c.read(roomSelectionControllerProvider.notifier).select(selectionFor(c));

      c.read(guestPartyControllerProvider.notifier).incrementAdults();
      expect(c.read(roomSelectionControllerProvider), isNull);
    });

    test('re-seeding the identical range does not clear the selection', () {
      final ProviderContainer c = _container();
      pickDates(c);
      final sel = selectionFor(c);
      c.read(roomSelectionControllerProvider.notifier).select(sel);

      // Returning to the picker seeds the same range atomically — equal value,
      // so no false invalidation.
      c.read(stayDatesControllerProvider.notifier).setRange(sel.stay);
      expect(c.read(roomSelectionControllerProvider), sel);
    });
  });
}

RoomTypeSummary _fakeRoomType() => const RoomTypeSummary(
      id: 'standard',
      name: LocalizedText(ar: 'قياسية', en: 'Standard'),
      description: LocalizedText(ar: '', en: ''),
      bedType: LocalizedText(ar: '', en: ''),
      maxOccupancy: 2,
      amenities: <RoomAmenity>[],
      nightlyRate: Money(amount: 320),
      breakfastIncluded: true,
      refundable: true,
    );
