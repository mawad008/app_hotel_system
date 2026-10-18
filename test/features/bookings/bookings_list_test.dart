import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/app/router/app_router.dart';
import 'package:hotel_guest_app/app/router/app_routes.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/create_reservation_request.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/extend_stay.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation_status.dart';
import 'package:hotel_guest_app/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:hotel_guest_app/features/reservation/presentation/state/reservation_providers.dart';

import '../../support/auth_test_support.dart';
import '../../support/pump_app.dart';
import '../payment/payment_test_support.dart' show fakeReservation;

class _Repo implements ReservationRepository {
  _Repo(this.items);
  final List<Reservation> items;
  @override
  Future<Reservation> create(CreateReservationRequest request) => throw UnimplementedError();
  @override
  Future<Reservation> getById(String id) async => items.firstWhere((Reservation r) => r.id == id);
  @override
  Future<List<Reservation>> list() async => items;
  @override
  Future<Reservation> cancel(String id) => throw UnimplementedError();
  @override
  Future<ExtendStayResult> extend(ExtendStayRequest request) => throw UnimplementedError();
}

void main() {
  testWidgets('current list shows the stay with its room number, then upcoming bookings',
      (WidgetTester tester) async {
    final ProviderContainer c = await pumpApp(
      tester,
      bootSession: completeSession(),
      locale: const Locale('en'),
      extraOverrides: <Override>[
        reservationRepositoryProvider.overrideWithValue(_Repo(<Reservation>[
          fakeReservation(id: 's', status: ReservationStatus.inStay, roomNumber: '412'),
          fakeReservation(id: 'u', status: ReservationStatus.depositHeld),
        ])),
      ],
    );
    final en = await tester.l10n();
    c.read(appRouterProvider).goNamed(AppRoutes.bookingsName);
    await tester.pumpAndSettle();

    expect(find.text(en.bookingsSectionOngoingStay), findsOneWidget);
    expect(find.text(en.bookingsSectionUpcoming), findsOneWidget);
    expect(find.text('The Oasis Hotel · ${en.bookingRoomNumber('412')}'), findsOneWidget);
    expect(find.textContaining(en.stayNights(2)), findsNWidgets(2));

    await tester.tap(find.text('The Oasis Hotel · ${en.bookingRoomNumber('412')}'));
    await tester.pumpAndSettle();
    expect(find.text(en.bookingDetailTitle), findsWidgets);
  });
}
