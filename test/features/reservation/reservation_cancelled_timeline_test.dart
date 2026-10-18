import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/app/router/app_router.dart';
import 'package:hotel_guest_app/core/localization/generated/app_localizations.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/guest_party.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/localized_text.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/money.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/stay_range.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/create_reservation_request.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/extend_stay.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation_status.dart';
import 'package:hotel_guest_app/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:hotel_guest_app/features/reservation/presentation/state/reservation_providers.dart';

import '../../support/auth_test_support.dart';
import '../../support/pump_app.dart';

Reservation _cancelled({required bool refundable}) => Reservation(
      id: 'res-c',
      reference: 'RSV-C',
      hotelId: 'oasis',
      hotelName: const LocalizedText(ar: 'فندق الواحة', en: 'The Oasis Hotel'),
      roomTypeId: 'deluxe',
      roomName: const LocalizedText(ar: 'ديلوكس', en: 'Deluxe Room'),
      stay: StayRange(checkIn: DateTime(2026, 9, 6), checkOut: DateTime(2026, 9, 8)),
      party: const GuestParty(adults: 2, children: 0),
      status: ReservationStatus.cancelled,
      priceSnapshot: const Money(amount: 900, currency: 'SAR'),
      createdAt: DateTime(2026, 9, 1, 9),
      cancelledAt: DateTime(2026, 9, 2, 9),
      cancellation: CancellationState(
        allowed: false,
        fullRefund: false,
        refundable: refundable,
      ),
    );

class _Repo implements ReservationRepository {
  _Repo(this.reservation);
  final Reservation reservation;
  @override
  Future<Reservation> getById(String id) async => reservation;
  @override
  Future<List<Reservation>> list() async => <Reservation>[reservation];
  @override
  Future<Reservation> create(CreateReservationRequest request) async => reservation;
  @override
  Future<Reservation> cancel(String id) async => reservation;
  @override
  Future<ExtendStayResult> extend(ExtendStayRequest request) =>
      throw UnimplementedError();
}

Future<AppLocalizations> _open(WidgetTester tester, Reservation r) async {
  final ProviderContainer c = await pumpApp(
    tester,
    bootSession: completeSession(),
    extraOverrides: <Override>[
      reservationRepositoryProvider.overrideWithValue(_Repo(r)),
    ],
  );
  c.read(appRouterProvider).go('/reservation/${r.id}');
  await tester.pumpAndSettle();
  return AppLocalizations.delegate.load(const Locale('en'));
}

void main() {
  testWidgets('a cancelled refundable booking promises the deposit refund',
      (WidgetTester tester) async {
    final AppLocalizations en = await _open(tester, _cancelled(refundable: true));

    expect(find.text(en.bookingDepositRefundRowSubtitle), findsOneWidget);
    expect(find.text(en.bookingCancellationFeeNone), findsOneWidget);
    expect(find.text(en.bookingDepositNotRefunded), findsNothing);
  });

  testWidgets('a cancelled non-refundable booking never promises a refund',
      (WidgetTester tester) async {
    final AppLocalizations en = await _open(tester, _cancelled(refundable: false));

    expect(find.text(en.bookingDepositNotRefunded), findsOneWidget);
    expect(find.text(en.bookingDepositRefundRowSubtitle), findsNothing);
    expect(find.text(en.bookingCancellationFeeNone), findsNothing);
  });
}
