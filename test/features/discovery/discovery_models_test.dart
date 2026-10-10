import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/features/discovery/data/models/discovery_models.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/hotel.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/hotel_facility.dart';

void main() {
  test('HotelSummaryModel maps every field to the entity', () {
    final HotelSummaryModel model = HotelSummaryModel.fromJson(
      <String, Object?>{
        'id': 'oasis',
        'name': <String, Object?>{'ar': 'الواحة', 'en': 'Oasis'},
        'city_id': 'alula',
        'city_name': <String, Object?>{'ar': 'العُلا', 'en': 'AlUla'},
        'tagline': <String, Object?>{'ar': 't-ar', 'en': 't-en'},
        'rating': 4.96,
        'review_count': 217,
        'nightly_rate_from': <String, Object?>{
          'amount': 320,
          'currency': 'SAR',
        },
        'is_available': true,
      },
    );

    final entity = model.toEntity();
    expect(entity.id, 'oasis');
    expect(entity.name.resolve(const Locale('ar')), 'الواحة');
    expect(entity.cityName.resolve(const Locale('en')), 'AlUla');
    expect(entity.rating, 4.96);
    expect(entity.reviewCount, 217);
    expect(entity.nightlyRateFrom.amount, 320);
    expect(entity.isAvailable, isTrue);
  });

  test('HotelModel parses facilities and counts', () {
    final HotelModel model = HotelModel.fromJson(<String, Object?>{
      'id': 'oasis',
      'name': <String, Object?>{'ar': 'الواحة', 'en': 'Oasis'},
      'city_id': 'alula',
      'city_name': <String, Object?>{'ar': 'a', 'en': 'a'},
      'tagline': <String, Object?>{'ar': 'a', 'en': 'a'},
      'rating': 4.5,
      'review_count': 10,
      'nightly_rate_from': <String, Object?>{'amount': 320},
      'is_available': true,
      'description': <String, Object?>{'ar': 'وصف', 'en': 'about'},
      // Dummy-shape wire keys — a name not in the known set is dropped,
      // never guessed.
      'amenities': <Object?>['free_wifi', 'pool', 'not_a_real_one'],
      'room_type_count': 6,
      'photo_count': 48,
    });

    final Hotel entity = model.toEntity();
    expect(entity.facilities.map((HotelFacility f) => f.key), <String>[
      'free_wifi',
      'pool',
    ]);
    expect(entity.facilities.first.label.en, 'Free Wi-Fi');
    expect(entity.roomTypeCount, 6);
    expect(entity.photoCount, 48);
    expect(entity.description.resolve(const Locale('ar')), 'وصف');
  });

  test('AvailabilityResultModel maps nested rooms and the stay', () {
    final AvailabilityResultModel model = AvailabilityResultModel.fromJson(
      <String, Object?>{
        'hotel_id': 'oasis',
        'check_in': '2026-09-06T00:00:00.000',
        'check_out': '2026-09-08T00:00:00.000',
        'adults': 2,
        'children': 1,
        'rooms': <Object?>[
          <String, Object?>{
            'is_available': false,
            'room_type': <String, Object?>{
              'id': 'royal',
              'name': <String, Object?>{'ar': 'ملكي', 'en': 'Royal'},
              'description': <String, Object?>{'ar': '', 'en': ''},
              'bed_type': <String, Object?>{'ar': '', 'en': ''},
              'max_occupancy': 4,
              'amenities': <Object?>['balcony'],
              'nightly_rate': <String, Object?>{'amount': 1450},
              'breakfast_included': true,
              'refundable': false,
            },
          },
        ],
      },
    );

    final entity = model.toEntity();
    expect(entity.hotelId, 'oasis');
    expect(entity.stay.nights, 2);
    expect(entity.party.total, 3);
    expect(entity.rooms.single.isAvailable, isFalse);
    expect(entity.rooms.single.roomType.nightlyRate.amount, 1450);
    expect(entity.rooms.single.stayTotal(2).amount, 2900);
  });

  test(
    'AvailabilityResultModel drops room types that cannot seat the party',
    () {
      Map<String, Object?> room(String id, int maxOccupancy) =>
          <String, Object?>{
            'is_available': true,
            'room_type': <String, Object?>{
              'id': id,
              'name': <String, Object?>{'ar': id, 'en': id},
              'description': <String, Object?>{'ar': '', 'en': ''},
              'bed_type': <String, Object?>{'ar': '', 'en': ''},
              'max_occupancy': maxOccupancy,
              'amenities': <Object?>[],
              'nightly_rate': <String, Object?>{'amount': 100},
            },
          };

      final entity = AvailabilityResultModel.fromJson(<String, Object?>{
        'hotel_id': 'oasis',
        'check_in': '2026-09-06T00:00:00.000',
        'check_out': '2026-09-08T00:00:00.000',
        'adults': 2,
        'children': 1,
        'rooms': <Object?>[
          room('double', 2),
          room('triple', 3),
          room('family', 4),
        ],
      }).toEntity();

      expect(entity.rooms.map((r) => r.roomType.id), <String>[
        'triple',
        'family',
      ]);
    },
  );
}
