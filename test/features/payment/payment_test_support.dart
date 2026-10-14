import 'package:hotel_guest_app/features/discovery/domain/entities/guest_party.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/localized_text.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/money.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/stay_range.dart';
import 'package:hotel_guest_app/features/payment/data/datasources/dummy_payment_data_source.dart';
import 'package:hotel_guest_app/features/payment/domain/entities/payment_request.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation_status.dart';

Reservation fakeReservation({
  String id = 'res-1',
  int amount = 900,
  String currency = 'SAR',
  ReservationStatus status = ReservationStatus.pending,
  String? roomNumber,
  num? depositAmount,
  num? nightlyRate,
  num? serviceFee,
  bool? pricesIncludeTaxes,
  StayRange? stay,
}) {
  return Reservation(
    id: id,
    reference: 'RSV-001-001',
    hotelId: 'oasis',
    hotelName: const LocalizedText(ar: 'فندق الواحة', en: 'The Oasis Hotel'),
    roomTypeId: 'deluxe',
    roomName: const LocalizedText(ar: 'ديلوكس', en: 'Deluxe Room'),
    stay: stay ?? StayRange(checkIn: DateTime(2026, 9, 6), checkOut: DateTime(2026, 9, 8)),
    party: const GuestParty(adults: 2, children: 0),
    status: status,
    priceSnapshot: Money(amount: amount, currency: currency),
    createdAt: DateTime(2026, 9, 1, 9),
    roomNumber: roomNumber,
    depositAmount: depositAmount == null
        ? null
        : Money(amount: depositAmount, currency: currency),
    nightlyRate:
        nightlyRate == null ? null : Money(amount: nightlyRate, currency: currency),
    serviceFee:
        serviceFee == null ? null : Money(amount: serviceFee, currency: currency),
    pricesIncludeTaxes: pricesIncludeTaxes,
  );
}

PaymentHoldRequest fakeHoldRequest({String reservationId = 'res-1', int amount = 900}) =>
    PaymentHoldRequest(
      reservationId: reservationId,
      amount: Money(amount: amount),
    );

/// The first reservation id (`r0`, `r1`, …) that maps to [scenario].
String reservationIdForScenario(DummyHoldScenario scenario) {
  for (int i = 0; i < 500; i++) {
    final String id = 'r$i';
    if (DummyPaymentDataSource.scenarioFor(id) == scenario) return id;
  }
  throw StateError('no id found for $scenario');
}
