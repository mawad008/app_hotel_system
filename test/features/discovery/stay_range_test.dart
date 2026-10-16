import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/stay_range.dart';

void main() {
  group('calendarDaysBetween', () {
    test('counts calendar days, not 24-hour periods', () {
      // On a daylight-saving change local midnights are 23 or 25 hours
      // apart; the count must depend on the dates alone.
      expect(
        calendarDaysBetween(DateTime(2026, 4, 23, 23, 59), DateTime(2026, 4, 25)),
        2,
      );
      expect(
        calendarDaysBetween(DateTime(2026, 10, 29), DateTime(2026, 10, 30, 23)),
        1,
      );
    });

    test('works across month and year ends', () {
      expect(calendarDaysBetween(DateTime(2026, 12, 30), DateTime(2027, 1, 2)), 3);
      expect(calendarDaysBetween(DateTime(2028, 2, 28), DateTime(2028, 3, 1)), 2);
    });
  });

  test('addCalendarDays lands on the next calendar day at midnight', () {
    expect(addCalendarDays(DateTime(2026, 4, 30), 1), DateTime(2026, 5));
    expect(addCalendarDays(DateTime(2026, 12, 31, 18), 1), DateTime(2027));
  });

  test('a stay across a daylight-saving change keeps every night', () {
    // Egypt springs forward on the last Friday of April (24 April 2026).
    final StayRange stay = StayRange(
      checkIn: DateTime(2026, 4, 23),
      checkOut: DateTime(2026, 4, 26),
    );
    expect(stay.nights, 3);
  });
}
