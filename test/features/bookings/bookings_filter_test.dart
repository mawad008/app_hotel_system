import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/features/bookings/domain/bookings_filter.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation_status.dart';

import '../payment/payment_test_support.dart';

void main() {
  test('every reservation status belongs to exactly one Bookings section', () {
    for (final ReservationStatus status in ReservationStatus.values) {
      final r = fakeReservation(status: status);
      final int sections = <bool>[
        r.isOngoingStay,
        r.isUpcomingBooking,
        r.isPastBooking,
      ].where((bool b) => b).length;
      expect(sections, 1, reason: '$status must appear in one section');
    }
  });

  test('a checkout in progress or blocked is still the current stay', () {
    expect(
      fakeReservation(status: ReservationStatus.checkoutInProgress).isOngoingStay,
      isTrue,
    );
    expect(
      fakeReservation(status: ReservationStatus.checkoutBlocked).isOngoingStay,
      isTrue,
    );
  });
}
