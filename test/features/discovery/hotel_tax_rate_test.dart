import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/features/discovery/data/models/discovery_models.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/guest_party.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/hotel_guest_details.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/localized_text.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/money.dart';
import 'package:hotel_guest_app/features/discovery/presentation/state/booking_price.dart';
import 'package:hotel_guest_app/features/discovery/presentation/widgets/price_breakdown_card.dart';
import 'package:hotel_guest_app/features/reservation/data/models/reservation_models.dart';

import '../reservation/reservation_test_support.dart';

/// The hotel's tax rate ("نسبة الضريبة"): added on top of stay + service fee
/// when its rates exclude taxes — same arithmetic as the backend's
/// `Reservation::taxAmount`.
void main() {
  test('tax_rate parses from the guest hotel payload; null/0 means none', () {
    expect(HotelModel.parseGuestDetails(<String, dynamic>{'tax_rate': '15.00'}).taxRate, 15);
    expect(HotelModel.parseGuestDetails(<String, dynamic>{'tax_rate': null}).taxRate, isNull);
    expect(HotelModel.parseGuestDetails(<String, dynamic>{'tax_rate': '0.00'}).taxRate, isNull);
  });

  test('taxFor applies the rate to stay + fee, truncated to the halala', () {
    const HotelGuestDetails details = HotelGuestDetails(taxRate: 15);
    // (200 + 45) × 15% = 36.75
    expect(
      details.taxFor(Money(amount: 200), serviceFee: Money(amount: 45))!.amount,
      36.75,
    );
    // 33.33 × 15% = 4.9995 → 4.99 (bcmath truncation)
    expect(details.taxFor(Money(amount: 33.33))!.amount, 4.99);
    expect(const HotelGuestDetails().taxFor(Money(amount: 200)), isNull);
  });

  test('the booking breakdown adds the tax to the total', () {
    final BookingPriceBreakdown breakdown = BookingPriceBreakdown.of(
      fakeSelection(price: 100),
      serviceFee: Money(amount: 45),
      tax: Money(amount: 36.75),
      taxRate: 15,
    );
    expect(breakdown.total.amount, 281.75);
    expect(breakdown.taxRate, 15);
    expect(formatTaxRate(15), '15');
    expect(formatTaxRate(7.5), '7.5');
  });

  test('a reservation carries the server tax and pays it in the total', () {
    final ReservationModel model = ReservationModel.fromJson(
      <String, dynamic>{
        'id': 9,
        'hotel_id': 1,
        'room_type_id': 5,
        'status': 'pending',
        'check_in': '2026-09-06',
        'check_out': '2026-09-08',
        'adults': 2,
        'children': 0,
        'price_snapshot': '200.00',
        'service_fee_amount': '45.00',
        'tax_rate': '15.00',
        'tax_amount': '36.75',
        'currency': 'SAR',
        'created_at': '2026-09-01T00:00:00Z',
      },
      hotelName: const LocalizedText(ar: 'الواحة', en: 'Oasis'),
      roomName: const LocalizedText(ar: 'ديلوكس', en: 'Deluxe'),
      party: const GuestParty(adults: 2, children: 0),
    );
    final reservation = model.toEntity();
    expect(reservation.tax!.amount, 36.75);
    expect(reservation.taxRate, 15);
    expect(reservation.totalToPay.amount, 281.75);
  });
}
